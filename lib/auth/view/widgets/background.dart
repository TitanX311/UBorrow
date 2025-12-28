import 'package:flutter/material.dart';

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