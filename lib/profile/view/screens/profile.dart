import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uborrow/auth/view/screens/auth_screen.dart';
import 'package:uborrow/auth/viewmodel/auth_view_model.dart';
import 'package:uborrow/home/view/screens/notifications_screen.dart';
import 'package:uborrow/home/view/screens/requests.dart';
import 'package:uborrow/home/view/widgets/my_nested_scroll_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    return MyNestedScrollView(
      title: const Text("Profile"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ---------------- PROFILE HEADER ----------------
            CircleAvatar(
              radius: 45,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 45)
                  : null,
            ),
            const SizedBox(height: 15),
            Text(
              user?.displayName ?? "Student Name",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? "student@college.edu",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            const Text(
              "⭐ 4.9  •  Trusted Borrower",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 25),
            // ---------------- STATS SECTION ----------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _StatItem(value: "12", label: "Shared"),
                _StatItem(value: "8", label: "Borrowed"),
                _StatItem(value: "2", label: "Requests"),
              ],
            ),
            const SizedBox(height: 30),
            // ---------------- ACTIVITY SECTION ----------------
            _sectionTitle("Activity"),
            _profileTile(
              icon: Icons.inventory_2,
              title: "My Items",
              onTap: () {},
            ),
            _profileTile(
              icon: Icons.swap_horiz,
              title: "Borrow Requests",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RequestsScreen(),
                  ),
                );
              },
            ),
            _profileTile(
              icon: Icons.history,
              title: "Borrow History",
              onTap: () {},
            ),
            const SizedBox(height: 20),
            // ---------------- SETTINGS SECTION ----------------
            _sectionTitle("Settings"),
            _profileTile(icon: Icons.edit, title: "Edit Profile", onTap: () {}),
            _profileTile(
              icon: Icons.notifications,
              title: "Notifications",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            _profileTile(icon: Icons.lock, title: "Change Password"),
            const SizedBox(height: 20),
            // ---------------- LEGAL SECTION ----------------
            _sectionTitle("About"),
            _profileTile(icon: Icons.privacy_tip, title: "Privacy Policy"),
            _profileTile(icon: Icons.info_outline, title: "About App"),
            const SizedBox(height: 20),
            // ---------------- LOGOUT ----------------
            _profileTile(
              icon: Icons.logout,
              title: "Logout",
              color: Colors.red,
              onTap: () async {
                ref.read(authViewModelProvider.notifier).signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// =================== STAT ITEM ===================
class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}

// =================== PROFILE TILE ===================
Widget _profileTile({
  required IconData icon,
  required String title,
  VoidCallback? onTap,
  Color color = Colors.black,
}) {
  return ListTile(
    leading: Icon(icon, color: color),
    title: Text(title, style: TextStyle(color: color)),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    onTap: onTap,
  );
}

// =================== SECTION TITLE ===================
Widget _sectionTitle(String title) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
