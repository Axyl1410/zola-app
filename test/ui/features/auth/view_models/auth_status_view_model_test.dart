import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zola/data/repositories/auth_session_repository.dart';
import 'package:zola/data/services/secure_storage_service.dart';
import 'package:zola/di/providers/repositories_providers.dart';
import 'package:zola/domain/models/auth_session.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_view_model.dart';

void main() {
  group('AuthStatusNotifier', () {
    test('refreshAuthStatus sets authenticated when token exists', () async {
      final fakeRepository = _FakeAuthSessionRepository(
        validToken: 'token-123',
      );
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authStatusNotifierProvider.notifier)
          .refreshAuthStatus();

      expect(
        container.read(authStatusNotifierProvider),
        AuthStatus.authenticated,
      );
    });

    test('refreshAuthStatus sets unauthenticated when token missing', () async {
      final fakeRepository = _FakeAuthSessionRepository(validToken: null);
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authStatusNotifierProvider.notifier)
          .refreshAuthStatus();

      expect(
        container.read(authStatusNotifierProvider),
        AuthStatus.unauthenticated,
      );
      expect(fakeRepository.clearCalled, isTrue);
    });

    test('markAuthenticated saves token and sets authenticated', () async {
      final fakeRepository = _FakeAuthSessionRepository(validToken: null);
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authStatusNotifierProvider.notifier)
          .markAuthenticated('new-token');

      expect(fakeRepository.savedToken, 'new-token');
      expect(
        container.read(authStatusNotifierProvider),
        AuthStatus.authenticated,
      );
    });

    test('markAuthenticated clears cached user when user is null', () async {
      final fakeRepository = _FakeAuthSessionRepository(validToken: null);
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authStatusNotifierProvider.notifier)
          .markAuthenticated('new-token');

      expect(fakeRepository.clearUserCalled, isTrue);
    });

    test('logout clears session and sets unauthenticated', () async {
      final fakeRepository = _FakeAuthSessionRepository(
        validToken: 'token-123',
      );
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authStatusNotifierProvider.notifier).logout();

      expect(fakeRepository.clearCalled, isTrue);
      expect(
        container.read(authStatusNotifierProvider),
        AuthStatus.unauthenticated,
      );
    });
  });
}

class _FakeAuthSessionRepository extends AuthSessionRepository {
  _FakeAuthSessionRepository({this.validToken})
    : super(secureStorageService: _FakeSecureStorageService());

  String? validToken;
  DateTime? expiresAt;
  String? savedToken;
  bool clearCalled = false;
  bool clearUserCalled = false;

  @override
  Future<String?> getValidToken() async {
    return validToken;
  }

  @override
  Future<void> clearSession() async {
    clearCalled = true;
    validToken = null;
    expiresAt = null;
  }

  @override
  Future<void> clearUser() async {
    clearUserCalled = true;
  }

  @override
  Future<AuthSession?> getSession() async {
    final token = validToken;
    final expiry = expiresAt;
    if (token == null || expiry == null) {
      return null;
    }
    return AuthSession(
      token: token,
      receivedAt: DateTime.now().toUtc(),
      expiresAt: expiry,
    );
  }

  @override
  Future<AuthSession> saveToken(
    String token, {
    Duration ttl = SecureStorageService.defaultSessionTtl,
  }) async {
    savedToken = token;
    validToken = token;
    final receivedAt = DateTime.now().toUtc();
    expiresAt = receivedAt.add(ttl);
    return AuthSession(
      token: token,
      receivedAt: receivedAt,
      expiresAt: expiresAt!,
    );
  }
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService() : super(storage: const FlutterSecureStorage());
}
