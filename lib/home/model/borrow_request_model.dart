import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uborrow/utils/constants.dart';

class BorrowRequestModel {
  final String id;
  final String itemId;
  final String itemName;
  final String itemImage;
  final String ownerId;
  final String ownerEmail;
  final String requesterId;
  final String requesterEmail;
  final String period;
  final String? message;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BorrowRequestModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.itemImage,
    required this.ownerId,
    required this.ownerEmail,
    required this.requesterId,
    required this.requesterEmail,
    required this.period,
    this.message,
    this.status = BorrowRequestStatus.pending,
    this.createdAt,
    this.updatedAt,
  });

  factory BorrowRequestModel.fromMap(
    Map<String, dynamic> map, {
    required String documentId,
  }) {
    return BorrowRequestModel(
      id: documentId,
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      itemImage: map['itemImage'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerEmail: map['ownerEmail'] ?? '',
      requesterId: map['requesterId'] ?? '',
      requesterEmail: map['requesterEmail'] ?? '',
      period: map['period'] ?? '',
      message: map['message'],
      status: map['status'] ?? BorrowRequestStatus.pending,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'itemImage': itemImage,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'requesterId': requesterId,
      'requesterEmail': requesterEmail,
      'period': period,
      'message': message,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

