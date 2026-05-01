import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zola/data/repositories/auth_session_repository.dart';
import 'package:zola/data/services/api_client.dart';
import 'package:zola/data/services/secure_storage_service.dart';
import 'package:zola/data/services/todo_remote_service.dart';

void main() {
  group('TodoRemoteService', () {
    test('returns parsed model on 200 response', () async {
      final fakeClient = _FakeApiClient(
        response: http.Response(
          '{"userId":1,"id":7,"title":"test todo","completed":false}',
          200,
        ),
      );
      final service = TodoRemoteService(apiClient: fakeClient);

      final model = await service.fetchTodoById(7);

      expect(fakeClient.lastUri.toString(), contains('/todos/7'));
      expect(model.userId, 1);
      expect(model.id, 7);
      expect(model.title, 'test todo');
      expect(model.completed, isFalse);
    });

    test('throws when response status is not 200', () async {
      final fakeClient = _FakeApiClient(response: http.Response('error', 500));
      final service = TodoRemoteService(apiClient: fakeClient);

      await expectLater(
        () => service.fetchTodoById(1),
        throwsA(isA<Exception>()),
      );
    });
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({required this.response})
    : super(authTokenProvider: _FakeAuthSessionRepository());

  final http.Response response;
  Uri? lastUri;

  @override
  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    lastUri = uri;
    return response;
  }
}

class _FakeAuthSessionRepository extends AuthSessionRepository {
  _FakeAuthSessionRepository()
    : super(secureStorageService: _FakeSecureStorageService());
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService() : super(storage: const FlutterSecureStorage());
}
