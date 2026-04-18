import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() {
    return _instance;
  }

  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  late FlutterLocalNotificationsPlugin _localNotifications;

  // Callback for when notification is tapped
  Function(Map<String, dynamic> payload)? onNotificationTapped;

  Future<void> initialize() async {
    // Initialize local notifications
    _initializeLocalNotifications();

    // Request notification permissions
    await _requestPermissions();

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen(_handleForegroundNotification);

    // Handle notification when app is opened from terminated state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle background notifications
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundNotification);

    // Get and save FCM token
    await _saveFCMToken();
  }

  void _initializeLocalNotifications() {
    _localNotifications = FlutterLocalNotificationsPlugin();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        );

    _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
  }

  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      PushNotificationService().onNotificationTapped?.call({
        'payload': response.payload,
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (kDebugMode) {
        print(
          'Notification permission status: ${settings.authorizationStatus}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting notification permissions: $e');
      }
    }
  }

  Future<void> _saveFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (token != null && currentUser != null) {
        await _saveFcmTokenViaCallable(token);

        if (kDebugMode) {
          print('FCM Token saved: $token');
        }
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _saveFcmTokenViaCallable(newToken);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }
  }

  Future<void> _saveFcmTokenViaCallable(String token) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final callable = _functions.httpsCallable('saveFcmToken');
        await callable.call({'token': token});
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating FCM token: $e');
      }
    }
  }

  void _handleForegroundNotification(RemoteMessage message) {
    if (kDebugMode) {
      print('Foreground notification: ${message.notification?.title}');
    }

    _showLocalNotification(message);
  }

  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification tapped: ${message.notification?.title}');
    }

    final data = message.data;
    onNotificationTapped?.call(data);
  }

  static Future<void> _handleBackgroundNotification(
    RemoteMessage message,
  ) async {
    if (kDebugMode) {
      print('Background notification: ${message.notification?.title}');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'uborrow_notifications',
      'UBorrow Notifications',
      channelDescription: 'Notifications for UBorrow app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: message.data.toString(),
    );
  }

  /// Send a notification to a specific user via FCM
  /// Should be called from your backend
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // Get user's FCM token from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return;

      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        if (kDebugMode) {
          print('User $userId has no FCM token');
        }
        return;
      }

      // In production, you should call your backend to send the notification
      // For now, we'll just log it
      if (kDebugMode) {
        print('Would send notification to $userId with FCM token: $fcmToken');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
    }
  }

  /// Subscribe to a notification topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic: $e');
      }
    }
  }

  /// Unsubscribe from a notification topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic: $e');
      }
    }
  }

  /// Get current FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Delete FCM token (call on logout)
  Future<void> deleteFCMToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      if (kDebugMode) {
        print('FCM token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting FCM token: $e');
      }
    }
  }

  /// Send notification for borrow request
  Future<void> sendBorrowRequestNotification({
    required String itemName,
    required String requesterEmail,
    required String ownerId,
    required String requestId,
  }) async {
    await sendNotificationToUser(
      userId: ownerId,
      title: 'New Borrow Request',
      body: '$requesterEmail wants to borrow "$itemName"',
      data: {
        'type': 'borrow_request',
        'requestId': requestId,
        'itemName': itemName,
      },
    );
  }

  /// Send notification for need request
  Future<void> sendNeedRequestNotification({
    required String itemName,
    required String requesterEmail,
    required String userId,
    required String requestId,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Someone needs "$itemName"',
      body: '$requesterEmail is looking for "$itemName"',
      data: {
        'type': 'need_request',
        'requestId': requestId,
        'itemName': itemName,
      },
    );
  }

  /// Send notification for request status change
  Future<void> sendRequestStatusNotification({
    required String userId,
    required String itemName,
    required String status,
    required String requestId,
  }) async {
    String title = '';
    String body = '';

    switch (status.toLowerCase()) {
      case 'accepted':
        title = 'Request Accepted';
        body = 'Your request for "$itemName" has been accepted!';
        break;
      case 'declined':
        title = 'Request Declined';
        body = 'Your request for "$itemName" has been declined.';
        break;
      case 'completed':
        title = 'Request Completed';
        body = 'Your "$itemName" borrow request is now completed.';
        break;
      default:
        title = 'Request Status Updated';
        body =
            'Your request for "$itemName" status has been updated to $status.';
    }

    await sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      data: {
        'type': 'request_status',
        'requestId': requestId,
        'status': status,
      },
    );
  }

  /// Send notification for new message
  Future<void> sendMessageNotification({
    required String userId,
    required String senderEmail,
    required String message,
    required String chatId,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'New Message from $senderEmail',
      body: message,
      data: {'type': 'message', 'chatId': chatId},
    );
  }
}
