import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uborrow/auth/model/user_model.dart';

part 'auth_remote_repository.g.dart';

@riverpod
AuthRemoteRepository authRemoteRepository(Ref ref) {
  return AuthRemoteRepository();
}

class AuthRemoteRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleAuth = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      UserModel user = UserModel(id: userCredential.user!.uid.toString());
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<UserModel> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      UserModel user = UserModel(id: userCredential.user!.uid.toString(), email: email);
      _firestore.collection("users").doc(user.id).set(user.toJson());

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> sendDetailsRegister(
    String id,
    String name,
    String hostel,
    String phoneNumber,
  ) async {
    await _firestore.collection("users").doc(id).set({
      'name': name,
      'hostel': hostel,
      'phoneNumber': phoneNumber,
    }, SetOptions(merge: true));
  }

  Future<void> sendDetailsGoogle(
    String id,
    String hostel,
    String phoneNumber,
  ) async {
    await _firestore.collection("users").doc(id).set({
      'hostel': hostel,
      'phoneNumber': phoneNumber,
    }, SetOptions(merge: true));
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      await _googleAuth.initialize();
      final GoogleSignInAccount? googleUser = await _googleAuth.authenticate();
      if (googleUser == null) {
        throw Exception("Something went wrong");
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);

      final user = userCred.user;
      UserModel userModel = UserModel(
        id: user!.uid.toString(),
        name: user.displayName,
        photoURL: user.photoURL,
        email: user.email,
      );
      _firestore.collection("users").doc(userModel.id).set(userModel.toJson());
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleAuth.signOut();
  }
}
