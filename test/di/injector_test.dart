import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/data/repositories/auth_backend_repository.dart';
import 'package:zola/data/repositories/auth_session_repository.dart';
import 'package:zola/data/repositories/google_auth_repository.dart';
import 'package:zola/data/repositories/showcase_theme_repository.dart';
import 'package:zola/data/repositories/todo_repository.dart';
import 'package:zola/data/services/api_client.dart';
import 'package:zola/data/services/auth_remote_service.dart';
import 'package:zola/data/services/color_scheme_service.dart';
import 'package:zola/data/services/google_sign_in_service.dart';
import 'package:zola/data/services/secure_storage_service.dart';
import 'package:zola/data/services/todo_remote_service.dart';
import 'package:zola/di/providers.dart';

void main() {
  test('all providers can be resolved', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(colorSchemeServiceProvider),
      isA<ColorSchemeService>(),
    );
    expect(
      container.read(secureStorageServiceProvider),
      isA<SecureStorageService>(),
    );
    expect(
      container.read(showcaseThemeRepositoryProvider),
      isA<ShowcaseThemeRepository>(),
    );
    expect(
      container.read(authSessionRepositoryProvider),
      isA<AuthSessionRepository>(),
    );
    expect(container.read(apiClientProvider), isA<ApiClient>());
    expect(container.read(todoRemoteServiceProvider), isA<TodoRemoteService>());
    expect(container.read(todoRepositoryProvider), isA<TodoRepository>());
    expect(container.read(authRemoteServiceProvider), isA<AuthRemoteService>());
    expect(
      container.read(googleSignInServiceProvider),
      isA<GoogleSignInService>(),
    );
    expect(
      container.read(googleAuthRepositoryProvider),
      isA<GoogleAuthRepository>(),
    );
    expect(
      container.read(authBackendRepositoryProvider),
      isA<AuthBackendRepository>(),
    );
  });

  test('service/repository providers are singletons per container', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      identical(
        container.read(apiClientProvider),
        container.read(apiClientProvider),
      ),
      isTrue,
    );
    expect(
      identical(
        container.read(googleAuthRepositoryProvider),
        container.read(googleAuthRepositoryProvider),
      ),
      isTrue,
    );
    expect(
      identical(
        container.read(authBackendRepositoryProvider),
        container.read(authBackendRepositoryProvider),
      ),
      isTrue,
    );
  });

  test('notifier providers are isolated across containers', () {
    final containerA = ProviderContainer();
    final containerB = ProviderContainer();
    addTearDown(containerA.dispose);
    addTearDown(containerB.dispose);

    final showcaseNotifierA = containerA.read(
      showcaseNotifierProvider.notifier,
    );
    final showcaseNotifierB = containerB.read(
      showcaseNotifierProvider.notifier,
    );
    final schoolNotifierA = containerA.read(schoolNotifierProvider.notifier);
    final schoolNotifierB = containerB.read(schoolNotifierProvider.notifier);
    final messagesNotifierA = containerA.read(
      messagesNotifierProvider.notifier,
    );
    final messagesNotifierB = containerB.read(
      messagesNotifierProvider.notifier,
    );

    expect(identical(showcaseNotifierA, showcaseNotifierB), isFalse);
    expect(identical(schoolNotifierA, schoolNotifierB), isFalse);
    expect(identical(messagesNotifierA, messagesNotifierB), isFalse);
  });
}
