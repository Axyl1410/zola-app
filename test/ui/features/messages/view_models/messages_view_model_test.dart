import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:zola/di/providers.dart';
import 'package:zola/domain/models/google_auth_result.dart';

void main() {
  group('MessagesNotifier', () {
    test('signInWithGoogle sets auth result on success', () async {
      final fakeRepository = _FakeGoogleAuthRepository();
      final fakeAuthBackendRepository = _FakeAuthBackendRepository();
      final container = ProviderContainer(
        overrides: [
          googleAuthRepositoryProvider.overrideWithValue(fakeRepository),
          authBackendRepositoryProvider.overrideWithValue(
            fakeAuthBackendRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(messagesNotifierProvider.notifier);

      await notifier.signInWithGoogle();
      final state = container.read(messagesNotifierProvider);

      expect(fakeRepository.signInCalled, isTrue);
      expect(fakeAuthBackendRepository.signInCalled, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.authResult, isNotNull);
      expect(state.authResult!.idToken, 'id-token');
      expect(state.authResult!.accessToken, 'access-token');
      expect(state.backendStatusCode, 200);
    });

    test('signInWithGoogle sets error message on failure', () async {
      final fakeRepository = _FakeGoogleAuthRepository(throwOnSignIn: true);
      final fakeAuthBackendRepository = _FakeAuthBackendRepository();
      final container = ProviderContainer(
        overrides: [
          googleAuthRepositoryProvider.overrideWithValue(fakeRepository),
          authBackendRepositoryProvider.overrideWithValue(
            fakeAuthBackendRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(messagesNotifierProvider.notifier);

      await notifier.signInWithGoogle();
      final state = container.read(messagesNotifierProvider);

      expect(state.isLoading, isFalse);
      expect(state.authResult, isNull);
      expect(state.errorMessage, contains('Google sign-in failed'));
    });

    test('clearAuthResult resets stored auth result', () async {
      final fakeRepository = _FakeGoogleAuthRepository();
      final fakeAuthBackendRepository = _FakeAuthBackendRepository();
      final container = ProviderContainer(
        overrides: [
          googleAuthRepositoryProvider.overrideWithValue(fakeRepository),
          authBackendRepositoryProvider.overrideWithValue(
            fakeAuthBackendRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(messagesNotifierProvider.notifier);
      await notifier.signInWithGoogle();

      notifier.clearAuthResult();
      final state = container.read(messagesNotifierProvider);

      expect(state.authResult, isNull);
    });
  });
}

class _FakeGoogleAuthRepository extends GoogleAuthRepository {
  _FakeGoogleAuthRepository({this.throwOnSignIn = false})
    : super(googleSignInService: _NoopGoogleSignInService());

  final bool throwOnSignIn;
  bool signInCalled = false;

  @override
  Future<GoogleAuthResult> signInWithGoogle() async {
    signInCalled = true;
    if (throwOnSignIn) {
      throw Exception('Google sign-in failed');
    }
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
  _FakeAuthBackendRepository()
    : super(authRemoteService: _NoopAuthRemoteService());

  bool signInCalled = false;

  @override
  Future<AuthBackendSignInResult> signInWithGoogle(
    GoogleAuthResult authResult,
  ) async {
    signInCalled = true;
    return const AuthBackendSignInResult(statusCode: 200, body: '{}');
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
