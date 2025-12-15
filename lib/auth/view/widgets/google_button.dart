import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uborrow/theme/app_colors.dart';
import 'package:uborrow/utils/constants.dart';

class GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GoogleButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      color: AppColors.white,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 50,
          width: MediaQuery.of(context).size.width - 60,
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                AppConstants.googleIcon,
                height: 24,
                width: 24,
              ),
              const SizedBox(width: 10,),
              const Text('Continue with Google')
            ],
          ),
        ),
      ),
    );
  }
}
