import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uborrow/auth/view/screens/auth_screen.dart';
import 'package:uborrow/auth/viewmodel/auth_service.dart';
import 'package:uborrow/home/view/screens/main_screen.dart';

class AuthGate extends StatelessWidget {
  AuthGate({super.key});

  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return MainScreen();
          } else {
            return const AuthScreen();
          }
        },
      ),
    );
  }

  void signout() {
    _auth.signout();
  }
}
