import 'package:flutter/material.dart';
import 'package:uborrow/chats/view/screens/inbox.dart';
import 'package:uborrow/chats/viewmodel/chat_service.dart';

import '../widgets/user_tile.dart';

class ChatScreen extends StatelessWidget {
  ChatScreen({super.key});

  final ChatService _chatService = ChatService();

  // final AuthS _chatService = ChatService();

  Widget _buildUserList() {
    return StreamBuilder(
      stream: _chatService.getUserStream(),
      builder: (context, snapshot) {
        //error
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        //loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        //return listview
        return ListView(
          children: snapshot.data!
              .map<Widget>((userData) => _buildUserListItem(userData, context))
              .toList(),
        );
      },
    );
  }

  Widget _buildUserListItem(
    Map<String, dynamic> userData,
    BuildContext context,
  ) {
    //display all user except current user
    return UserTile(
      text: userData['email'],
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InBox(user: userData['email']),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: ListView.builder(
        itemCount: 2, // Replace with actual chat count
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(
              // In a real app, you'd have user avatars
              child: Icon(Icons.person),
            ),
            title: const Text('User123'),
            // Replace with actual user name
            subtitle: const Text('I\'m coming!'),
            // Replace with last message
            trailing: const Text('10:42 AM'),
            // Replace with message time
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InBox(user: 'User123')),
              );
            },
          );
        },
      ),
    );
  }
}
