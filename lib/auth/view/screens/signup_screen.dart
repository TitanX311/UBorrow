import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Name",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.white,
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
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.mail, color: Color(0xff4ac8f4)),
              fillColor: Colors.white,
              border: InputBorder.none,
            ),
          ),
        ),
        const Text(
          "Email",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.white,
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
        const Text(
          "Password",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.white,
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
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.lock, color: Color(0xff4ac8f4)),
              fillColor: Colors.white,
              border: InputBorder.none,
            ),
          ),
        ),
        const Spacer(flex: 2,),
        Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xff5bdeac),
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: const Text(
            "Log In",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        const Spacer(),
        const Center(
          child: Text(
            "Don't have a account REGISTER",
            style: TextStyle(color: Color(0xff1576fc)),
          ),
        ),
      ],
    );
  }
}
