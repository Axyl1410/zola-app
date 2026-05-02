import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/di/providers/repositories_providers.dart';

import 'login_view_model.dart';

final loginNotifierProvider = NotifierProvider<LoginNotifier, LoginState>(
  LoginNotifier.new,
);

final lastLoginMethodProvider = FutureProvider<String?>((ref) {
  return ref.watch(authSessionRepositoryProvider).getLastLoginMethod();
});
