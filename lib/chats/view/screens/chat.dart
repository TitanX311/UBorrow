import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uborrow/chats/repositories/chat_service.dart';
import 'package:uborrow/chats/view/screens/inbox.dart';
import '../widgets/user_tile.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatService = ref.watch(chatServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search chats...',
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() {}),
              )
            : const Text('Chats'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: chatService.getUsersWithLastMessage(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation with someone!',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data!;
          final searchTerm = _searchController.text.toLowerCase();

          final filteredUsers = searchTerm.isEmpty
              ? users
              : users.where((userData) {
                  final name = (userData['name'] ?? '')
                      .toString()
                      .toLowerCase();
                  final email = (userData['email'] ?? '')
                      .toString()
                      .toLowerCase();
                  final lastMessage = (userData['lastMessage'] ?? '')
                      .toString()
                      .toLowerCase();
                  return name.contains(searchTerm) ||
                      email.contains(searchTerm) ||
                      lastMessage.contains(searchTerm);
                }).toList();

          if (filteredUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No results found',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final userData = filteredUsers[index];
              return UserTile(
                name: userData['name'] ?? 'Unknown',
                lastMessage: userData['lastMessage'],
                lastMessageTime: userData['lastMessageTime'],
                unreadCount: userData['unreadCount'] ?? 0,
                imageUrl: userData['profileImage'],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InBox(
                        receiverEmail: userData['email'],
                        receiverId: userData['uid'],
                        receiverName: userData['name'] ?? 'Unknown',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to new chat or contacts screen
          _showNewChatDialog(context);
        },
        child: const Icon(Icons.edit),
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    final chatService = ref.read(chatServiceProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'New Chat',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: chatService.getUserStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final users = snapshot.data!
                      .where(
                        (userData) =>
                            userData['email'] !=
                            chatService.getCurrentUser()!.email,
                      )
                      .toList();

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData = users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(userData['name'][0].toUpperCase()),
                        ),
                        title: Text(userData['name']),
                        subtitle: Text(userData['email']),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InBox(
                                receiverEmail: userData['email'],
                                receiverId: userData['uid'],
                                receiverName: userData['name'],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
