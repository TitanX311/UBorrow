import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uborrow/auth/model/user_model.dart';

part 'remote_repository.g.dart';

@Riverpod(keepAlive: true)
class RemoteRepository extends _$RemoteRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void build() {
    // no state to initialize
  }

  /// 🔹 Fetch current logged-in user from Firestore
  Future<UserModel> getCurrentUser() async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      throw Exception("User not authenticated");
    }

    final doc = await _firestore.collection("users").doc(uid).get();

    if (!doc.exists) {
      throw Exception("User document not found");
    }

    return UserModel.fromDocument(doc);
  }

  /// 🔹 Update user details (Register flow)
  Future<void> updateUserDetails({
    required String name,
    required String hostel,
    required String phoneNumber,
  }) async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      throw Exception("User not authenticated");
    }

    await _firestore.collection("users").doc(uid).set({
      'name': name,
      'hostel': hostel,
      'phoneNumber': phoneNumber,
    }, SetOptions(merge: true));
  }

  /// 🔹 Update user details (Google flow)
  Future<void> updateGoogleDetails({
    required String hostel,
    required String phoneNumber,
  }) async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      throw Exception("User not authenticated");
    }

    await _firestore.collection("users").doc(uid).set({
      'hostel': hostel,
      'phoneNumber': phoneNumber,
    }, SetOptions(merge: true));
  }
}
