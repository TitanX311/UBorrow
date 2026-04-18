import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uborrow/chats/repositories/chat_service.dart';
import 'package:intl/intl.dart';

class InBox extends ConsumerStatefulWidget {
  final String receiverEmail;
  final String receiverId;
  final String receiverName;

  const InBox({
    super.key,
    required this.receiverEmail,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  ConsumerState<InBox> createState() => _InBoxState();
}

class _InBoxState extends ConsumerState<InBox> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToBottom();
      }
    });

    // Typing indicator
    _messageController.addListener(_onTypingChanged);
  }

  void _onTypingChanged() {
    if (!mounted) return;

    final isTyping = _messageController.text.isNotEmpty;
    if (isTyping != _isTyping) {
      _isTyping = isTyping;
      try {
        final currentUser = ref.read(chatServiceProvider).getCurrentUser();
        if (currentUser != null) {
          ref
              .read(chatServiceProvider)
              .setTypingStatus(currentUser.uid, widget.receiverId, isTyping);
        }
      } catch (e) {
        // Silently ignore errors when widget is disposed
      }
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTypingChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();

    // Clear typing status without accessing ref
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final message = _messageController.text;
      _messageController.clear();

      try {
        await ref
            .read(chatServiceProvider)
            .sendMessage(widget.receiverId, message);

        // Clear typing status safely
        if (mounted) {
          final currentUser = ref.read(chatServiceProvider).getCurrentUser();
          if (currentUser != null) {
            ref
                .read(chatServiceProvider)
                .setTypingStatus(currentUser.uid, widget.receiverId, false);
          }
        }
      } catch (e) {
        // Handle error silently or show to user
      }
      _isTyping = false;
    }
  }

  String _formatMessageTime(Timestamp timestamp) {
    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(messageTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(messageTime)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE HH:mm').format(messageTime);
    } else {
      return DateFormat('MMM d, HH:mm').format(messageTime);
    }
  }

  void _showMessageOptions(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final currentUser = ref.read(chatServiceProvider).getCurrentUser();
    final isCurrentUser = data['senderId'] == currentUser?.uid;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentUser)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Message'),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(chatServiceProvider)
                      .deleteMessage(
                        doc.id,
                        currentUser!.uid,
                        widget.receiverId,
                      );
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Text'),
              onTap: () {
                Navigator.pop(context);
                // Copy to clipboard functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.receiverName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            StreamBuilder<bool>(
              stream: ref
                  .watch(chatServiceProvider)
                  .getTypingStatus(
                    ref.watch(chatServiceProvider).getCurrentUser()!.uid,
                    widget.receiverId,
                  ),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return const Text(
                    'typing...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildUserInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    String senderId = ref.watch(chatServiceProvider).getCurrentUser()!.uid;
    return StreamBuilder(
      stream: ref
          .watch(chatServiceProvider)
          .getMessages(widget.receiverId, senderId),
      builder: (context, snapshot) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToBottom();
            // Mark messages as read when they load
            try {
              final currentUser = ref
                  .read(chatServiceProvider)
                  .getCurrentUser();
              if (currentUser != null) {
                ref
                    .read(chatServiceProvider)
                    .markMessagesAsRead(currentUser.uid, widget.receiverId);
              }
            } catch (e) {
              // Silently ignore
            }
          }
        });

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading messages"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  "Be the first to say hi! 👋",
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final showDate =
                index == 0 ||
                _shouldShowDateHeader(snapshot.data!.docs[index - 1], doc);

            return Column(
              children: [
                if (showDate) _buildDateHeader(doc),
                _buildMessageItem(doc),
              ],
            );
          },
        );
      },
    );
  }

  bool _shouldShowDateHeader(DocumentSnapshot prev, DocumentSnapshot current) {
    final prevData = prev.data() as Map<String, dynamic>;
    final currentData = current.data() as Map<String, dynamic>;

    final prevTime = (prevData['timestamp'] as Timestamp).toDate();
    final currentTime = (currentData['timestamp'] as Timestamp).toDate();

    return prevTime.day != currentTime.day ||
        prevTime.month != currentTime.month ||
        prevTime.year != currentTime.year;
  }

  Widget _buildDateHeader(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['timestamp'] as Timestamp;
    final date = timestamp.toDate();
    final now = DateTime.now();

    String dateText;
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      dateText = 'Today';
    } else if (date.day == now.day - 1 &&
        date.month == now.month &&
        date.year == now.year) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final isRequestReference = data['messageType'] == 'request_reference';
    final isBorrowRequest = data['messageType'] == 'borrow_request';
    final requestItemName = (data['requestItemName'] as String?)?.trim();
    final itemName = (data['itemName'] as String?)?.trim();
    bool isCurrentUser =
        data['senderId'] ==
        ref.watch(chatServiceProvider).getCurrentUser()!.uid;

    var bubbleColor = isCurrentUser ? Colors.blue : Colors.grey.shade300;
    var textColor = isCurrentUser ? Colors.white : Colors.black;

    return GestureDetector(
      onLongPress: () => _showMessageOptions(context, doc),
      child: Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isCurrentUser ? 20 : 4),
                bottomRight: Radius.circular(isCurrentUser ? 4 : 20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data["message"] ?? '',
                  style: TextStyle(color: textColor, fontSize: 15),
                ),
                if (isRequestReference)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      requestItemName != null && requestItemName.isNotEmpty
                          ? 'Request: $requestItemName'
                          : 'Request reference attached',
                      style: TextStyle(
                        color: isCurrentUser
                            ? Colors.white70
                            : Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (isBorrowRequest)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      itemName != null && itemName.isNotEmpty
                          ? 'Item: $itemName'
                          : 'Borrow request attached',
                      style: TextStyle(
                        color: isCurrentUser
                            ? Colors.white70
                            : Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatMessageTime(data['timestamp']),
                      style: TextStyle(
                        color: isCurrentUser
                            ? Colors.white70
                            : Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 4),
                      Icon(
                        data['isRead'] == true ? Icons.done_all : Icons.done,
                        size: 14,
                        color: data['isRead'] == true
                            ? Colors.blue.shade100
                            : Colors.white70,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: "Message...",
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      // TODO: Emoji picker functionality
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: sendMessage,
              icon: const Icon(Icons.send),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
