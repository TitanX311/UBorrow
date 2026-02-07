// home_remote_repository.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uborrow/core/repository/cloudinary_provider.dart';
import 'package:uborrow/home/model/item_model.dart';

part 'home_remote_repository.g.dart';

@riverpod
HomeRemoteRepository homeRemoteRepository(Ref ref) {
  return HomeRemoteRepository(
    firestore: FirebaseFirestore.instance,
    cloudinary: ref.read(cloudinaryServiceProvider),
  );
}

class HomeRemoteRepository {
  HomeRemoteRepository({
    required FirebaseFirestore firestore,
    required CloudinaryService cloudinary,
  }) : _firestore = firestore,
       _cloudinary = cloudinary;

  final FirebaseFirestore _firestore;
  final CloudinaryService _cloudinary;

  // 🔹 Collection ref
  CollectionReference<Map<String, dynamic>> get _itemsRef =>
      _firestore.collection('items');
  CollectionReference<Map<String, dynamic>> get _itemRequestRef =>
      _firestore.collection('items_requests');

  // 🔹 Fetch items with pagination
  Future<List<ItemModel>> fetchItems({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String orderByField = 'createdAt',
    bool descending = true,
  }) async {
    Query<Map<String, dynamic>> query = _itemsRef
        .orderBy(orderByField, descending: descending)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => ItemModel.fromMap(doc.data(), documentId: doc.id))
        .toList();
  }

  // 🔹 Get document snapshot (for pagination cursor)
  Future<DocumentSnapshot?> getDocumentSnapshot(String docId) async {
    return await _itemsRef.doc(docId).get();
  }

  // 🔹 Stream items (keep for real-time updates if needed)
  Stream<QuerySnapshot<Map<String, dynamic>>> getItemsStream({
    String orderByField = 'createdAt',
    bool descending = true,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _itemsRef.orderBy(
      orderByField,
      descending: descending,
    );

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  // 🔹 Add item (keep as is)
  Future<ItemModel> addItem({
    required ItemModel item,
    required String ownerId,
    required String ownerEmail,
    File? imageFile,
    String? fromRequestId,
    void Function(double progress)? onUploadProgress,
  }) async {
    String imageUrl = item.image;

    if (imageFile != null) {
      final uploadedUrl = await _cloudinary.uploadImage(
        imageFile: imageFile,
        folder: 'uborrow_items',
        onProgress: onUploadProgress,
      );

      if (uploadedUrl == null) {
        throw Exception('Image upload failed');
      }

      imageUrl = uploadedUrl;
    }

    final docRef = await _itemsRef.add({
      ...item
          .copyWith(
            image: imageUrl,
            ownerId: ownerId,
            ownerEmail: ownerEmail,
            available: true,
          )
          .toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (fromRequestId != null) {
      await _itemRequestRef.doc(fromRequestId).update({
        'status': 'Fulfilled',
        'fulfilledBy': ownerId,
        'fulfilledItemId': docRef.id,
        'fulfilledAt': FieldValue.serverTimestamp(),
      });
    }

    return item.copyWith(
      id: docRef.id,
      image: imageUrl,
      ownerId: ownerId,
      ownerEmail: ownerEmail,
    );
  }

  Future<List<ItemModel>> addItemsBatch({
    required List<ItemModel> items,
  }) async {
    final batch = _firestore.batch();
    final collection = _firestore.collection('items');

    final List<ItemModel> savedItems = [];

    for (final item in items) {
      final docRef = collection.doc();

      final newItem = item.copyWith(id: docRef.id, createdAt: DateTime.now());

      batch.set(docRef, newItem.toMap());
      savedItems.add(newItem);
    }

    await batch.commit();
    return savedItems;
  }
}
