import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uborrow/auth/viewmodel/auth_view_model.dart';
import 'package:uborrow/theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    ref.listen(authViewModelProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next!.error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (next is AsyncData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login successful"),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Email",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.white),
          ),
          child: TextFormField(
            controller: emailCtrl,
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.mail, color: AppColors.turquoise),
              fillColor: AppColors.white,
              border: InputBorder.none,
            ),
          ),
        ),
        const Spacer(),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Password",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.white),
          ),
          child: TextFormField(
            controller: passCtrl,
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.lock, color: AppColors.turquoise),
              fillColor: AppColors.white,
              border: InputBorder.none,
            ),
          ),
        ),
        const Spacer(),
        const Spacer(),
        GestureDetector(
          onTap: () {
            ref.read(authViewModelProvider.notifier).loginWithEmailAndPassword(emailCtrl.text, passCtrl.text);
            
          },
          child: Container(
            height: 40,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(30),
            ),
            alignment: Alignment.center,
            child: const Text(
              "Log In",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        const Spacer(),
        const Center(
          child: Text(
            "Don't have a account REGISTER",
            style: TextStyle(color: AppColors.blue),
          ),
        ),
      ],
    );
  }
}
