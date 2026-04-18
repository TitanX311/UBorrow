// import 'package:cloud_firestore/cloud_firestore.dart';

// class RequestModel {
//   final String id;
//   final String itemId;
//   final String itemName;
//   final String ownerId;
//   final String ownerEmail;
//   final String requesterId;
//   final String requesterEmail;
//   final String period;
//   final String? message;
//   final String status; // Pending, Accepted, Declined, Completed
//   final DateTime? createdAt;
//   final DateTime? updatedAt;

//   RequestModel({
//     required this.id,
//     required this.itemId,
//     required this.itemName,
//     required this.ownerId,
//     required this.ownerEmail,
//     required this.requesterId,
//     required this.requesterEmail,
//     required this.period,
//     this.message,
//     this.status = 'Pending',
//     this.createdAt,
//     this.updatedAt,
//   });

//   // Convert Firestore document to RequestModel
//   factory RequestModel.fromMap(
//     Map<String, dynamic> map, {
//     required String documentId,
//   }) {
//     return RequestModel(
//       id: documentId,
//       itemId: map['itemId'] ?? '',
//       itemName: map['itemName'] ?? '',
//       ownerId: map['ownerId'] ?? '',
//       ownerEmail: map['ownerEmail'] ?? '',
//       requesterId: map['requesterId'] ?? '',
//       requesterEmail: map['requesterEmail'] ?? '',
//       period: map['period'] ?? '',
//       message: map['message'],
//       status: map['status'] ?? 'Pending',
//       createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
//       updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
//     );
//   }

//   // Convert RequestModel to Map for Firestore
//   Map<String, dynamic> toMap() {
//     return {
//       'itemId': itemId,
//       'itemName': itemName,
//       'ownerId': ownerId,
//       'ownerEmail': ownerEmail,
//       'requesterId': requesterId,
//       'requesterEmail': requesterEmail,
//       'period': period,
//       'message': message,
//       'status': status,
//       'createdAt': createdAt,
//       'updatedAt': updatedAt,
//     };
//   }

//   // Create a copy with updated fields
//   RequestModel copyWith({
//     String? id,
//     String? itemId,
//     String? itemName,
//     String? ownerId,
//     String? ownerEmail,
//     String? requesterId,
//     String? requesterEmail,
//     String? period,
//     String? message,
//     String? status,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//   }) {
//     return RequestModel(
//       id: id ?? this.id,
//       itemId: itemId ?? this.itemId,
//       itemName: itemName ?? this.itemName,
//       ownerId: ownerId ?? this.ownerId,
//       ownerEmail: ownerEmail ?? this.ownerEmail,
//       requesterId: requesterId ?? this.requesterId,
//       requesterEmail: requesterEmail ?? this.requesterEmail,
//       period: period ?? this.period,
//       message: message ?? this.message,
//       status: status ?? this.status,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//     );
//   }
// }
