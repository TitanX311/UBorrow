import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String? name;
  final String? email;
  final String? photoURL;
  final String? hostel;
  final String? phoneNumber;

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

  //<editor-fold desc="Data Methods">
  const UserModel({
    required this.id,
    this.name,
    this.email,
    this.photoURL,
    this.hostel,
    this.phoneNumber,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          photoURL == other.photoURL &&
          hostel == other.hostel &&
          phoneNumber == other.phoneNumber);

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      email.hashCode ^
      photoURL.hashCode ^
      hostel.hashCode ^
      phoneNumber.hashCode;

  @override
  String toString() {
    return 'UserModel{' +
        ' id: $id,' +
        ' name: $name,' +
        ' email: $email,' +
        ' photoURL: $photoURL,' +
        ' hostel: $hostel,' +
        ' phoneNumber: $phoneNumber,' +
        '}';
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoURL,
    String? hostel,
    String? phoneNumber,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      hostel: hostel ?? this.hostel,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'name': this.name,
      'email': this.email,
      'photoURL': this.photoURL,
      'hostel': this.hostel,
      'phoneNumber': this.phoneNumber,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      photoURL: map['photoURL'] as String,
      hostel: map['hostel'] as String,
      phoneNumber: map['phoneNumber'] as String,
    );
  }

  //</editor-fold>
}
