import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uborrow/chats/model/message.dart';
import 'package:uborrow/chats/repositories/chat_service.dart';

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
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _performSend(Future<void> Function() action) async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      await action();
      if (mounted) {
        _scrollToBottom();
      }
    } catch (e) {
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendPreset(String messageType) async {
    await _performSend(() async {
      await ref
          .read(chatServiceProvider)
          .sendPresetMessage(
            receiverId: widget.receiverId,
            messageType: messageType,
          );
    });
  }

  Future<void> _pickAndSendMeetingTime() async {
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: DateTime.now(),
    );

    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime == null || !mounted) return;

    final meetingAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    await _performSend(() async {
      await ref
          .read(chatServiceProvider)
          .sendMeetingTimeMessage(
            receiverId: widget.receiverId,
            meetingAt: meetingAt,
          );
    });
  }

  Future<void> _shareContact() async {
    final shouldShare = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Share contact details?'),
          content: const Text(
            'This will share your saved email and phone number.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Share'),
            ),
          ],
        );
      },
    );

    if (shouldShare != true) return;

    await _performSend(() async {
      await ref
          .read(chatServiceProvider)
          .sendContactShareMessage(receiverId: widget.receiverId);
    });
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

  void _showMessageOptions(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final currentUser = ref.read(chatServiceProvider).getCurrentUser();
    final isCurrentUser = data['senderId'] == currentUser?.uid;

    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentUser)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Message'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
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
                Navigator.pop(bottomSheetContext);
                Clipboard.setData(ClipboardData(text: data['message'] ?? ''));
              },
            ),
          ],
        ),
      ),
    );
  }

  String _displayMessageText(Map<String, dynamic> data) {
    final messageType = data['messageType'] as String?;
    switch (messageType) {
      case ChatMessageType.iHaveThis:
        return 'I have this';
      case ChatMessageType.isAvailable:
        return 'Is this available?';
      case ChatMessageType.whenCollect:
        return 'When can I collect it?';
      case ChatMessageType.whereMeet:
        return 'Where can we meet?';
      case ChatMessageType.thanks:
        return 'Thank you';
      case ChatMessageType.meetingTime:
        return 'Proposed meeting time';
      case ChatMessageType.shareContact:
        return 'Shared contact details';
      case ChatMessageType.requestReference:
      case ChatMessageType.borrowRequest:
      default:
        return (data['message'] as String?) ?? '';
    }
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isRequestReference =
        data['messageType'] == ChatMessageType.requestReference;
    final isBorrowRequest =
        data['messageType'] == ChatMessageType.borrowRequest;
    final isMeetingTime = data['messageType'] == ChatMessageType.meetingTime;
    final isContactShare = data['messageType'] == ChatMessageType.shareContact;

    final requestItemName = (data['requestItemName'] as String?)?.trim();
    final itemName = (data['itemName'] as String?)?.trim();
    final sharedEmail = (data['sharedEmail'] as String?)?.trim();
    final sharedPhone = (data['sharedPhone'] as String?)?.trim();
    final meetingAt = data['meetingAt'] as Timestamp?;
    final meetingNote = (data['meetingNote'] as String?)?.trim();

    final isCurrentUser =
        data['senderId'] ==
        ref.watch(chatServiceProvider).getCurrentUser()!.uid;

    final bubbleColor = isCurrentUser ? Colors.blue : Colors.grey.shade300;
    final textColor = isCurrentUser ? Colors.white : Colors.black;

    return GestureDetector(
      onLongPress: () => _showMessageOptions(context, doc),
      child: Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
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
                  _displayMessageText(data),
                  style: TextStyle(color: textColor, fontSize: 15),
                ),
                if (isMeetingTime && meetingAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: isCurrentUser
                              ? Colors.white70
                              : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat(
                            'EEE, MMM d • hh:mm a',
                          ).format(meetingAt.toDate()),
                          style: TextStyle(
                            color: isCurrentUser
                                ? Colors.white70
                                : Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isMeetingTime &&
                    meetingNote != null &&
                    meetingNote.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      meetingNote,
                      style: TextStyle(
                        color: isCurrentUser
                            ? Colors.white70
                            : Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (isContactShare)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (sharedPhone != null && sharedPhone.isNotEmpty)
                          Text(
                            'Phone: $sharedPhone',
                            style: TextStyle(
                              color: isCurrentUser
                                  ? Colors.white70
                                  : Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        if (sharedEmail != null && sharedEmail.isNotEmpty)
                          Text(
                            'Email: $sharedEmail',
                            style: TextStyle(
                              color: isCurrentUser
                                  ? Colors.white70
                                  : Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
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

  Widget _buildMessageList() {
    final senderId = ref.watch(chatServiceProvider).getCurrentUser()!.uid;
    return StreamBuilder(
      stream: ref
          .watch(chatServiceProvider)
          .getMessages(widget.receiverId, senderId),
      builder: (context, snapshot) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToBottom();
            final currentUser = ref.read(chatServiceProvider).getCurrentUser();
            if (currentUser != null) {
              ref
                  .read(chatServiceProvider)
                  .markMessagesAsRead(currentUser.uid, widget.receiverId);
            }
          }
        });

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading messages'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final type = data['messageType'] as String?;
          return type != null && ChatMessageType.allowed.contains(type);
        }).toList();

        if (docs.isEmpty) {
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
                  'Start with a quick message below',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final showDate =
                index == 0 || _shouldShowDateHeader(docs[index - 1], doc);

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

  Widget _buildPresetButton(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
        onPressed: _isSending ? null : onTap,
      ),
    );
  }

  Widget _buildUserInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetButton(
                  'I have this',
                  Icons.inventory_2_outlined,
                  () {
                    _sendPreset(ChatMessageType.iHaveThis);
                  },
                ),
                _buildPresetButton('Available?', Icons.help_outline, () {
                  _sendPreset(ChatMessageType.isAvailable);
                }),
                _buildPresetButton('Collect when?', Icons.schedule, () {
                  _sendPreset(ChatMessageType.whenCollect);
                }),
                _buildPresetButton('Where meet?', Icons.place_outlined, () {
                  _sendPreset(ChatMessageType.whereMeet);
                }),
                _buildPresetButton('Thank you', Icons.favorite_outline, () {
                  _sendPreset(ChatMessageType.thanks);
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSending ? null : _pickAndSendMeetingTime,
                  icon: const Icon(Icons.event_available),
                  label: const Text('Share Meeting Time'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSending ? null : _shareContact,
                  icon: const Icon(Icons.contact_phone_outlined),
                  label: const Text('Share Contact'),
                ),
              ),
            ],
          ),
          if (_isSending)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.receiverName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
}
