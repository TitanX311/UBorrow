import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uborrow/utils/constants.dart';

class NeedRequestModel {
  final String id;
  final String itemName;
  final String period;
  final String? message;
  final String requesterId;
  final String requesterEmail;
  final String status;
  final String? fulfilledBy;
  final String? fulfilledItemId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? fulfilledAt;

  const NeedRequestModel({
    required this.id,
    required this.itemName,
    required this.period,
    this.message,
    required this.requesterId,
    required this.requesterEmail,
    this.status = NeedRequestStatus.open,
    this.fulfilledBy,
    this.fulfilledItemId,
    this.createdAt,
    this.updatedAt,
    this.fulfilledAt,
  });

  factory NeedRequestModel.fromMap(
    Map<String, dynamic> map, {
    required String documentId,
  }) {
    return NeedRequestModel(
      id: documentId,
      itemName: map['itemName'] ?? '',
      period: map['period'] ?? '',
      message: map['message'],
      requesterId: map['requesterId'] ?? '',
      requesterEmail: map['requesterEmail'] ?? '',
      status: map['status'] ?? NeedRequestStatus.open,
      fulfilledBy: map['fulfilledBy'],
      fulfilledItemId: map['fulfilledItemId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      fulfilledAt: (map['fulfilledAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'period': period,
      'message': message,
      'requesterId': requesterId,
      'requesterEmail': requesterEmail,
      'status': status,
      'fulfilledBy': fulfilledBy,
      'fulfilledItemId': fulfilledItemId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'fulfilledAt': fulfilledAt,
    };
  }
}

