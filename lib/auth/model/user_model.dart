import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String? name;
  final String? email;
  final String? photoURL;
  final String? hostel;
  final String? phoneNumber;

  UserModel({
    required this.id,
    this.name,
    this.email,
    this.photoURL,
    this.hostel,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoURL': photoURL,
      'hostel': hostel,
      'phoneNumber': phoneNumber,
    };
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] as String?,
      email: data['email'] as String?,
      photoURL: data['photoURL'] as String?,
      hostel: data['hostel'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
    );
  }
}
