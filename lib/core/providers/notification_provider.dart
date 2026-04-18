import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uborrow/core/services/push_notification_service.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(pushNotificationServiceProvider);
  return await service.getFCMToken();
});

