import 'package:flutter/material.dart';
import '../widgets/google_button.dart';

class LoginScreen extends StatelessWidget {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: emailCtrl,
            decoration: InputDecoration(
              labelText: "Email",
              border: OutlineInputBorder(),
            ),
          ),

          SizedBox(height: 15),

          TextField(
            controller: passCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: "Password",
              border: OutlineInputBorder(),
            ),
          ),

          SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {},
            child: Text("Login"),
          ),

          SizedBox(height: 20),
          Text("or"),
          SizedBox(height: 10),

          GoogleButton(
            onpressed: (){},
          ),
        ],
      ),
    );
  }
}
