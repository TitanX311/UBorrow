import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String? id;
  final String name;
  final String description;
  final String hostel;
  final String category;
  final String image;
  final String ownerId;
  final String ownerEmail;
  final bool available;
  final DateTime? createdAt;

  ItemModel({
    this.id,
    required this.name,
    required this.description,
    required this.hostel,
    required this.category,
    required this.image,
    required this.ownerId,
    required this.ownerEmail,
    this.available = true,
    this.createdAt,
  });

  factory ItemModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ItemModel(
      id: doc.id, // ✅ ALWAYS from Firestore doc ID
      name: data['name'],
      description: data['description'],
      hostel: data['hostel'],
      category: data['category'],
      image: data['image'],
      ownerId: data['ownerId'],
      ownerEmail: data['ownerEmail'],
      available: data['available'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
  // Convert Firestore document to ItemModel
  factory ItemModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return ItemModel(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      hostel: map['hostel'] ?? '',
      category: map['category'] ?? 'Other',
      image: map['image'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerEmail: map['ownerEmail'] ?? '',
      available: map['available'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert ItemModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      // 'id': id,
      'name': name,
      'description': description,
      'hostel': hostel,
      'category': category,
      'image': image,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'available': available,
      'createdAt': createdAt,
    };
  }

  // Create a copy with updated fields
  ItemModel copyWith({
    String? id,
    String? name,
    String? description,
    String? hostel,
    String? category,
    String? image,
    String? ownerId,
    String? ownerEmail,
    bool? available,
    DateTime? createdAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      hostel: hostel ?? this.hostel,
      category: category ?? this.category,
      image: image ?? this.image,
      ownerId: ownerId ?? this.ownerId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      available: available ?? this.available,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
