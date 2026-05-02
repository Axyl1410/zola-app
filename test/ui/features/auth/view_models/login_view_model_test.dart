import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zola/data/models/google_sign_in_tokens_model.dart';
import 'package:zola/data/repositories/auth_backend_repository.dart';
import 'package:zola/data/repositories/auth_session_repository.dart';
import 'package:zola/data/repositories/google_auth_repository.dart';
import 'package:zola/data/services/api_client.dart';
import 'package:zola/data/services/auth_remote_service.dart';
import 'package:zola/data/services/google_sign_in_service.dart';
import 'package:zola/data/services/secure_storage_service.dart';
import 'package:zola/di/providers/repositories_providers.dart';
import 'package:zola/domain/models/google_auth_result.dart';
import 'package:zola/domain/models/auth_user.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_view_model.dart';
import 'package:zola/ui/features/auth/view_models/login_view_model.dart';
import 'package:zola/ui/features/auth/view_models/login_providers.dart';

void main() {
  group('LoginNotifier', () {
    test('formatTokenForLog masks token by default', () {
      expect(
        LoginNotifier.formatTokenForLog('backend-jwt'),
        'backen***-jwt',
      );
      expect(LoginNotifier.formatTokenForLog('1234567890'), '12***');
    });

    test('formatTokenForLog returns full token when enabled', () {
      expect(
        LoginNotifier.formatTokenForLog(
          'backend-jwt',
          logFullToken: true,
        ),
        'backend-jwt',
      );
    });

    test('signInWithGoogle saves backend token and succeeds', () async {
      final fakeGoogleRepo = _FakeGoogleAuthRepository();
      final fakeBackendRepo = _FakeAuthBackendRepository(
        shouldThrowMissingToken: false,
      );
      final container = ProviderContainer(
        overrides: [
          googleAuthRepositoryProvider.overrideWithValue(fakeGoogleRepo),
          authBackendRepositoryProvider.overrideWithValue(fakeBackendRepo),
          authStatusNotifierProvider.overrideWith(_FakeAuthStatusNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      await container.read(loginNotifierProvider.notifier).signInWithGoogle();
      final state = container.read(loginNotifierProvider);
      final authStatus = container.read(authStatusNotifierProvider);

      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.isSuccess, isTrue);
      expect(authStatus, AuthStatus.authenticated);
      expect(fakeGoogleRepo.called, isTrue);
      expect(fakeBackendRepo.called, isTrue);
    });

    test('sets error when backend response has no token', () async {
      final container = ProviderContainer(
        overrides: [
          googleAuthRepositoryProvider.overrideWithValue(
            _FakeGoogleAuthRepository(),
          ),
          authBackendRepositoryProvider.overrideWithValue(
            _FakeAuthBackendRepository(shouldThrowMissingToken: true),
          ),
          authStatusNotifierProvider.overrideWith(_FakeAuthStatusNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      await container.read(loginNotifierProvider.notifier).signInWithGoogle();
      final state = container.read(loginNotifierProvider);

      expect(state.isSuccess, isFalse);
      expect(state.errorMessage, contains('missing token'));
    });

    test(
      'persists lastLoginMethod when backend user has non-empty value',
      () async {
        final recordingRepo = _RecordingAuthSessionRepository();
        final container = ProviderContainer(
          overrides: [
            googleAuthRepositoryProvider.overrideWithValue(
              _FakeGoogleAuthRepository(),
            ),
            authBackendRepositoryProvider.overrideWithValue(
              _FakeAuthBackendRepository(
                shouldThrowMissingToken: false,
                user: const AuthUser(
                  id: 'u_1',
                  name: 'Dev',
                  email: 'dev@zola.app',
                  emailVerified: true,
                  lastLoginMethod: 'google',
                ),
              ),
            ),
            authSessionRepositoryProvider.overrideWithValue(recordingRepo),
            authStatusNotifierProvider.overrideWith(_FakeAuthStatusNotifier.new),
          ],
        );
        addTearDown(container.dispose);

        await container.read(loginNotifierProvider.notifier).signInWithGoogle();

        expect(recordingRepo.savedLastLoginMethods, ['google']);
      },
    );

    test(
      'does NOT persist lastLoginMethod when backend user value is null',
      () async {
        final recordingRepo = _RecordingAuthSessionRepository();
        await recordingRepo.saveLastLoginMethod('google');
        recordingRepo.savedLastLoginMethods.clear();

        final container = ProviderContainer(
          overrides: [
            googleAuthRepositoryProvider.overrideWithValue(
              _FakeGoogleAuthRepository(),
            ),
            authBackendRepositoryProvider.overrideWithValue(
              _FakeAuthBackendRepository(
                shouldThrowMissingToken: false,
                user: const AuthUser(
                  id: 'u_1',
                  name: 'Dev',
                  email: 'dev@zola.app',
                  emailVerified: true,
                ),
              ),
            ),
            authSessionRepositoryProvider.overrideWithValue(recordingRepo),
            authStatusNotifierProvider.overrideWith(_FakeAuthStatusNotifier.new),
          ],
        );
        addTearDown(container.dispose);

        await container.read(loginNotifierProvider.notifier).signInWithGoogle();

        expect(recordingRepo.savedLastLoginMethods, isEmpty);
        expect(await recordingRepo.getLastLoginMethod(), 'google');
      },
    );
  });
}

class _FakeGoogleAuthRepository extends GoogleAuthRepository {
  _FakeGoogleAuthRepository()
    : super(googleSignInService: _NoopGoogleSignInService());

  bool called = false;

  @override
  Future<GoogleAuthResult> signInWithGoogle() async {
    called = true;
    return const GoogleAuthResult(
      idToken: 'id-token',
      accessToken: 'access-token',
    );
  }
}

class _NoopGoogleSignInService extends GoogleSignInService {
  @override
  Future<GoogleSignInTokensModel> signIn() {
    throw UnimplementedError();
  }
}

class _FakeAuthBackendRepository extends AuthBackendRepository {
  _FakeAuthBackendRepository({required this.shouldThrowMissingToken, this.user})
    : super(authRemoteService: _NoopAuthRemoteService());

  final bool shouldThrowMissingToken;
  final AuthUser? user;
  bool called = false;

  @override
  Future<AuthBackendSignInResult> signInWithGoogle(
    GoogleAuthResult authResult,
  ) async {
    called = true;
    if (shouldThrowMissingToken) {
      throw Exception('Backend response missing token');
    }
    return AuthBackendSignInResult(
      statusCode: 200,
      token: 'backend-jwt',
      user: user,
    );
  }
}

class _NoopAuthRemoteService extends AuthRemoteService {
  _NoopAuthRemoteService()
    : super(
        apiClient: ApiClient(
          authTokenProvider: _FakeAuthSessionRepository(),
        ),
      );

  @override
  Future<http.Response> signInWithGoogle({
    required String idToken,
    required String accessToken,
  }) {
    throw UnimplementedError();
  }
}

class _FakeAuthSessionRepository extends AuthSessionRepository {
  _FakeAuthSessionRepository()
    : super(secureStorageService: _FakeSecureStorageService());
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService() : super(storage: const FlutterSecureStorage());
}

class _RecordingAuthSessionRepository extends AuthSessionRepository {
  _RecordingAuthSessionRepository()
    : super(secureStorageService: _InMemorySecureStorageService());

  final List<String> savedLastLoginMethods = <String>[];

  @override
  Future<void> saveLastLoginMethod(String method) async {
    if (method.isEmpty) {
      return;
    }
    savedLastLoginMethods.add(method);
    await super.saveLastLoginMethod(method);
  }
}

class _InMemorySecureStorageService extends SecureStorageService {
  _InMemorySecureStorageService() : super(storage: const FlutterSecureStorage());

  final Map<String, String> _store = <String, String>{};

  @override
  Future<void> writeValue({required String key, required String value}) async {
    _store[key] = value;
  }

  @override
  Future<String?> readValue(String key) async {
    return _store[key];
  }

  @override
  Future<void> deleteValue(String key) async {
    _store.remove(key);
  }

  @override
  Future<Map<String, String>> readAll() async {
    return Map<String, String>.from(_store);
  }
}

class _FakeAuthStatusNotifier extends AuthStatusNotifier {
  @override
  AuthStatus build() => AuthStatus.unauthenticated;

  @override
  Future<void> markAuthenticated(String token, {AuthUser? user}) async {
    state = AuthStatus.authenticated;
  }
}
