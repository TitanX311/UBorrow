import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/viewmodel/auth_viewmodel.dart';

class ProfileScreen extends ConsumerWidget {
  final user = {
    "name": "Abir Debnath",
    "year": "1st Year",
    "hostel": "Hall 3 - Room 219",
    "rating": 4.9
  };

  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final authViewModel = ref.read(authViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            SizedBox(height: 15),
            Text(authState.user?.displayName ?? "${user["name"]}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(authState.user?.email ?? "${user["year"]} • ${user["hostel"]}"),
            SizedBox(height: 10),
            Text("Rating: ⭐ ${user["rating"]}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 30),
            ElevatedButton(
              child: Text("Logout"),
              onPressed: () async {
                 await authViewModel.signOut();
                 Navigator.pushNamedAndRemoveUntil(context, "/authScreen", (route) => false);
              },
            )
          ],
        ),
      ),
    );
  }
}
