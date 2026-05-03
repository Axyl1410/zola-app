import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zola/data/repositories/auth_backend_repository.dart';
import 'package:zola/data/repositories/auth_session_repository.dart';
import 'package:zola/data/services/api_client.dart';
import 'package:zola/data/services/auth_remote_service.dart';
import 'package:zola/data/services/auth_token_provider.dart';
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
          authBackendRepositoryProvider.overrideWithValue(
            fakeBackendRepository,
          ),
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

    test('build does not trigger refresh automatically', () async {
      final fakeRepository = _FakeAuthSessionRepository(
        validToken: 'token-123',
      );
      final fakeBackendRepository = _FakeAuthBackendRepository(
        sessionResult: _defaultSessionResult(),
      );
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
          authBackendRepositoryProvider.overrideWithValue(
            fakeBackendRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(authStatusNotifierProvider);

      expect(fakeBackendRepository.getSessionCallCount, 0);
      expect(container.read(authStatusNotifierProvider), AuthStatus.checking);
    });

    test('refreshAuthStatus sets unauthenticated when token missing', () async {
      final fakeRepository = _FakeAuthSessionRepository(validToken: null);
      final fakeBackendRepository = _FakeAuthBackendRepository(
        sessionResult: _defaultSessionResult(),
      );
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
          authBackendRepositoryProvider.overrideWithValue(
            fakeBackendRepository,
          ),
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

    test(
      'refreshAuthStatus sets sessionRecoveryRequired when startup is checking and backend returns non-401',
      () async {
        final fakeRepository = _FakeAuthSessionRepository(
          validToken: 'token-123',
        );
        final fakeBackendRepository = _FakeAuthBackendRepository(
          sessionError: const AuthBackendHttpException(
            statusCode: 500,
            message: 'Internal server error',
          ),
        );
        final container = ProviderContainer(
          overrides: [
            authSessionRepositoryProvider.overrideWithValue(fakeRepository),
            authBackendRepositoryProvider.overrideWithValue(
              fakeBackendRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(authStatusNotifierProvider.notifier)
            .refreshAuthStatus();

        expect(
          container.read(authStatusNotifierProvider),
          AuthStatus.sessionRecoveryRequired,
        );
      },
    );

    test('markAuthenticated saves token and sets authenticated', () async {
      final fakeRepository = _FakeAuthSessionRepository(validToken: null);
      final fakeBackendRepository = _FakeAuthBackendRepository(
        sessionResult: _defaultSessionResult(),
      );
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
          authBackendRepositoryProvider.overrideWithValue(
            fakeBackendRepository,
          ),
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
          authBackendRepositoryProvider.overrideWithValue(
            fakeBackendRepository,
          ),
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
          authBackendRepositoryProvider.overrideWithValue(
            fakeBackendRepository,
          ),
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

    test(
      'logout notifies backend before clearing local session by default',
      () async {
        final fakeRepository = _FakeAuthSessionRepository(
          validToken: 'token-123',
        );
        final fakeBackendRepository = _FakeAuthBackendRepository(
          sessionResult: _defaultSessionResult(),
        );
        final container = ProviderContainer(
          overrides: [
            authSessionRepositoryProvider.overrideWithValue(fakeRepository),
            authBackendRepositoryProvider.overrideWithValue(
              fakeBackendRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(authStatusNotifierProvider.notifier).logout();

        expect(fakeBackendRepository.signOutCallCount, 1);
        expect(fakeBackendRepository.lastSignOutToken, 'token-123');
        expect(fakeRepository.clearCalled, isTrue);
        expect(
          container.read(authStatusNotifierProvider),
          AuthStatus.unauthenticated,
        );
      },
    );

    test('logout with notifyBackend false skips backend signOut', () async {
      final fakeRepository = _FakeAuthSessionRepository(
        validToken: 'token-123',
      );
      final fakeBackendRepository = _FakeAuthBackendRepository(
        sessionResult: _defaultSessionResult(),
      );
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
          authBackendRepositoryProvider.overrideWithValue(
            fakeBackendRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authStatusNotifierProvider.notifier)
          .logout(notifyBackend: false);

      expect(fakeBackendRepository.signOutCallCount, 0);
      expect(fakeRepository.clearCalled, isTrue);
      expect(
        container.read(authStatusNotifierProvider),
        AuthStatus.unauthenticated,
      );
    });

    test(
      'ensureSessionActiveForCriticalAction logs out when backend returns 401',
      () async {
        final fakeRepository = _FakeAuthSessionRepository(
          validToken: 'token-123',
        );
        final fakeBackendRepository = _FakeAuthBackendRepository(
          sessionError: const AuthBackendHttpException(
            statusCode: 401,
            message: 'Unauthorized',
          ),
        );
        final container = ProviderContainer(
          overrides: [
            authSessionRepositoryProvider.overrideWithValue(fakeRepository),
            authBackendRepositoryProvider.overrideWithValue(
              fakeBackendRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        final isActive = await container
            .read(authStatusNotifierProvider.notifier)
            .ensureSessionActiveForCriticalAction();

        expect(isActive, isFalse);
        expect(fakeRepository.clearCalled, isTrue);
        expect(
          container.read(authStatusNotifierProvider),
          AuthStatus.unauthenticated,
        );
      },
    );

    test(
      'ensureSessionActiveForCriticalAction keeps authenticated state on non-401 critical failure',
      () async {
        final fakeRepository = _FakeAuthSessionRepository(
          validToken: 'token-123',
        );
        final fakeBackendRepository = _FakeAuthBackendRepository(
          sessionError: const AuthBackendHttpException(
            statusCode: 500,
            message: 'Internal server error',
          ),
        );
        final container = ProviderContainer(
          overrides: [
            authSessionRepositoryProvider.overrideWithValue(fakeRepository),
            authBackendRepositoryProvider.overrideWithValue(
              fakeBackendRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(authStatusNotifierProvider.notifier)
            .markAuthenticated('token-123');

        final isActive = await container
            .read(authStatusNotifierProvider.notifier)
            .ensureSessionActiveForCriticalAction();

        expect(isActive, isFalse);
        expect(fakeRepository.clearCalled, isFalse);
        expect(
          container.read(authStatusNotifierProvider),
          AuthStatus.authenticated,
        );
      },
    );

    test('markAuthenticated sets banned status for banned user', () async {
      final fakeRepository = _FakeAuthSessionRepository(validToken: null);
      final fakeBackendRepository = _FakeAuthBackendRepository(
        sessionResult: AuthBackendSessionResult(
          statusCode: 200,
          session: const AuthBackendSession(
            id: 's_1',
            expiresAt: '2099-05-01T00:00:00.000Z',
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
          authBackendRepositoryProvider.overrideWithValue(
            fakeBackendRepository,
          ),
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

    test(
      'ensureSessionActiveForCriticalAction sets banned status when server user is banned',
      () async {
        final fakeRepository = _FakeAuthSessionRepository(
          validToken: 'token-123',
        );
        final fakeBackendRepository = _FakeAuthBackendRepository(
          sessionResult: AuthBackendSessionResult(
            statusCode: 200,
            session: const AuthBackendSession(
              id: 's_1',
              expiresAt: '2099-05-01T00:00:00.000Z',
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
            authBackendRepositoryProvider.overrideWithValue(
              fakeBackendRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        final isActive = await container
            .read(authStatusNotifierProvider.notifier)
            .ensureSessionActiveForCriticalAction();

        expect(isActive, isFalse);
        expect(container.read(authStatusNotifierProvider), AuthStatus.banned);
      },
    );

    test(
      'ensureSessionActiveForLifecycle keeps banned state on non-401 error',
      () async {
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
            authBackendRepositoryProvider.overrideWithValue(
              fakeBackendRepository,
            ),
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
      },
    );

    test(
      'ensureSessionActiveForLifecycle keeps authenticated on non-401 error',
      () async {
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
            authBackendRepositoryProvider.overrideWithValue(
              fakeBackendRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(authStatusNotifierProvider.notifier)
            .markAuthenticated('new-token');

        final isActive = await container
            .read(authStatusNotifierProvider.notifier)
            .ensureSessionActiveForLifecycle();

        expect(isActive, isTrue);
        expect(
          container.read(authStatusNotifierProvider),
          AuthStatus.authenticated,
        );
      },
    );

    test(
      'validateSessionForCriticalAction returns banned outcome for banned server user',
      () async {
        final fakeRepository = _FakeAuthSessionRepository(
          validToken: 'token-123',
        );
        final fakeBackendRepository = _FakeAuthBackendRepository(
          sessionResult: AuthBackendSessionResult(
            statusCode: 200,
            session: const AuthBackendSession(
              id: 's_1',
              expiresAt: '2099-05-01T00:00:00.000Z',
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
            authBackendRepositoryProvider.overrideWithValue(
              fakeBackendRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        final outcome = await container
            .read(authStatusNotifierProvider.notifier)
            .validateSessionForCriticalAction();

        expect(outcome, SessionValidationOutcome.banned);
        expect(container.read(authStatusNotifierProvider), AuthStatus.banned);
      },
    );

    test(
      'refreshAuthStatus reconciles token and backend expiry into local session',
      () async {
        final fakeRepository = _FakeAuthSessionRepository(
          validToken: 'token-123',
        );
        final fakeBackendRepository = _FakeAuthBackendRepository(
          sessionResult: AuthBackendSessionResult(
            statusCode: 200,
            session: const AuthBackendSession(
              id: 's_9',
              expiresAt: '2099-05-15T10:30:00.000Z',
              token: 'rotated-token',
              createdAt: '2026-05-01T10:30:00.000Z',
            ),
            user: const AuthUser(
              id: 'u_9',
              name: 'User',
              email: 'user@zola.app',
              emailVerified: true,
            ),
          ),
        );
        final container = ProviderContainer(
          overrides: [
            authSessionRepositoryProvider.overrideWithValue(fakeRepository),
            authBackendRepositoryProvider.overrideWithValue(
              fakeBackendRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(authStatusNotifierProvider.notifier)
            .refreshAuthStatus();

        expect(fakeRepository.savedToken, 'rotated-token');
        expect(
          fakeRepository.savedSessionExpiresAt,
          DateTime.parse('2099-05-15T10:30:00.000Z').toUtc(),
        );
        expect(
          container.read(authStatusNotifierProvider),
          AuthStatus.authenticated,
        );
      },
    );

    test(
      'ensureSessionActiveForCriticalAction uses short-lived cache',
      () async {
        final fakeRepository = _FakeAuthSessionRepository(
          validToken: 'token-123',
        );
        final fakeBackendRepository = _FakeAuthBackendRepository(
          sessionResult: _defaultSessionResult(),
        );
        final container = ProviderContainer(
          overrides: [
            authSessionRepositoryProvider.overrideWithValue(fakeRepository),
            authBackendRepositoryProvider.overrideWithValue(
              fakeBackendRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(authStatusNotifierProvider.notifier);
        final first = await notifier.ensureSessionActiveForCriticalAction();
        final afterFirst = fakeBackendRepository.getSessionCallCount;
        final second = await notifier.ensureSessionActiveForCriticalAction();

        expect(first, isTrue);
        expect(second, isTrue);
        expect(fakeBackendRepository.getSessionCallCount, afterFirst);
      },
    );

    test('critical validation cache resets after markAuthenticated', () async {
      final fakeRepository = _FakeAuthSessionRepository(
        validToken: 'token-123',
      );
      final fakeBackendRepository = _FakeAuthBackendRepository(
        sessionResult: _defaultSessionResult(),
      );
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
          authBackendRepositoryProvider.overrideWithValue(
            fakeBackendRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authStatusNotifierProvider.notifier);
      await notifier.validateSessionForCriticalAction();
      final callsAfterFirst = fakeBackendRepository.getSessionCallCount;
      await notifier.validateSessionForCriticalAction();
      expect(fakeBackendRepository.getSessionCallCount, callsAfterFirst);

      await notifier.markAuthenticated('fresh-token');
      await notifier.validateSessionForCriticalAction();
      expect(fakeBackendRepository.getSessionCallCount, callsAfterFirst + 1);
    });

    test('critical validation cache resets after logout', () async {
      final fakeRepository = _FakeAuthSessionRepository(
        validToken: 'token-123',
      );
      final fakeBackendRepository = _FakeAuthBackendRepository(
        sessionResult: _defaultSessionResult(),
      );
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
          authBackendRepositoryProvider.overrideWithValue(
            fakeBackendRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authStatusNotifierProvider.notifier);
      await notifier.validateSessionForCriticalAction();
      final callsAfterFirst = fakeBackendRepository.getSessionCallCount;
      await notifier.validateSessionForCriticalAction();
      expect(fakeBackendRepository.getSessionCallCount, callsAfterFirst);

      await notifier.logout(notifyBackend: false);
      fakeRepository.validToken = 'token-123';
      await notifier.validateSessionForCriticalAction();
      expect(fakeBackendRepository.getSessionCallCount, callsAfterFirst + 1);
    });

    test('retry after transient critical failure can recover', () async {
      final fakeRepository = _FakeAuthSessionRepository(
        validToken: 'token-123',
      );
      final fakeBackendRepository = _SequencedAuthBackendRepository(
        sequence: <Object>[
          const AuthBackendHttpException(
            statusCode: 500,
            message: 'temporary error',
          ),
          _defaultSessionResult(),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
          authBackendRepositoryProvider.overrideWithValue(
            fakeBackendRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authStatusNotifierProvider.notifier);
      final first = await notifier.validateSessionForCriticalAction();
      fakeBackendRepository.clearSequence();
      fakeBackendRepository.enqueue(_defaultSessionResult());
      notifier.resetCriticalValidationCacheForTest();
      final second = await notifier.validateSessionForCriticalAction();

      expect(first, SessionValidationOutcome.transientFailure);
      expect(second, SessionValidationOutcome.active);
      expect(
        container.read(authStatusNotifierProvider),
        AuthStatus.authenticated,
      );
    });

    test('concurrent critical validations do not break auth state', () async {
      final fakeRepository = _FakeAuthSessionRepository(
        validToken: 'token-123',
      );
      final fakeBackendRepository = _SequencedAuthBackendRepository(
        sequence: <Object>[
          _defaultSessionResult(),
          _defaultSessionResult(),
          _defaultSessionResult(),
        ],
        responseDelay: const Duration(milliseconds: 20),
      );
      final container = ProviderContainer(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(fakeRepository),
          authBackendRepositoryProvider.overrideWithValue(
            fakeBackendRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authStatusNotifierProvider.notifier);
      final results = await Future.wait(
        List<Future<SessionValidationOutcome>>.generate(
          3,
          (_) => notifier.validateSessionForCriticalAction(),
        ),
      );

      expect(
        results.every((r) => r == SessionValidationOutcome.active),
        isTrue,
      );
      expect(
        container.read(authStatusNotifierProvider),
        AuthStatus.authenticated,
      );
      expect(
        fakeBackendRepository.getSessionCallCount,
        greaterThanOrEqualTo(1),
      );
      expect(fakeBackendRepository.getSessionCallCount, lessThanOrEqualTo(3));

      final callsAfterConcurrent = fakeBackendRepository.getSessionCallCount;
      await notifier.validateSessionForCriticalAction();
      expect(fakeBackendRepository.getSessionCallCount, callsAfterConcurrent);
    });
  });
}

AuthBackendSessionResult _defaultSessionResult() {
  return const AuthBackendSessionResult(
    statusCode: 200,
    session: AuthBackendSession(
      id: 's_1',
      expiresAt: '2099-05-01T00:00:00.000Z',
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
  DateTime? savedSessionExpiresAt;
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
    Duration ttl = AuthSessionRepository.defaultSessionTtl,
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

  @override
  Future<AuthSession> saveSession({
    required String token,
    required DateTime expiresAt,
    DateTime? receivedAt,
  }) async {
    savedToken = token;
    validToken = token;
    savedSessionExpiresAt = expiresAt.toUtc();
    final resolvedReceivedAt = receivedAt?.toUtc() ?? DateTime.now().toUtc();
    this.expiresAt = savedSessionExpiresAt;
    return AuthSession(
      token: token,
      receivedAt: resolvedReceivedAt,
      expiresAt: savedSessionExpiresAt!,
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
  int getSessionCallCount = 0;
  int signOutCallCount = 0;
  String? lastSignOutToken;

  @override
  Future<AuthBackendSessionResult> getSession({
    required String bearerToken,
  }) async {
    getSessionCallCount++;
    if (sessionError != null) {
      throw sessionError!;
    }
    if (sessionResult != null) {
      return sessionResult!;
    }
    throw Exception('Missing fake session result');
  }

  @override
  Future<void> signOut({required String bearerToken}) async {
    signOutCallCount++;
    lastSignOutToken = bearerToken;
  }
}

class _NoopAuthRemoteService extends AuthRemoteService {
  _NoopAuthRemoteService()
    : super(apiClient: ApiClient(authTokenProvider: _FakeAuthTokenProvider()));

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

class _FakeAuthTokenProvider implements AuthTokenProvider {
  @override
  Future<String?> getValidToken() async {
    return null;
  }
}

class _SequencedAuthBackendRepository extends AuthBackendRepository {
  _SequencedAuthBackendRepository({
    required List<Object> sequence,
    this.responseDelay = Duration.zero,
  }) : _sequence = List<Object>.from(sequence),
       super(authRemoteService: _NoopAuthRemoteService());

  final Duration responseDelay;
  final List<Object> _sequence;

  void enqueue(Object value) {
    _sequence.add(value);
  }

  void clearSequence() {
    _sequence.clear();
  }

  @override
  Future<AuthBackendSessionResult> getSession({
    required String bearerToken,
  }) async {
    getSessionCallCount++;
    if (responseDelay > Duration.zero) {
      await Future<void>.delayed(responseDelay);
    }
    if (_sequence.isEmpty) {
      throw Exception('No sequenced response');
    }
    final next = _sequence.removeAt(0);
    if (next is AuthBackendSessionResult) {
      return next;
    }
    throw next;
  }

  int getSessionCallCount = 0;
}
