import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uborrow/auth/view/screens/auth_screen.dart';
import 'package:uborrow/theme/app_theme.dart';
import 'package:uborrow/utils/constants.dart';
import 'home/view/screens/add_item.dart';
import 'home/view/screens/chat.dart';
import 'home/view/screens/home.dart';
import 'home/view/screens/item_details.dart';
import 'home/view/screens/profile.dart';
import 'home/view/screens/requests.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(child: BorrowHubApp()));
}

class BorrowHubApp extends StatelessWidget {
  const BorrowHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: "/authScreen",
      routes: {
        "/authScreen": (BuildContext context) => AuthScreen(),
        "/home": (BuildContext context) => HomeScreen(),
        "/add": (BuildContext context) => AddItemScreen(),
        "/requests": (BuildContext context) => RequestsScreen(),
        "/profile": (BuildContext context) => ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == "/item") {
          final item = settings.arguments as Map;
          return MaterialPageRoute(
            builder: (_) => ItemDetailsScreen(item: item),
          );
        }
        if (settings.name == "/chat") {
          final user = settings.arguments;
          return MaterialPageRoute(builder: (_) => ChatScreen(user: user));
        }
        return null;
      },
    );
  }
}
