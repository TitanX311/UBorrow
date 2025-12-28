import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uborrow/auth/view/widgets/background.dart';
import 'package:uborrow/auth/view/widgets/glass_effect.dart';
import 'package:uborrow/auth/viewmodel/auth_view_model.dart';
import 'package:uborrow/home/view/screens/main_screen.dart';

class DetailsGoogleSignin extends ConsumerWidget {
  const DetailsGoogleSignin({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hostelController = TextEditingController();
    final phoneController = TextEditingController();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
            backgroundColor: const Color(0xffd3effb),
            body: Stack(
              children: [
                // BackGround Section
                const Background(),
                // Glass Effect with Login UI
                GlassEffect(
                  name: false,
                  hostelController: hostelController,
                  phoneController: phoneController,
                  onTap: () async {
                    await ref
                        .read(authViewModelProvider.notifier)
                        .sendDetailsGoogle(
                          hostelController.text,
                          phoneController.text,
                        );
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => MainScreen()),
                    );
                  },
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            backgroundColor: const Color(0xffd3effb),
            body: const Background(),
          );
        }
      },
    );
  }
}

class DetailsRegister extends ConsumerWidget {
  const DetailsRegister({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final hostelController = TextEditingController();
    final phoneController = TextEditingController();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
            backgroundColor: const Color(0xffd3effb),
            body: Stack(
              children: [
                // BackGround Section
                const Background(),
                // Glass Effect with Login UI
                GlassEffect(
                  name: true,
                  nameController: nameController,
                  hostelController: hostelController,
                  phoneController: phoneController,
                  onTap: () async {
                    await ref
                        .read(authViewModelProvider.notifier)
                        .sendDetailsRegister(
                          nameController.text,
                          hostelController.text,
                          phoneController.text,
                        );
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => MainScreen()),
                    );
                  },
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            backgroundColor: const Color(0xffd3effb),
            body: const Background(),
          );
        }
      },
    );
  }
}
