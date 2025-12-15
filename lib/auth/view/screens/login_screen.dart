import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uborrow/auth/viewmodel/auth_viewmodel.dart';
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
    final authState = ref.watch(authViewModelProvider);
    final authViewModelNotifier = ref.read(authViewModelProvider.notifier);

    // Listen to error changes
    ref.listen(authViewModelProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
      if (next.user != null && previous?.user == null) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: const Text(
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
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.mail, color: AppColors.inputIcon),
              fillColor: AppColors.white,
              border: InputBorder.none,
            ),
          ),
        ),
        const Spacer(),
        Align(
          alignment: Alignment.centerLeft,
          child: const Text(
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
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.lock, color: AppColors.inputIcon),
              fillColor: AppColors.white,
              border: InputBorder.none,
            ),
          ),
        ),
        const Spacer(),
        const Spacer(),
        Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryButton,
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
        const Spacer(),
        const Center(
          child: Text(
            "Don't have a account REGISTER",
            style: TextStyle(color: AppColors.linkText),
          ),
        ),
      ],
    );
  }
}
