// home_remote_repository.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uborrow/core/repository/cloudinary_provider.dart';
import 'package:uborrow/home/model/item_model.dart';
import 'package:uborrow/home/model/need_request_model.dart';
import 'package:uborrow/utils/constants.dart';

import '../../core/services/notification_helper.dart';

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
      _firestore.collection(AppCollections.items);
  CollectionReference<Map<String, dynamic>> get _needRequestRef =>
      _firestore.collection(AppCollections.needRequests);

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

  // 🔹 Add item
  Future<ItemModel> addItem({
    required ItemModel item,
    required String ownerId,
    required String ownerEmail,
    File? imageFile,
    String? fromRequestId,
    void Function(double progress)? onUploadProgress,
  }) async {
    DocumentReference<Map<String, dynamic>>? requestRef;
    String? requestRequesterId;
    String requestItemName = item.name;

    if (fromRequestId != null) {
      requestRef = _needRequestRef.doc(fromRequestId);
      final requestSnapshot = await requestRef.get();

      if (!requestSnapshot.exists) {
        throw Exception('Request not found');
      }

      final requestData = requestSnapshot.data() ?? <String, dynamic>{};
      final status = requestData['status'] as String? ?? NeedRequestStatus.open;
      final fulfilledBy = requestData['fulfilledBy'] as String?;

      if (status != NeedRequestStatus.open ||
          (fulfilledBy != null && fulfilledBy.isNotEmpty)) {
        throw Exception('This request has already been fulfilled');
      }

      requestRequesterId = requestData['requesterId'] as String?;
      requestItemName = requestData['itemName'] as String? ?? item.name;
    }

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

    if (fromRequestId != null && requestRef != null) {
      try {
        await _firestore.runTransaction((transaction) async {
          final latestRequest = await transaction.get(requestRef!);

          if (!latestRequest.exists) {
            throw Exception('Request not found');
          }

          final requestData = latestRequest.data() ?? <String, dynamic>{};
          final status =
              requestData['status'] as String? ?? NeedRequestStatus.open;
          final fulfilledBy = requestData['fulfilledBy'] as String?;

          if (status != NeedRequestStatus.open ||
              (fulfilledBy != null && fulfilledBy.isNotEmpty)) {
            throw Exception('This request has already been fulfilled');
          }

          transaction.update(requestRef, {
            'status': NeedRequestStatus.fulfilled,
            'fulfilledBy': ownerId,
            'fulfilledItemId': docRef.id,
            'fulfilledAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });
      } catch (e) {
        await docRef.delete();
        rethrow;
      }

      // if (requestRequesterId != null &&
      //     requestRequesterId.isNotEmpty &&
      //     requestRequesterId != ownerId) {
      //   await _sendAutomatedRequestReferenceMessage(
      //     senderId: ownerId,
      //     senderEmail: ownerEmail,
      //     receiverId: requestRequesterId,
      //     requestId: fromRequestId,
      //     requestItemName: requestItemName,
      //     fulfilledItemId: docRef.id,
      //   );

      //   // Send notification to requester that their need request was fulfilled
      //   final notificationHelper = NotificationHelper();
      //   await notificationHelper.onNeedRequestFulfilled(
      //     requestId: fromRequestId,
      //     itemName: requestItemName,
      //     requesterId: requestRequesterId,
      //     fulfilledByEmail: ownerEmail,
      //   );
      // }
    }

    return item.copyWith(
      id: docRef.id,
      image: imageUrl,
      ownerId: ownerId,
      ownerEmail: ownerEmail,
    );
  }

  //request item
  Future<NeedRequestModel> createNeedRequest({
    required String itemName,
    required String period,
    String? message,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      final docRef = await _needRequestRef.add({
        'itemName': itemName,
        'period': period,
        'message': message,
        'requesterId': user.uid,
        'requesterEmail': user.email ?? '',
        'status': NeedRequestStatus.open,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (docRef.id.isEmpty) {
        throw Exception('Failed to post request');
      }

      final savedSnapshot = await docRef.get();
      final data = savedSnapshot.data();

      if (data == null) {
        throw Exception('Failed to load created request');
      }

      return NeedRequestModel.fromMap(data, documentId: savedSnapshot.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _sendAutomatedRequestReferenceMessage({
    required String senderId,
    required String senderEmail,
    required String receiverId,
    required String requestId,
    required String requestItemName,
    String? fulfilledItemId,
  }) async {
    final timestamp = Timestamp.now();
    final participantIds = [senderId, receiverId]..sort();
    final chatRoomId = participantIds.join('_');

    final payload = {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': 'I have this',
      'timestamp': timestamp,
      'isRead': false,
      'isAutomated': true,
      'messageType': 'request_reference',
      'requestId': requestId,
      'requestItemName': requestItemName,
      if (fulfilledItemId != null) 'fulfilledItemId': fulfilledItemId,
    };

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(payload);

    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'participants': participantIds,
      'lastMessage': payload['message'],
      'lastMessageTime': timestamp,
      'lastMessageSenderId': senderId,
      'lastMessageType': payload['messageType'],
      'lastRequestId': requestId,
      if (fulfilledItemId != null) 'lastFulfilledItemId': fulfilledItemId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<ItemModel>> addItemsBatch({
    required List<ItemModel> items,
  }) async {
    final batch = _firestore.batch();
    final collection = _firestore.collection(AppCollections.items);

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

  Future<void> handleIHaveThis({required String requestId}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    String? requesterId;
    String requestItemName = 'Unknown item';

    await _firestore.runTransaction((transaction) async {
      final requestRef = _needRequestRef.doc(requestId);
      final requestDoc = await transaction.get(requestRef);

      if (!requestDoc.exists) {
        throw Exception('Request not found');
      }

      final requestData = requestDoc.data() ?? <String, dynamic>{};
      final status = requestData['status'] as String? ?? NeedRequestStatus.open;
      final fulfilledBy = requestData['fulfilledBy'] as String?;

      requesterId = requestData['requesterId'] as String?;
      requestItemName = requestData['itemName'] as String? ?? 'Unknown item';

      if (requesterId == null || requesterId!.isEmpty) {
        throw Exception('Invalid request');
      }

      if (requesterId == currentUser.uid) {
        throw Exception('You cannot fulfill your own request');
      }

      if (status != NeedRequestStatus.open ||
          (fulfilledBy != null && fulfilledBy.isNotEmpty)) {
        throw Exception('This request has already been fulfilled');
      }

      transaction.update(requestRef, {
        'status': NeedRequestStatus.fulfilled,
        'fulfilledBy': currentUser.uid,
        'fulfilledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _sendAutomatedRequestReferenceMessage(
      senderId: currentUser.uid,
      senderEmail: currentUser.email ?? '',
      receiverId: requesterId!,
      requestId: requestId,
      requestItemName: requestItemName,
    );

    // final notificationHelper = NotificationHelper();
    // await notificationHelper.onNeedRequestFulfilled(
    //   requestId: requestId,
    //   itemName: requestItemName,
    //   requesterId: requesterId!,
    //   fulfilledByEmail: currentUser.email ?? '',
    // );
  }
}
