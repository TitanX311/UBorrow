import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    _controller = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Campus Borrow Hub"),
        bottom: TabBar(
          controller: _controller,
          tabs: const [
            Tab(text: "Login"),
            Tab(text: "Signup"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _controller,
        children: [
          LoginScreen(),
          SignupScreen(),
        ],
      ),
    );
  }
}
