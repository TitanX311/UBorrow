import 'package:flutter/material.dart';
import 'package:uborrow/theme/app_colors.dart';

class UserTile extends StatelessWidget {
 final String text;
 final void Function()? onTap;

  const UserTile({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: AppColors.skyBlue,borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            //icon
            Icon(Icons.person),
            //username
            Text(text),
          ],
        ),
      ),

    );
  }
}
