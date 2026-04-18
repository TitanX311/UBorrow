import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uborrow/utils/constants.dart';

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
          .collection(AppCollections.needRequests)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        if (!snapshot.hasData) {
          return const Center(child: Text("No requests from others right now"));
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['requesterId'] != user.uid;
        }).toList();

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "No requests from others right now",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _NeedRequestCard(data: data, requestId: doc.id);
          },
        );
      },
    );
  }
}

class _NeedRequestCard extends ConsumerWidget {
  final Map<String, dynamic> data;
  final String requestId;

  const _NeedRequestCard({required this.data, required this.requestId});

  Future<void> _handleIHaveThis(BuildContext context, WidgetRef ref) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final requesterId = data['requesterId'] as String?;
    final itemName = data['itemName'] as String? ?? 'Unknown item';

    if (requesterId == null || requesterId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid request'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      
      await firestore.runTransaction((transaction) async {
        final requestRef = firestore
            .collection(AppCollections.needRequests)
            .doc(requestId);
        
        final requestDoc = await transaction.get(requestRef);
        
        if (!requestDoc.exists) {
          throw Exception('Request not found');
        }

        final requestData = requestDoc.data() ?? <String, dynamic>{};
        final status = requestData['status'] as String? ?? NeedRequestStatus.open;
        final fulfilledBy = requestData['fulfilledBy'] as String?;

        if (status != NeedRequestStatus.open ||
            (fulfilledBy != null && fulfilledBy.isNotEmpty)) {
          throw Exception('This request has already been fulfilled');
        }

        transaction.update(requestRef, {
          'status': NeedRequestStatus.fulfilled,
          'fulfilledBy': currentUser.uid,
          'fulfilledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      final participantIds = [currentUser.uid, requesterId]..sort();
      final chatRoomId = participantIds.join('_');

      final timestamp = Timestamp.now();
      await firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'senderEmail': currentUser.email ?? '',
        'receiverId': requesterId,
        'message': 'I have this',
        'timestamp': timestamp,
        'isRead': false,
        'isAutomated': true,
        'messageType': 'request_reference',
        'requestId': requestId,
        'requestItemName': itemName,
      });

      await firestore.collection('chat_rooms').doc(chatRoomId).set({
        'participants': participantIds,
        'lastMessage': 'I have this',
        'lastMessageTime': timestamp,
        'lastMessageSenderId': currentUser.uid,
        'lastMessageType': 'request_reference',
        'lastRequestId': requestId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = data['status'] ?? NeedRequestStatus.open;

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
                  '"${data['message']}"',
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
                if (status == NeedRequestStatus.open)
                  ElevatedButton.icon(
                    onPressed: () => _handleIHaveThis(context, ref),
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
      case NeedRequestStatus.matched:
        color = Colors.blue;
        icon = Icons.link;
        break;
      case NeedRequestStatus.fulfilled:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case NeedRequestStatus.open:
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

