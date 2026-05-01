import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zola/data/repositories/auth_backend_repository.dart';
import 'package:zola/data/repositories/auth_session_repository.dart';
import 'package:zola/data/services/api_client.dart';
import 'package:zola/data/services/auth_remote_service.dart';
import 'package:zola/data/services/secure_storage_service.dart';
import 'package:zola/di/providers.dart';
import 'package:zola/domain/models/auth_user.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_view_model.dart';

void main() {
  group('MessagesNotifier', () {
    test('logout calls signOut with token and clears session state', () async {
      final fakeAuthBackendRepository = _FakeAuthBackendRepository();
      final fakeSessionRepository = _FakeAuthSessionRepository(
        validToken: 'secret-token',
      );
      final container = ProviderContainer(
        overrides: [
          authBackendRepositoryProvider.overrideWithValue(
            fakeAuthBackendRepository,
          ),
          authSessionRepositoryProvider.overrideWithValue(
            fakeSessionRepository,
          ),
          authStatusNotifierProvider.overrideWith(_FakeAuthStatusNotifier.new),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(messagesNotifierProvider.notifier);

      await notifier.logout();

      expect(fakeAuthBackendRepository.signOutCalled, isTrue);
      expect(fakeAuthBackendRepository.lastSignOutToken, 'secret-token');
      expect(fakeSessionRepository.clearCalled, isTrue);
      expect(container.read(messagesNotifierProvider).isLoading, isFalse);
    });

    test('logout still clears session when signOut fails', () async {
      final fakeAuthBackendRepository = _FakeAuthBackendRepository(
        throwOnSignOut: true,
      );
      final fakeSessionRepository = _FakeAuthSessionRepository(
        validToken: 'secret-token',
      );
      final container = ProviderContainer(
        overrides: [
          authBackendRepositoryProvider.overrideWithValue(
            fakeAuthBackendRepository,
          ),
          authSessionRepositoryProvider.overrideWithValue(
            fakeSessionRepository,
          ),
          authStatusNotifierProvider.overrideWith(_FakeAuthStatusNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      await container.read(messagesNotifierProvider.notifier).logout();

      expect(fakeAuthBackendRepository.signOutCalled, isTrue);
      expect(fakeSessionRepository.clearCalled, isTrue);
    });
  });
}

class _FakeAuthBackendRepository extends AuthBackendRepository {
  _FakeAuthBackendRepository({this.throwOnSignOut = false})
    : super(authRemoteService: _NoopAuthRemoteService());

  bool signOutCalled = false;
  String? lastSignOutToken;
  final bool throwOnSignOut;

  @override
  Future<void> signOut({required String bearerToken}) async {
    signOutCalled = true;
    lastSignOutToken = bearerToken;
    if (throwOnSignOut) {
      throw Exception('sign-out failed');
    }
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
  _FakeAuthSessionRepository({this.validToken})
    : super(secureStorageService: _FakeSecureStorageService());

  String? validToken;
  bool clearCalled = false;

  @override
  Future<String?> getValidToken() async {
    return validToken;
  }

  @override
  Future<void> clearSession() async {
    clearCalled = true;
    validToken = null;
  }
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
