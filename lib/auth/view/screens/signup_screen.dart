import 'package:flutter/material.dart';
import 'package:uborrow/auth/repository/auth_service.dart';
import 'package:uborrow/auth/view/screens/details.dart';
import 'package:uborrow/theme/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPwCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: const Text(
            "Email",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white),
          ),
          child: TextFormField(
            controller: emailCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.mail, color: Color(0xff4ac8f4)),
              fillColor: Colors.white,
              border: InputBorder.none,
            ),
          ),
        ),
        // const Spacer(),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: const Text(
            "Password",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white),
          ),
          child: TextFormField(
            controller: passCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.lock, color: Color(0xff4ac8f4)),
              fillColor: Colors.white,
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: const Text(
            "Confirm Password",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white),
          ),
          child: TextFormField(
            controller: confirmPwCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.lock, color: Color(0xff4ac8f4)),
              fillColor: Colors.white,
              border: InputBorder.none,
            ),
          ),
        ),
        const Spacer(flex: 2),
        GestureDetector(
          onTap: () async {
            if (passCtrl.text != confirmPwCtrl.text) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("not same")));
            } else {
              register(context);
            }
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
              "Register",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const Spacer(),
        const Center(
          child: Text(
            "Already a user? LOGIN",
            style: TextStyle(color: AppColors.blue),
          ),
        ),
      ],
    );
  }

  void register(BuildContext context) {
    final authService = AuthService();
    try {
      authService.signupWithEmail(emailCtrl.text, passCtrl.text);
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => DetailsRegister()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }
}
