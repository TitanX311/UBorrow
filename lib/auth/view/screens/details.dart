import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uborrow/auth/model/user_model.dart';
import 'package:uborrow/home/view/screens/main_screen.dart';

class DetailsGoogleSignin extends StatelessWidget {
  const DetailsGoogleSignin({super.key});

  @override
  Widget build(BuildContext context) {
    final hostelController = TextEditingController();
    final phoneController = TextEditingController();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.hasData) {
          final user = snapshot.data!;
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
                    final userModel = UserModel(
                      id: user.uid,
                      email: user.email,
                      name: user.displayName,
                      photoURL: user.photoURL,
                      hostel: hostelController.text,
                      phoneNumber: phoneController.text,
                    );
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .set(userModel.toJson());
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

class DetailsRegister extends StatelessWidget {
  const DetailsRegister({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final hostelController = TextEditingController();
    final phoneController = TextEditingController();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.hasData) {
          final user = snapshot.data!;
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
                    final userModel = UserModel(
                      id: user.uid,
                      email: user.email,
                      name: nameController.text,
                      hostel: hostelController.text,
                      phoneNumber: phoneController.text,
                    );
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .set(userModel.toJson());
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

class Background extends StatelessWidget {
  const Background({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
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
                    colors: [Color(0xff48c6f9), Color(0xff58e0aa)],
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
                      colors: [Color(0xff1578f8), Color(0xff44c5ff)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(flex: 2, child: Container()),
      ],
    );
  }
}

class GlassEffect extends StatelessWidget {
  final bool name;
  final VoidCallback? onTap;
  final TextEditingController? nameController;
  final TextEditingController? hostelController;
  final TextEditingController? phoneController;

  const GlassEffect({
    super.key,
    required this.name,
    this.onTap,
    this.nameController,
    this.hostelController,
    this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 400,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(15),
            color: Colors.white.withOpacity(0.1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaY: 20, sigmaX: 20),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    const Center(
                      child: Text(
                        "Please Enter the following Details",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (name) ...[
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
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            suffixIcon: Icon(
                              Icons.person,
                              color: Color(0xff4ac8f4),
                            ),
                            fillColor: Colors.white,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    const Text(
                      "Hostel",
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
                        controller: hostelController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          suffixIcon: Icon(
                            Icons.home,
                            color: Color(0xff4ac8f4),
                          ),
                          fillColor: Colors.white,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      "Phone number",
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
                        controller: phoneController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          suffixIcon: Icon(
                            Icons.phone,
                            color: Color(0xff4ac8f4),
                          ),
                          fillColor: Colors.white,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        height: 40,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xff5bdeac),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Enter",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
