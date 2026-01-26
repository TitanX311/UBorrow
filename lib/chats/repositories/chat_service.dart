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

    return _firestore.collection('users').snapshots().asyncMap((
      snapshot,
    ) async {
      List<Map<String, dynamic>> usersWithMessages = [];

      for (var doc in snapshot.docs) {
        if (doc.id == currentUserId) continue;

        final user = doc.data();
        user['uid'] = doc.id;

        // Get last message for this chat
        List<String> ids = [currentUserId, doc.id];
        ids.sort();
        String chatRoomId = ids.join('_');

        final lastMessageSnapshot = await _firestore
            .collection('chat_rooms')
            .doc(chatRoomId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (lastMessageSnapshot.docs.isNotEmpty) {
          final lastMessage = lastMessageSnapshot.docs.first.data();
          user['lastMessage'] = lastMessage['message'];
          user['lastMessageTime'] = lastMessage['timestamp'];
          user['unreadCount'] = await getUnreadCount(currentUserId, doc.id);
        } else {
          user['lastMessage'] = null;
          user['lastMessageTime'] = null;
          user['unreadCount'] = 0;
        }

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
    final String currentUserId = getCurrentUser()!.uid;
    final String? currentUserEmail = getCurrentUser()!.email;
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail!,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
    );

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    // Add message to Firestore
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());

    // Update chat room metadata
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'participants': ids,
      'lastMessage': message,
      'lastMessageTime': timestamp,
      'lastMessageSenderId': currentUserId,
    }, SetOptions(merge: true));
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
    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    final messages = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('senderId', isEqualTo: receiverId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in messages.docs) {
      await doc.reference.update({'isRead': true});
    }
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
