import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;
  final bool isRead;
  final bool isAutomated;
  final String? messageType;
  final String? requestId;
  final String? requestItemName;
  final String? fulfilledItemId;

  //<editor-fold desc="Data Methods">
  const Message({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.isAutomated = false,
    this.messageType,
    this.requestId,
    this.requestItemName,
    this.fulfilledItemId,
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
          timestamp == other.timestamp &&
          isRead == other.isRead &&
          isAutomated == other.isAutomated &&
          messageType == other.messageType &&
          requestId == other.requestId &&
          requestItemName == other.requestItemName &&
          fulfilledItemId == other.fulfilledItemId);

  @override
  int get hashCode =>
      senderId.hashCode ^
      senderEmail.hashCode ^
      receiverId.hashCode ^
      message.hashCode ^
      timestamp.hashCode ^
      isRead.hashCode ^
      isAutomated.hashCode ^
      messageType.hashCode ^
      requestId.hashCode ^
      requestItemName.hashCode ^
      fulfilledItemId.hashCode;

  @override
  String toString() {
    return 'Message{' +
        ' senderId: $senderId,' +
        ' senderEmail: $senderEmail,' +
        ' receiverId: $receiverId,' +
        ' message: $message,' +
        ' timestamp: $timestamp,' +
        ' isRead: $isRead,' +
        ' isAutomated: $isAutomated,' +
        ' messageType: $messageType,' +
        ' requestId: $requestId,' +
        ' requestItemName: $requestItemName,' +
        ' fulfilledItemId: $fulfilledItemId,' +
        '}';
  }

  Message copyWith({
    String? senderId,
    String? senderEmail,
    String? receiverId,
    String? message,
    Timestamp? timestamp,
    bool? isRead,
    bool? isAutomated,
    String? messageType,
    String? requestId,
    String? requestItemName,
    String? fulfilledItemId,
  }) {
    return Message(
      senderId: senderId ?? this.senderId,
      senderEmail: senderEmail ?? this.senderEmail,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isAutomated: isAutomated ?? this.isAutomated,
      messageType: messageType ?? this.messageType,
      requestId: requestId ?? this.requestId,
      requestItemName: requestItemName ?? this.requestItemName,
      fulfilledItemId: fulfilledItemId ?? this.fulfilledItemId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': this.senderId,
      'senderEmail': this.senderEmail,
      'receiverId': this.receiverId,
      'message': this.message,
      'timestamp': this.timestamp,
      'isRead': this.isRead,
      'isAutomated': this.isAutomated,
      'messageType': this.messageType,
      'requestId': this.requestId,
      'requestItemName': this.requestItemName,
      'fulfilledItemId': this.fulfilledItemId,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderId: map['senderId'] as String,
      senderEmail: map['senderEmail'] as String,
      receiverId: map['receiverId'] as String,
      message: map['message'] as String,
      timestamp: map['timestamp'] as Timestamp,
      isRead: map['isRead'] as bool? ?? false,
      isAutomated: map['isAutomated'] as bool? ?? false,
      messageType: map['messageType'] as String?,
      requestId: map['requestId'] as String?,
      requestItemName: map['requestItemName'] as String?,
      fulfilledItemId: map['fulfilledItemId'] as String?,
    );
  }

  //</editor-fold>
}
