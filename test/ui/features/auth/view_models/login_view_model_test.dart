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
import 'package:zola/ui/features/auth/view_models/login_providers.dart';

void main() {
  group('LoginNotifier', () {
    test('signInWithGoogle saves backend token and succeeds', () async {
      final fakeGoogleRepo = _FakeGoogleAuthRepository();
      final fakeBackendRepo = _FakeAuthBackendRepository(
        responseBody: '{"token":"backend-jwt"}',
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
            _FakeAuthBackendRepository(responseBody: '{"ok":true}'),
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
  _FakeAuthBackendRepository({required this.responseBody})
    : super(authRemoteService: _NoopAuthRemoteService());

  final String responseBody;
  bool called = false;

  @override
  Future<AuthBackendSignInResult> signInWithGoogle(
    GoogleAuthResult authResult,
  ) async {
    called = true;
    return AuthBackendSignInResult(statusCode: 200, body: responseBody);
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
}

class _FakeAuthSessionRepository extends AuthSessionRepository {
  _FakeAuthSessionRepository()
    : super(secureStorageService: _FakeSecureStorageService());
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService() : super(storage: const FlutterSecureStorage());
}

class _FakeAuthStatusNotifier extends AuthStatusNotifier {
  @override
  AuthStatus build() => AuthStatus.unauthenticated;

  @override
  Future<void> markAuthenticated(String token, {AuthUser? user}) async {
    state = AuthStatus.authenticated;
  }
}
