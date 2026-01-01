import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uborrow/auth/model/user_model.dart';
import '../repository/auth_remote_repository.dart';

part 'auth_view_model.g.dart';

@riverpod
class AuthViewModel extends _$AuthViewModel {
  late final AuthRemoteRepository _authRemoteRepository;

  @override
  AsyncValue<UserModel>? build() {
    _authRemoteRepository = ref.watch(authRemoteRepositoryProvider);
    return state;
  }

  Future<void> signinWithGoogle() async {
    state = const AsyncLoading();
    try {
      final user = await _authRemoteRepository.signInWithGoogle();
      print(user);
      state = AsyncData(user);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> sendDetailsGoogle(String hostel, String phoneNumber) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    try {
      await _authRemoteRepository.sendDetailsGoogle(uid, hostel, phoneNumber);
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  Future<void> sendDetailsRegister(
    String name,
    String hostel,
    String phoneNumber,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception("User not authenticated");
    }
    await _authRemoteRepository.sendDetailsRegister(
      uid,
      name,
      hostel,
      phoneNumber,
    );
  }

  Future<UserModel?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    state = const AsyncLoading();
    try {
      final user = await _authRemoteRepository.registerWithEmailAndPassword(
        email,
        password,
      );
      print(user);
      state = AsyncData(user);
      return user;
    } catch (e, s) {
      state = AsyncError(e, s);
      return null;
    }
  }

  Future<void> loginWithEmailAndPassword(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _authRemoteRepository.signInWithEmailAndPassword(
        email,
        password,
      );
      print(user);
      state = AsyncData(user);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> signOut() async {
    await _authRemoteRepository.signOut();
    state = null;
  }
}
