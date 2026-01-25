import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;

  //<editor-fold desc="Data Methods">
  const Message({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          runtimeType == other.runtimeType &&
          senderId == other.senderId &&
          senderEmail == other.senderEmail &&
          receiverId == other.receiverId &&
          message == other.message &&
          timestamp == other.timestamp);

  @override
  int get hashCode =>
      senderId.hashCode ^
      senderEmail.hashCode ^
      receiverId.hashCode ^
      message.hashCode ^
      timestamp.hashCode;

  @override
  String toString() {
    return 'Message{' +
        ' senderId: $senderId,' +
        ' senderEmail: $senderEmail,' +
        ' receiverId: $receiverId,' +
        ' message: $message,' +
        ' timestamp: $timestamp,' +
        '}';
  }

  Message copyWith({
    String? senderId,
    String? senderEmail,
    String? receiverId,
    String? message,
    Timestamp? timestamp,
  }) {
    return Message(
      senderId: senderId ?? this.senderId,
      senderEmail: senderEmail ?? this.senderEmail,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': this.senderId,
      'senderEmail': this.senderEmail,
      'receiverId': this.receiverId,
      'message': this.message,
      'timestamp': this.timestamp,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderId: map['senderId'] as String,
      senderEmail: map['senderEmail'] as String,
      receiverId: map['receiverId'] as String,
      message: map['message'] as String,
      timestamp: map['timestamp'] as Timestamp,
    );
  }

  //</editor-fold>
}
