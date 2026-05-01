import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zola/data/repositories/auth_backend_repository.dart';
import 'package:zola/data/repositories/auth_session_repository.dart';
import 'package:zola/data/services/api_client.dart';
import 'package:zola/data/services/auth_remote_service.dart';
import 'package:zola/data/services/secure_storage_service.dart';
import 'package:zola/di/providers/repositories_providers.dart';
import 'package:zola/domain/models/auth_session.dart';
import 'package:zola/domain/models/auth_user.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_view_model.dart';

void main() {
  group('AuthStatusNotifier', () {
    test('refreshAuthStatus sets authenticated when token exists', () async {
      final fakeRepository = _FakeAuthSessionRepository(
        validToken: 'token-123',
      );
      final fakeBackendRepository = _FakeAuthBackendRepository(
        sessionResult: _defaultSessionResult(),
      );
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
          authBackendRepositoryProvider.overrideWithValue(fakeBackendRepository),
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
      final fakeBackendRepository = _FakeAuthBackendRepository(
        sessionResult: _defaultSessionResult(),
      );
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
          authBackendRepositoryProvider.overrideWithValue(fakeBackendRepository),
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
      final fakeBackendRepository = _FakeAuthBackendRepository(
        sessionResult: _defaultSessionResult(),
      );
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
          authBackendRepositoryProvider.overrideWithValue(fakeBackendRepository),
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
      final fakeBackendRepository = _FakeAuthBackendRepository(
        sessionResult: _defaultSessionResult(),
      );
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
          authBackendRepositoryProvider.overrideWithValue(fakeBackendRepository),
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
      final fakeBackendRepository = _FakeAuthBackendRepository(
        sessionResult: _defaultSessionResult(),
      );
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
          authBackendRepositoryProvider.overrideWithValue(fakeBackendRepository),
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

    test('ensureSessionActiveForCriticalAction logs out when backend returns 401', () async {
      final fakeRepository = _FakeAuthSessionRepository(validToken: 'token-123');
      final fakeBackendRepository = _FakeAuthBackendRepository(
        sessionError: const AuthBackendHttpException(
          statusCode: 401,
          message: 'Unauthorized',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
          authBackendRepositoryProvider.overrideWithValue(fakeBackendRepository),
        ],
      );
      addTearDown(container.dispose);

      final isActive = await container
          .read(authStatusNotifierProvider.notifier)
          .ensureSessionActiveForCriticalAction();

      expect(isActive, isFalse);
      expect(fakeRepository.clearCalled, isTrue);
      expect(container.read(authStatusNotifierProvider), AuthStatus.unauthenticated);
    });

    test('markAuthenticated sets banned status for banned user', () async {
      final fakeRepository = _FakeAuthSessionRepository(validToken: null);
      final fakeBackendRepository = _FakeAuthBackendRepository(
        sessionResult: AuthBackendSessionResult(
          statusCode: 200,
          session: const AuthBackendSession(
            id: 's_1',
            expiresAt: '2026-05-01T00:00:00.000Z',
            token: 'token-123',
          ),
          user: const AuthUser(
            id: 'u_1',
            name: 'Banned User',
            email: 'banned@zola.app',
            emailVerified: true,
            banned: true,
          ),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
          authBackendRepositoryProvider.overrideWithValue(fakeBackendRepository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authStatusNotifierProvider.notifier)
          .markAuthenticated(
            'new-token',
            user: const AuthUser(
              id: 'u_1',
              name: 'Banned User',
              email: 'banned@zola.app',
              emailVerified: true,
              banned: true,
            ),
          );

      expect(container.read(authStatusNotifierProvider), AuthStatus.banned);
    });

    test('ensureSessionActiveForCriticalAction sets banned status when server user is banned', () async {
      final fakeRepository = _FakeAuthSessionRepository(validToken: 'token-123');
      final fakeBackendRepository = _FakeAuthBackendRepository(
        sessionResult: AuthBackendSessionResult(
          statusCode: 200,
          session: const AuthBackendSession(
            id: 's_1',
            expiresAt: '2026-05-01T00:00:00.000Z',
            token: 'token-123',
          ),
          user: const AuthUser(
            id: 'u_2',
            name: 'Banned By Server',
            email: 'server-banned@zola.app',
            emailVerified: true,
            banned: true,
          ),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
          authBackendRepositoryProvider.overrideWithValue(fakeBackendRepository),
        ],
      );
      addTearDown(container.dispose);

      final isActive = await container
          .read(authStatusNotifierProvider.notifier)
          .ensureSessionActiveForCriticalAction();

      expect(isActive, isFalse);
      expect(container.read(authStatusNotifierProvider), AuthStatus.banned);
    });

    test('ensureSessionActiveForLifecycle keeps banned state on non-401 error', () async {
      final fakeRepository = _FakeAuthSessionRepository(validToken: null);
      final fakeBackendRepository = _FakeAuthBackendRepository(
        sessionError: const AuthBackendHttpException(
          statusCode: 500,
          message: 'Internal server error',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
          authBackendRepositoryProvider.overrideWithValue(fakeBackendRepository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authStatusNotifierProvider.notifier)
          .markAuthenticated(
            'new-token',
            user: const AuthUser(
              id: 'u_banned',
              name: 'Banned User',
              email: 'banned@zola.app',
              emailVerified: true,
              banned: true,
            ),
          );

      final isActive = await container
          .read(authStatusNotifierProvider.notifier)
          .ensureSessionActiveForLifecycle();

      expect(isActive, isFalse);
      expect(container.read(authStatusNotifierProvider), AuthStatus.banned);
    });
  });
}

AuthBackendSessionResult _defaultSessionResult() {
  return const AuthBackendSessionResult(
    statusCode: 200,
    session: AuthBackendSession(
      id: 's_1',
      expiresAt: '2026-05-01T00:00:00.000Z',
      token: 'token-123',
    ),
  );
}

class _FakeAuthSessionRepository extends AuthSessionRepository {
  _FakeAuthSessionRepository({this.validToken})
    : super(secureStorageService: _FakeSecureStorageService());

  String? validToken;
  DateTime? expiresAt;
  String? savedToken;
  bool clearCalled = false;
  bool clearUserCalled = false;
  AuthUser? savedUser;

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
  Future<void> saveUser(AuthUser user) async {
    savedUser = user;
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

class _FakeAuthBackendRepository extends AuthBackendRepository {
  _FakeAuthBackendRepository({this.sessionResult, this.sessionError})
    : super(authRemoteService: _NoopAuthRemoteService());

  final AuthBackendSessionResult? sessionResult;
  final Object? sessionError;

  @override
  Future<AuthBackendSessionResult> getSession({required String bearerToken}) async {
    if (sessionError != null) {
      throw sessionError!;
    }
    if (sessionResult != null) {
      return sessionResult!;
    }
    throw Exception('Missing fake session result');
  }
}

class _NoopAuthRemoteService extends AuthRemoteService {
  _NoopAuthRemoteService()
    : super(
        apiClient: ApiClient(
          authSessionRepository: _FakeAuthSessionRepository(),
        ),
      );

  @override
  Future<http.Response> signInWithGoogle({
    required String idToken,
    required String accessToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> getSession({required String bearerToken}) {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> signOut({required String bearerToken}) {
    throw UnimplementedError();
  }
}
