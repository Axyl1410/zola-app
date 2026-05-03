import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zola/data/repositories/auth_session_repository.dart';
import 'package:zola/data/services/api_client.dart';
import 'package:zola/data/services/auth_remote_service.dart';
import 'package:zola/data/services/secure_storage_service.dart';

void main() {
  group('AuthRemoteService', () {
    test('throws when backend base url is missing', () async {
      final service = AuthRemoteService(
        apiClient: ApiClient(authTokenProvider: _FakeAuthSessionRepository()),
      );

      await expectLater(
        () => service.signInWithGoogle(
          idToken: 'id-token',
          accessToken: 'access-token',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}

class _FakeAuthSessionRepository extends AuthSessionRepository {
  _FakeAuthSessionRepository()
    : super(secureStorageService: _FakeSecureStorageService());
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService() : super(storage: const FlutterSecureStorage());
}
