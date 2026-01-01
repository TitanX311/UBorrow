import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uborrow/auth/model/user_model.dart';
import 'package:uborrow/core/repository/remote_repository.dart';

final currentUserProvider = FutureProvider<UserModel>((ref) async {
  return await ref.read(remoteRepositoryProvider.notifier).getCurrentUser();
});
