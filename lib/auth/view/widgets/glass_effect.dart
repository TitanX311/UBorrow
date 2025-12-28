import 'dart:ui';

import 'package:flutter/material.dart';

class GlassEffect extends StatelessWidget {
  final bool name;
  final VoidCallback onTap;
  final TextEditingController? nameController;
  final TextEditingController? hostelController;
  final TextEditingController? phoneController;

  const GlassEffect({
    super.key,
    required this.name,
    required this.onTap,
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
          height: MediaQuery.sizeOf(context).height * 0.5,
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
                            color: Colors.white,
                            fontSize: 16,
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