import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/data/repositories/auth_backend_repository.dart';
import 'package:zola/data/repositories/auth_session_repository.dart';
import 'package:zola/data/repositories/google_auth_repository.dart';
import 'package:zola/data/repositories/showcase_theme_repository.dart';
import 'package:zola/data/repositories/todo_repository.dart';
import 'package:zola/data/services/api_client.dart';
import 'package:zola/data/services/auth_remote_service.dart';
import 'package:zola/data/services/todo_remote_service.dart';

import 'services_providers.dart';

final showcaseThemeRepositoryProvider = Provider<ShowcaseThemeRepository>((
  ref,
) {
  return ShowcaseThemeRepository(
    colorSchemeService: ref.watch(colorSchemeServiceProvider),
  );
});

final authSessionRepositoryProvider = Provider<AuthSessionRepository>((ref) {
  return AuthSessionRepository(
    secureStorageService: ref.watch(secureStorageServiceProvider),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    authTokenProvider: ref.watch(authSessionRepositoryProvider),
  );
});

final todoRemoteServiceProvider = Provider<TodoRemoteService>((ref) {
  return TodoRemoteService(apiClient: ref.watch(apiClientProvider));
});

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return TodoRepository(
    todoRemoteService: ref.watch(todoRemoteServiceProvider),
  );
});

final authRemoteServiceProvider = Provider<AuthRemoteService>((ref) {
  return AuthRemoteService(apiClient: ref.watch(apiClientProvider));
});

final googleAuthRepositoryProvider = Provider<GoogleAuthRepository>((ref) {
  return GoogleAuthRepository(
    googleSignInService: ref.watch(googleSignInServiceProvider),
  );
});

final authBackendRepositoryProvider = Provider<AuthBackendRepository>((ref) {
  return AuthBackendRepository(
    authRemoteService: ref.watch(authRemoteServiceProvider),
  );
});
