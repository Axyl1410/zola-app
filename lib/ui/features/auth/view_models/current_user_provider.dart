import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/di/providers/repositories_providers.dart';
import 'package:zola/domain/models/auth_user.dart';

final currentUserProvider = FutureProvider<AuthUser?>((ref) {
  return ref.watch(authSessionRepositoryProvider).getUser();
});
