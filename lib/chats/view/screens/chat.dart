import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uborrow/chats/repositories/chat_service.dart';
import 'package:uborrow/chats/view/screens/inbox.dart';

import '../widgets/user_tile.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatService = ref.watch(chatServiceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: StreamBuilder(
        stream: chatService.getUserStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: snapshot.data!
                .where(
                  (userData) =>
                      userData['email'] != chatService.getCurrentUser()!.email,
                )
                .map<Widget>(
                  (userData) => UserTile(
                    text: userData['email'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InBox(
                            receiverEmail: userData['email'],
                            receiverId: userData['uid'],
                          ),
                        ),
                      );
                    },
                    name: userData['name'],
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
