import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zola/data/repositories/auth_backend_repository.dart';
import 'package:zola/data/services/auth_remote_service.dart';
import 'package:zola/data/services/api_client.dart';
import 'package:zola/data/repositories/auth_session_repository.dart';
import 'package:zola/data/services/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zola/domain/models/google_auth_result.dart';

void main() {
  group('AuthBackendRepository', () {
    test('throws when idToken is null', () async {
      final fakeService = _FakeAuthRemoteService();
      final repository = AuthBackendRepository(authRemoteService: fakeService);
      const authResult = GoogleAuthResult(
        idToken: null,
        accessToken: 'access-token',
      );

      await expectLater(
        () => repository.signInWithGoogle(authResult),
        throwsA(isA<Exception>()),
      );
      expect(fakeService.called, isFalse);
    });

    test('throws when idToken is empty', () async {
      final fakeService = _FakeAuthRemoteService();
      final repository = AuthBackendRepository(authRemoteService: fakeService);
      const authResult = GoogleAuthResult(
        idToken: '',
        accessToken: 'access-token',
      );

      await expectLater(
        () => repository.signInWithGoogle(authResult),
        throwsA(isA<Exception>()),
      );
      expect(fakeService.called, isFalse);
    });

    test('delegates to remote service and maps response', () async {
      final fakeService = _FakeAuthRemoteService();
      final repository = AuthBackendRepository(authRemoteService: fakeService);
      const authResult = GoogleAuthResult(
        idToken: 'id-token',
        accessToken: 'access-token',
      );

      final result = await repository.signInWithGoogle(authResult);

      expect(fakeService.called, isTrue);
      expect(fakeService.lastIdToken, 'id-token');
      expect(fakeService.lastAccessToken, 'access-token');
      expect(result.statusCode, 201);
      expect(result.token, 'backend-jwt');
      expect(result.user, isNotNull);
      expect(result.user!.email, 'dev@zola.app');
      expect(result.user!.lastLoginMethod, 'google');
    });

    test('delegates signOut token to remote service', () async {
      final fakeService = _FakeAuthRemoteService();
      final repository = AuthBackendRepository(authRemoteService: fakeService);

      await repository.signOut(bearerToken: 'secret-token');

      expect(fakeService.signOutCalled, isTrue);
      expect(fakeService.lastBearerToken, 'secret-token');
    });

    test('throws backend message for 4xx/5xx responses', () async {
      final fakeService = _FakeAuthRemoteService(
        signInResponse: http.Response('{"message":"Unauthorized"}', 401),
      );
      final repository = AuthBackendRepository(authRemoteService: fakeService);
      const authResult = GoogleAuthResult(
        idToken: 'id-token',
        accessToken: 'access-token',
      );

      await expectLater(
        () => repository.signInWithGoogle(authResult),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Unauthorized'),
          ),
        ),
      );
    });

    test('signOut throws backend message for 4xx/5xx responses', () async {
      final fakeService = _FakeAuthRemoteService(
        signOutResponse: http.Response('{"message":"Session expired"}', 401),
      );
      final repository = AuthBackendRepository(authRemoteService: fakeService);

      await expectLater(
        () => repository.signOut(bearerToken: 'secret-token'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Session expired'),
          ),
        ),
      );
    });
  });
}

class _FakeAuthRemoteService extends AuthRemoteService {
  _FakeAuthRemoteService({this.signInResponse, this.signOutResponse})
    : super(
        apiClient: ApiClient(
          authTokenProvider: _FakeAuthSessionRepository(),
        ),
      );

  bool called = false;
  bool signOutCalled = false;
  String? lastIdToken;
  String? lastAccessToken;
  String? lastBearerToken;
  final http.Response? signInResponse;
  final http.Response? signOutResponse;

  @override
  Future<http.Response> signInWithGoogle({
    required String idToken,
    required String accessToken,
  }) async {
    called = true;
    lastIdToken = idToken;
    lastAccessToken = accessToken;
    return signInResponse ??
        http.Response(
          '{"token":"backend-jwt","user":{"id":"u_1","name":"Dev","email":"dev@zola.app","emailVerified":true,"lastLoginMethod":"google"}}',
          201,
        );
  }

  @override
  Future<http.Response> signOut({required String bearerToken}) async {
    signOutCalled = true;
    lastBearerToken = bearerToken;
    return signOutResponse ?? http.Response('{}', 200);
  }
}

class _FakeAuthSessionRepository extends AuthSessionRepository {
  _FakeAuthSessionRepository()
    : super(secureStorageService: _FakeSecureStorageService());
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService() : super(storage: const FlutterSecureStorage());
}
