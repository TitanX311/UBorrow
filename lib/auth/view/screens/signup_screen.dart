import 'package:flutter/material.dart';

import '../widgets/google_button.dart';

class SignupScreen extends StatelessWidget {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: "Full Name",
              border: OutlineInputBorder(),
            ),
          ),

          SizedBox(height: 15),

          TextField(
            controller: emailCtrl,
            decoration: InputDecoration(
              labelText: "Email (College Preferred)",
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
            child: Text("Create Account"),
          ),

          SizedBox(height: 20),
          Text("or"),
          SizedBox(height: 10),

          GoogleButton(
            onpressed: (){
              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Something went wrong');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text("Loading...");
                  }

                  if (!snapshot.hasData) {
                    return const SignInScreen();
                  }

                  final user = snapshot.data!;
                  return HomeScreen(userId: user.uid);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
