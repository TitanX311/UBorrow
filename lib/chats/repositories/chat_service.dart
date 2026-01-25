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
  //get instance of firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //getcurrentuser
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  //getuser stream
  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        //go through each individual user
        final user = doc.data();
        return user;
      }).toList();
    });
  }

  //send message

  Future<void> sendMessage(String receiverId, String message) async {
    //get current user info
    final String currentUserId = getCurrentUser()!.uid;
    final String? currentUserEmail = getCurrentUser()!.email;
    final Timestamp timestamp = Timestamp.now();

    //create a new message
    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail!,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
    );

    // construct chat room Id for the two users (sorted to ensure uniqueness)
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    //add new message to database
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());
  }

  //get mssage

  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    //construct a chatroom Id for the two users
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
}
