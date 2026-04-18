import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uborrow/chats/model/message.dart';

part 'chat_service.g.dart';

@riverpod
ChatService chatService(ChatServiceRef ref) {
  return ChatService();
}

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  static const Map<String, String> presetLabels = {
    ChatMessageType.iHaveThis: 'I have this',
    ChatMessageType.isAvailable: 'Is this available?',
    ChatMessageType.whenCollect: 'When can I collect it?',
    ChatMessageType.whereMeet: 'Where can we meet?',
    ChatMessageType.thanks: 'Thank you',
  };

  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        user['uid'] = doc.id; // Ensure uid is included
        return user;
      }).toList();
    });
  }

  // Get users with last message preview
  Stream<List<Map<String, dynamic>>> getUsersWithLastMessage() {
    final currentUserId = getCurrentUser()!.uid;

    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> usersWithMessages = [];

          for (final roomDoc in snapshot.docs) {
            final roomData = roomDoc.data();
            final participants =
                (roomData['participants'] as List<dynamic>? ?? [])
                    .map((e) => e.toString())
                    .toList();

            if (!participants.contains(currentUserId)) {
              continue;
            }

            final otherUserId = participants.firstWhere(
              (id) => id != currentUserId,
              orElse: () => '',
            );

            if (otherUserId.isEmpty) {
              continue;
            }

            final userSnapshot = await _firestore
                .collection('users')
                .doc(otherUserId)
                .get();

            final user = userSnapshot.data() ?? <String, dynamic>{};
            user['uid'] = otherUserId;
            user['lastMessage'] = roomData['lastMessage'];
            user['lastMessageTime'] = roomData['lastMessageTime'];
            user['unreadCount'] = await getUnreadCount(
              currentUserId,
              otherUserId,
            );

            usersWithMessages.add(user);
          }

          // Sort by last message time
          usersWithMessages.sort((a, b) {
            if (a['lastMessageTime'] == null && b['lastMessageTime'] == null)
              return 0;
            if (a['lastMessageTime'] == null) return 1;
            if (b['lastMessageTime'] == null) return -1;
            return (b['lastMessageTime'] as Timestamp).compareTo(
              a['lastMessageTime'] as Timestamp,
            );
          });

          return usersWithMessages;
        });
  }

  Future<void> sendMessage(String receiverId, String message) async {
    throw Exception('Free-text messages are disabled');
  }

  Future<void> sendPresetMessage({
    required String receiverId,
    required String messageType,
  }) async {
    if (!presetLabels.containsKey(messageType)) {
      throw Exception('Invalid preset message');
    }

    final text = presetLabels[messageType]!;
    final now = Timestamp.now();
    final currentUserId = getCurrentUser()!.uid;
    final currentUserEmail = getCurrentUser()!.email ?? '';

    final newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      message: text,
      messageType: messageType,
      timestamp: now,
      isRead: false,
    );

    await _sendMessageRecord(newMessage);
  }

  Future<void> sendMeetingTimeMessage({
    required String receiverId,
    required DateTime meetingAt,
    String? meetingNote,
  }) async {
    final now = Timestamp.now();
    final currentUserId = getCurrentUser()!.uid;
    final currentUserEmail = getCurrentUser()!.email ?? '';

    final newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      message: 'Proposed meeting time',
      messageType: ChatMessageType.meetingTime,
      timestamp: now,
      isRead: false,
      meetingAt: Timestamp.fromDate(meetingAt),
      meetingNote: meetingNote?.trim().isEmpty == true ? null : meetingNote,
    );

    await _sendMessageRecord(newMessage, lastMessageOverride: 'Meeting time');
  }

  Future<void> sendContactShareMessage({required String receiverId}) async {
    final now = Timestamp.now();
    final currentUserId = getCurrentUser()!.uid;
    final currentUserEmail = getCurrentUser()!.email ?? '';
    final contact = await _resolveContactSnapshot(currentUserId);

    if ((contact['email']?.isEmpty ?? true) &&
        (contact['phone']?.isEmpty ?? true)) {
      throw Exception('No contact details available to share');
    }

    final newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      message: 'Shared contact details',
      messageType: ChatMessageType.shareContact,
      timestamp: now,
      isRead: false,
      sharedEmail: contact['email'],
      sharedPhone: contact['phone'],
    );

    await _sendMessageRecord(newMessage, lastMessageOverride: 'Contact shared');
  }

  Future<Map<String, String?>> _resolveContactSnapshot(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data() ?? <String, dynamic>{};

    final email = ((data['email'] as String?) ?? getCurrentUser()!.email ?? '')
        .trim();
    final phone = ((data['phoneNumber'] as String?) ?? '').trim();

    return {
      'email': email.isEmpty ? null : email,
      'phone': phone.isEmpty ? null : phone,
    };
  }

  Future<void> _sendMessageRecord(
    Message message, {
    String? lastMessageOverride,
  }) async {
    final ids = [message.senderId, message.receiverId]..sort();
    final chatRoomId = ids.join('_');

    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'participants': ids,
      'lastMessage': lastMessageOverride ?? message.message,
      'lastMessageTime': message.timestamp,
      'lastMessageSenderId': message.senderId,
      'lastMessageType': message.messageType,
      if (message.requestId != null) 'lastRequestId': message.requestId,
      if (message.fulfilledItemId != null)
        'lastFulfilledItemId': message.fulfilledItemId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(message.toMap());
  }

  Future<void> sendRequestReferenceMessage({
    required String receiverId,
    required String requestId,
    required String requestItemName,
    required String fulfilledItemId,
    String text = 'I have this',
  }) async {
    final String currentUserId = getCurrentUser()!.uid;
    final String? currentUserEmail = getCurrentUser()!.email;
    final Timestamp timestamp = Timestamp.now();

    final message = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail ?? '',
      receiverId: receiverId,
      message: text,
      messageType: ChatMessageType.requestReference,
      timestamp: timestamp,
      isRead: false,
      isAutomated: true,
      requestId: requestId,
      requestItemName: requestItemName,
      fulfilledItemId: fulfilledItemId,
    );

    await _sendMessageRecord(message);
  }

  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String senderId, String receiverId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != senderId) return;

    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    final unreadSnapshot = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('senderId', isEqualTo: receiverId)
        .where('receiverId', isEqualTo: senderId)
        .where('isRead', isEqualTo: false)
        .get();

    if (unreadSnapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in unreadSnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Get unread message count
  Future<int> getUnreadCount(String currentUserId, String otherUserId) async {
    List<String> ids = [currentUserId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    final unreadMessages = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    return unreadMessages.docs.length;
  }

  // Delete message
  Future<void> deleteMessage(
    String messageId,
    String userId,
    String otherUserId,
  ) async {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // Search messages
  Future<List<QueryDocumentSnapshot>> searchMessages(
    String userId,
    String otherUserId,
    String searchTerm,
  ) async {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    final messages = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .get();

    return messages.docs.where((doc) {
      final message = doc.data()['message'] as String;
      return message.toLowerCase().contains(searchTerm.toLowerCase());
    }).toList();
  }

  // Typing indicator
  Future<void> setTypingStatus(
    String userId,
    String otherUserId,
    bool isTyping,
  ) async {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'typing_${userId}': isTyping,
    }, SetOptions(merge: true));
  }

  Stream<bool> getTypingStatus(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    return _firestore.collection('chat_rooms').doc(chatRoomId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return false;
      return snapshot.data()?['typing_$otherUserId'] ?? false;
    });
  }
}
