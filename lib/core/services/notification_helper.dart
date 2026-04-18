import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uborrow/core/services/push_notification_service.dart';

/// Helper class to handle notifications for various app events
class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();

  factory NotificationHelper() {
    return _instance;
  }

  NotificationHelper._internal();

  final _notificationService = PushNotificationService();
  final _firestore = FirebaseFirestore.instance;

  /// Send notification when a borrow request is created
  Future<void> onBorrowRequestCreated({
    required String itemName,
    required String requesterEmail,
    required String ownerId,
    required String requestId,
  }) async {
    try {
      await _notificationService.sendBorrowRequestNotification(
        itemName: itemName,
        requesterEmail: requesterEmail,
        ownerId: ownerId,
        requestId: requestId,
      );

      if (kDebugMode) {
        print('Borrow request notification sent for $requestId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending borrow request notification: $e');
      }
    }
  }

  /// Send notification when a need request is created
  Future<void> onNeedRequestCreated({
    required String itemName,
    required String requesterEmail,
    required String userId,
    required String requestId,
  }) async {
    try {
      // Get all users to send notifications (in a real app, you'd query subscribed users)
      final usersSnapshot = await _firestore.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;

        // Don't send notification to the requester
        if (userId != currentUserId) {
          await _notificationService.sendNeedRequestNotification(
            itemName: itemName,
            requesterEmail: requesterEmail,
            userId: userId,
            requestId: requestId,
          );
        }
      }

      if (kDebugMode) {
        print('Need request notifications sent for $requestId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending need request notifications: $e');
      }
    }
  }

  /// Send notification when borrow request status changes
  Future<void> onBorrowRequestStatusChanged({
    required String requestId,
    required String itemName,
    required String newStatus,
    required String requesterId,
  }) async {
    try {
      await _notificationService.sendRequestStatusNotification(
        userId: requesterId,
        itemName: itemName,
        status: newStatus,
        requestId: requestId,
      );

      if (kDebugMode) {
        print('Request status notification sent: $newStatus for $requestId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending request status notification: $e');
      }
    }
  }

  /// Send notification when need request is fulfilled
  Future<void> onNeedRequestFulfilled({
    required String requestId,
    required String itemName,
    required String requesterId,
    required String fulfilledByEmail,
  }) async {
    try {
      await _notificationService.sendRequestStatusNotification(
        userId: requesterId,
        itemName: itemName,
        status: 'fulfilled',
        requestId: requestId,
      );

      if (kDebugMode) {
        print('Need request fulfilled notification sent for $requestId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending need request fulfilled notification: $e');
      }
    }
  }

  /// Send notification for new message
  Future<void> onNewMessage({
    required String receiverId,
    required String senderEmail,
    required String messageBody,
    required String chatId,
  }) async {
    try {
      await _notificationService.sendMessageNotification(
        userId: receiverId,
        senderEmail: senderEmail,
        message: messageBody,
        chatId: chatId,
      );

      if (kDebugMode) {
        print('Message notification sent to $receiverId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message notification: $e');
      }
    }
  }

  /// Subscribe user to relevant topics
  Future<void> subscribeUserToTopics({
    required String userId,
  }) async {
    try {
      // Subscribe to general app notifications
      await _notificationService.subscribeToTopic('all_users');

      // Subscribe to user-specific topic
      await _notificationService.subscribeToTopic('user_$userId');

      // Subscribe to borrow requests
      await _notificationService.subscribeToTopic('borrow_requests');

      // Subscribe to need requests
      await _notificationService.subscribeToTopic('need_requests');

      if (kDebugMode) {
        print('User $userId subscribed to notification topics');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topics: $e');
      }
    }
  }

  /// Unsubscribe user from topics
  Future<void> unsubscribeUserFromTopics({
    required String userId,
  }) async {
    try {
      await _notificationService.unsubscribeFromTopic('all_users');
      await _notificationService.unsubscribeFromTopic('user_$userId');
      await _notificationService.unsubscribeFromTopic('borrow_requests');
      await _notificationService.unsubscribeFromTopic('need_requests');

      if (kDebugMode) {
        print('User $userId unsubscribed from notification topics');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topics: $e');
      }
    }
  }

  /// Handle notification tap navigation
  void setupNotificationTapHandler(Function(Map<String, dynamic> payload) onTap) {
    _notificationService.onNotificationTapped = onTap;
  }
}

