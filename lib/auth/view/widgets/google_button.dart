import 'package:flutter/material.dart';

class GoogleButton extends StatelessWidget {
  final VoidCallback onpressed;

  const GoogleButton({super.key,required this.onpressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onpressed, child: const Text('Google'));
  }
}
