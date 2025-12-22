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
    return null;
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

  Future<void> registerWithEmailAndPassword(String email, String password) async {
    state = const AsyncLoading();
    try{
      final user = await _authRemoteRepository.registerWithEmailAndPassword(email,password);
      print(user);
      state = AsyncData(user);
    } catch(e,s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> loginWithEmailAndPassword(String email, String password) async {
    state = const AsyncLoading();
    try{
      final user = await _authRemoteRepository.signInWithEmailAndPassword(email,password);
      print(user);
      state = AsyncData(user);
    } catch(e,s) {
      state = AsyncError(e, s);
    }
  }

  void signOut() {
    _authRemoteRepository.signOut();
  }
}