import 'package:flutter/material.dart';
import 'package:uborrow/theme/app_colors.dart';

class NotificationButton extends StatelessWidget {
  final int notificationCount;
  final void Function() onPressed;

  const NotificationButton({
    super.key,
    required this.onPressed,
    required this.notificationCount,
  });

  final double buttonSize = 30;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: Stack(
          children: [
            Icon(
              Icons.notifications,
              color: AppColors.transparentBlack,
              size: buttonSize,
            ),
            Container(
              width: buttonSize,
              height: buttonSize,
              alignment: Alignment.topRight,
              margin: const EdgeInsets.only(top: 5),
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.red,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Center(
                  child: Text(
                    notificationCount.toString(),
                    style: const TextStyle(fontSize: 10,color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
