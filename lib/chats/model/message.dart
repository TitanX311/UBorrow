import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageType {
  static const String legacyText = 'legacy_text';
  static const String iHaveThis = 'i_have_this';
  static const String isAvailable = 'is_available';
  static const String whenCollect = 'when_collect';
  static const String whereMeet = 'where_meet';
  static const String meetingTime = 'meeting_time';
  static const String thanks = 'thanks';
  static const String shareContact = 'share_contact';
  static const String requestReference = 'request_reference';
  static const String borrowRequest = 'borrow_request';

  static const Set<String> allowed = {
    iHaveThis,
    isAvailable,
    whenCollect,
    whereMeet,
    meetingTime,
    thanks,
    shareContact,
    requestReference,
    borrowRequest,
  };
}

class Message {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final String messageType;
  final Timestamp timestamp;
  final bool isRead;
  final bool isAutomated;
  final String? requestId;
  final String? requestItemName;
  final String? fulfilledItemId;
  final Timestamp? meetingAt;
  final String? meetingNote;
  final String? sharedEmail;
  final String? sharedPhone;

  //<editor-fold desc="Data Methods">
  const Message({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    required this.messageType,
    required this.timestamp,
    this.isRead = false,
    this.isAutomated = false,
    this.requestId,
    this.requestItemName,
    this.fulfilledItemId,
    this.meetingAt,
    this.meetingNote,
    this.sharedEmail,
    this.sharedPhone,
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
          messageType == other.messageType &&
          timestamp == other.timestamp &&
          isRead == other.isRead &&
          isAutomated == other.isAutomated &&
          requestId == other.requestId &&
          requestItemName == other.requestItemName &&
          fulfilledItemId == other.fulfilledItemId &&
          meetingAt == other.meetingAt &&
          meetingNote == other.meetingNote &&
          sharedEmail == other.sharedEmail &&
          sharedPhone == other.sharedPhone);

  @override
  int get hashCode =>
      senderId.hashCode ^
      senderEmail.hashCode ^
      receiverId.hashCode ^
      message.hashCode ^
      messageType.hashCode ^
      timestamp.hashCode ^
      isRead.hashCode ^
      isAutomated.hashCode ^
      requestId.hashCode ^
      requestItemName.hashCode ^
      fulfilledItemId.hashCode ^
      meetingAt.hashCode ^
      meetingNote.hashCode ^
      sharedEmail.hashCode ^
      sharedPhone.hashCode;

  @override
  String toString() {
    return 'Message{' +
        ' senderId: $senderId,' +
        ' senderEmail: $senderEmail,' +
        ' receiverId: $receiverId,' +
        ' message: $message,' +
        ' messageType: $messageType,' +
        ' timestamp: $timestamp,' +
        ' isRead: $isRead,' +
        ' isAutomated: $isAutomated,' +
        ' requestId: $requestId,' +
        ' requestItemName: $requestItemName,' +
        ' fulfilledItemId: $fulfilledItemId,' +
        ' meetingAt: $meetingAt,' +
        ' meetingNote: $meetingNote,' +
        ' sharedEmail: $sharedEmail,' +
        ' sharedPhone: $sharedPhone,' +
        '}';
  }

  Message copyWith({
    String? senderId,
    String? senderEmail,
    String? receiverId,
    String? message,
    String? messageType,
    Timestamp? timestamp,
    bool? isRead,
    bool? isAutomated,
    String? requestId,
    String? requestItemName,
    String? fulfilledItemId,
    Timestamp? meetingAt,
    String? meetingNote,
    String? sharedEmail,
    String? sharedPhone,
  }) {
    return Message(
      senderId: senderId ?? this.senderId,
      senderEmail: senderEmail ?? this.senderEmail,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isAutomated: isAutomated ?? this.isAutomated,
      requestId: requestId ?? this.requestId,
      requestItemName: requestItemName ?? this.requestItemName,
      fulfilledItemId: fulfilledItemId ?? this.fulfilledItemId,
      meetingAt: meetingAt ?? this.meetingAt,
      meetingNote: meetingNote ?? this.meetingNote,
      sharedEmail: sharedEmail ?? this.sharedEmail,
      sharedPhone: sharedPhone ?? this.sharedPhone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': this.senderId,
      'senderEmail': this.senderEmail,
      'receiverId': this.receiverId,
      'message': this.message,
      'messageType': this.messageType,
      'timestamp': this.timestamp,
      'isRead': this.isRead,
      'isAutomated': this.isAutomated,
      'requestId': this.requestId,
      'requestItemName': this.requestItemName,
      'fulfilledItemId': this.fulfilledItemId,
      'meetingAt': this.meetingAt,
      'meetingNote': this.meetingNote,
      'sharedEmail': this.sharedEmail,
      'sharedPhone': this.sharedPhone,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderId: map['senderId'] as String,
      senderEmail: map['senderEmail'] as String,
      receiverId: map['receiverId'] as String,
      message: map['message'] as String,
      messageType: map['messageType'] as String? ?? ChatMessageType.legacyText,
      timestamp: map['timestamp'] as Timestamp,
      isRead: map['isRead'] as bool? ?? false,
      isAutomated: map['isAutomated'] as bool? ?? false,
      requestId: map['requestId'] as String?,
      requestItemName: map['requestItemName'] as String?,
      fulfilledItemId: map['fulfilledItemId'] as String?,
      meetingAt: map['meetingAt'] as Timestamp?,
      meetingNote: map['meetingNote'] as String?,
      sharedEmail: map['sharedEmail'] as String?,
      sharedPhone: map['sharedPhone'] as String?,
    );
  }

  //</editor-fold>
}
