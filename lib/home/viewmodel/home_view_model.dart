import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uborrow/auth/repository/auth_remote_repository.dart';
import 'package:uborrow/home/model/item_model.dart';
import 'package:uborrow/home/repository/home_remote_repository.dart';

part 'home_view_model.g.dart';

@riverpod
class HomeViewModel extends _$HomeViewModel {
  List<ItemModel> _items = [];
  String? _lastItemId;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  Future<List<ItemModel>> build() async {
    return await loadInitialItems();
  }

  // ///
  // List<ItemModel> generateFakeItems({int count = 50}) {
  //   final random = Random();
  //
  //   const hostels = ['A Hostel', 'B Hostel', 'C Hostel', 'D Hostel'];
  //   const categories = [
  //     'Electronics',
  //     'Books',
  //     'Sports Equipment',
  //     'Musical Instruments',
  //     'Tools',
  //     'Kitchen Items',
  //     'Other',
  //   ];
  //
  //   return List.generate(count, (index) {
  //     return ItemModel(
  //       id: null, // Firestore will assign
  //       name: 'Debug Item $index',
  //       description: 'Auto-generated debug item $index',
  //       hostel: hostels[random.nextInt(hostels.length)],
  //       category: categories[random.nextInt(categories.length)],
  //       image: '',
  //       ownerId: 'debug_user',
  //       ownerEmail: 'debug@uborrow.app',
  //       available: random.nextBool(),
  //       createdAt: DateTime.now(),
  //     );
  //   });
  // }
  //
  // void addDebugItems() {
  //   final fakeItems = generateFakeItems(count: 50);
  //
  //   _items.insertAll(0, fakeItems);
  //   _hasMore = false; // prevent pagination confusion
  //   state = AsyncValue.data(_items);
  // }
  //
  // Future<void> generateAndUploadDebugItems({int count = 50}) async {
  //   state = const AsyncValue.loading();
  //
  //   try {
  //     final repo = ref.read(homeRemoteRepositoryProvider);
  //
  //     final fakeItems = generateFakeItems(count: count);
  //
  //     final uploadedItems = await repo.addItemsBatch(items: fakeItems);
  //
  //     // Prepend so they appear instantly
  //     _items.insertAll(0, uploadedItems);
  //     _hasMore = true;
  //
  //     state = AsyncValue.data(_items);
  //   } catch (e, st) {
  //     state = AsyncValue.error(e, st);
  //   }
  // }
  //
  // ///

  Future<List<ItemModel>> loadInitialItems() async {
    final repo = ref.read(homeRemoteRepositoryProvider);

    _items = await repo.fetchItems(limit: 20);
    _hasMore = _items.length >= 20;
    _lastItemId = _items.isNotEmpty ? _items.last.id : null;

    return _items;
  }

  Future<void> loadMoreItems() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;

    try {
      final repo = ref.read(homeRemoteRepositoryProvider);

      DocumentSnapshot? lastDoc;
      if (_lastItemId != null) {
        lastDoc = await repo.getDocumentSnapshot(_lastItemId!);
      }

      final newItems = await repo.fetchItems(limit: 20, lastDocument: lastDoc);

      if (newItems.isEmpty) {
        _hasMore = false;
      } else {
        _items.addAll(newItems);
        _lastItemId = newItems.last.id;
        _hasMore = newItems.length >= 20;

        state = AsyncValue.data(_items);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    _items.clear();
    _lastItemId = null;
    _hasMore = true;
    _isLoadingMore = false;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => loadInitialItems());
  }

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  User? getCurrentUser() {
    return ref.read(authRemoteRepositoryProvider).getCurrentUser();
  }

  Future<ItemModel> addItem({
    required ItemModel item,
    File? imageFile,
    String? fromRequestId,
    void Function(double progress)? onUploadProgress,
  }) async {
    final authRepo = ref.read(authRemoteRepositoryProvider);
    final repo = ref.read(homeRemoteRepositoryProvider);

    final user = authRepo.getCurrentUser();

    if (user == null) {
      throw Exception('User not logged in');
    }

    final newItem = await repo.addItem(
      item: item,
      ownerId: user.uid,
      ownerEmail: user.email ?? '',
      imageFile: imageFile,
      fromRequestId: fromRequestId,
      onUploadProgress: onUploadProgress,
    );

    // Add new item to the beginning of the list
    _items.insert(0, newItem);
    state = AsyncValue.data(_items);

    return newItem;
  }
}
