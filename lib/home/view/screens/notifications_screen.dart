import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uborrow/home/view/screens/add_item.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'General'),
              Tab(text: 'Requests'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_GeneralNotificationsTab(), _RequestNotificationsTab()],
        ),
      ),
    );
  }
}

class _GeneralNotificationsTab extends StatelessWidget {
  const _GeneralNotificationsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ListTile(
          leading: CircleAvatar(child: Icon(Icons.person)),
          title: Text('You accepted a request for Helmet'),
          subtitle: Text('1 day ago'),
        ),
        ListTile(
          leading: CircleAvatar(child: Icon(Icons.info_outline)),
          title: Text('Welcome to uBorrow'),
          subtitle: Text('2 days ago'),
        ),
      ],
    );
  }
}

class _RequestNotificationsTab extends ConsumerWidget {
  const _RequestNotificationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("Please sign in"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('item_requests')
          .where('requesterId', isNotEqualTo: user.uid) // don’t show own needs
          .orderBy('requesterId')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No requests from others right now",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _NeedRequestCard(data: data, requestId: doc.id);
          },
        );
      },
    );
  }
}

class _NeedRequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String requestId;

  const _NeedRequestCard({required this.data, required this.requestId});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Open';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              data['itemName'] ?? 'Unknown item',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            // Period
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  data['period'] ?? 'Not specified',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            if (data['message'] != null &&
                (data['message'] as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '“${data['message']}”',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // Status + action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _needStatusChip(status),
                if (status == 'Open')
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              AddItemScreen(fromRequestId: requestId),
                        ),
                      );
                      //after adding remove the request
                    },
                    icon: const Icon(Icons.inventory_2_outlined, size: 18),
                    label: const Text("I have this"),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _needStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'Matched':
        color = Colors.blue;
        icon = Icons.link;
        break;
      case 'Fulfilled':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'Open':
      default:
        color = Colors.orange;
        icon = Icons.campaign;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(status, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }
}
