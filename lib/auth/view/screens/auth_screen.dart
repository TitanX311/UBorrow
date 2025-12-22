import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uborrow/auth/view/screens/details.dart';
import 'package:uborrow/auth/view/widgets/google_button.dart';
import 'package:uborrow/auth/viewmodel/auth_view_model.dart';
import 'package:uborrow/theme/app_colors.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  // Initialize with the starting index height if known or use a default
  double _containerHeight = 400;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this);
    _controller.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTabSelection);
    _controller.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    // Check which tab is active and set height accordingly

    setState(() {
      if (_controller.index == 0) {
        // Login Screen Height
        _containerHeight = 400;
      } else {
        // Signup Screen Height - slightly larger to accommodate overflow if needed
        _containerHeight = 460;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      body: Stack(
        children: [
          /////////// ******* BackGround Section ****** //////////
          Column(
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(30),
                        ),
                        gradient: LinearGradient(
                          colors: [AppColors.skyBlue, AppColors.seafoamGreen],
                        ),
                      ),
                    ),
                    Positioned(
                      left: -100,
                      top: -50,
                      child: Container(
                        height: MediaQuery.sizeOf(context).height * 0.55,
                        width: MediaQuery.sizeOf(context).width + 20,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppColors.royalBlue,
                              AppColors.lightSkyBlue,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(flex: 2, child: Container()),
            ],
          ),
          ///////// ****** Glass Effect with Login UI ****** ///////////
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Welcome Back!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                key: ValueKey(_controller.index),
                //it rebuilds this container solving the renderflow error when switching from signup to login tab
                height: _containerHeight,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.white),
                  borderRadius: BorderRadius.circular(15),
                  color: AppColors.white.withOpacity(0.1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaY: 20, sigmaX: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TabBar(
                            controller: _controller,
                            tabs: const [
                              Tab(text: "Login"),
                              Tab(text: "SignUp"),
                            ],
                          ),
                          // const Spacer(),
                          const SizedBox(height: 20),
                          Expanded(
                            child: TabBarView(
                              controller: _controller,
                              children: const [LoginScreen(), SignupScreen()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GoogleButton(
                onPressed: () {
                  ref.read(authViewModelProvider.notifier).signinWithGoogle();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DetailsGoogleSignin(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
