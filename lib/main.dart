import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uborrow/splash_screen/splash_screen.dart';
import 'package:uborrow/theme/app_theme.dart';
import 'package:uborrow/utils/constants.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:uborrow/core/services/push_notification_service.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  CloudinaryContext.cloudinary = Cloudinary.fromCloudName(cloudName: 'demo');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize push notifications
  await PushNotificationService().initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // await FirebaseFirestore.instance.clearPersistence();

  runApp(ProviderScope(child: const BorrowHubApp()));
}

class BorrowHubApp extends StatelessWidget {
  const BorrowHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
