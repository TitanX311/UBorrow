import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  //instance of auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //signin
  Future<UserCredential> signinWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  //signup
  Future<UserCredential> signupWithEmail(String email, String password) async {
    try{
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e){
      throw Exception(e.message);
    }
  }


  //signout
  Future<void> signout() async {
    await _auth.signOut();
    await GoogleSignIn.instance.signOut();
  }

  //google
  Future<User?> signinWithGoogle() async {
    try {
      //instance
      final GoogleSignIn signIn = GoogleSignIn.instance;
      //initialize
      await signIn.initialize();
      //user
      final GoogleSignInAccount? googleUser = await signIn.authenticate();
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
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  //error
}
