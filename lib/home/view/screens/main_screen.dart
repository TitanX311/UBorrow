import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:uborrow/chats/view/screens/chat.dart';
import 'package:uborrow/home/view/screens/home.dart';
import 'package:uborrow/profile/view/screens/profile.dart';
import 'package:uborrow/theme/app_colors.dart';

class MainScreen extends StatelessWidget {
  MainScreen({super.key});

  final PersistentTabController _controller = PersistentTabController(
    initialIndex: 0,
  );

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: [const HomeScreen(), ChatScreen(), ProfileScreen()],
      items: [
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.home, size: 30),
          title: 'Home',
          activeColorPrimary: AppColors.blue,
        ),
        // PersistentBottomNavBarItem(
        //   icon: const Icon(Icons.add, size: 30),
        //   title: 'Add',
        //   activeColorPrimary: AppColors.blue,
        // ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.chat, size: 30),
          title: 'Chat',
          activeColorPrimary: AppColors.blue,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.person, size: 30),
          title: 'Profile',
          activeColorPrimary: AppColors.blue,
        ),
      ],
      animationSettings: const NavBarAnimationSettings(
        navBarItemAnimation: ItemAnimationSettings(
          // Navigation Bar's items animation properties.
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        ),
        screenTransitionAnimation: ScreenTransitionAnimationSettings(
          // Screen transition animation on change of selected tab.
          animateTabTransition: true,
          duration: Duration(milliseconds: 200),
          screenTransitionAnimationType: ScreenTransitionAnimationType.slide,
        ),
      ),
      padding: const EdgeInsets.only(top: 8),
      navBarHeight: kBottomNavigationBarHeight,
      backgroundColor: AppColors.white,
      navBarStyle: NavBarStyle.style12,
    );
  }
}
