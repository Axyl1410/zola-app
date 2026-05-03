import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zola/data/models/todo_api_model.dart';
import 'package:zola/data/repositories/auth_session_repository.dart';
import 'package:zola/data/repositories/todo_repository.dart';
import 'package:zola/data/services/api_client.dart';
import 'package:zola/data/services/secure_storage_service.dart';
import 'package:zola/data/services/todo_remote_service.dart';

void main() {
  group('TodoRepository', () {
    test('maps api model to domain model', () async {
      final fakeService = _FakeTodoRemoteService();
      final repository = TodoRepository(todoRemoteService: fakeService);

      final result = await repository.getTodoById(1);

      expect(fakeService.lastRequestedId, 1);
      expect(result.userId, 11);
      expect(result.id, 1);
      expect(result.title, 'Test title');
      expect(result.completed, isTrue);
    });
  });
}

class _FakeTodoRemoteService extends TodoRemoteService {
  _FakeTodoRemoteService()
    : super(
        apiClient: ApiClient(authTokenProvider: _FakeAuthSessionRepository()),
      );

  int? lastRequestedId;

  @override
  Future<TodoApiModel> fetchTodoById(int id) async {
    lastRequestedId = id;
    return const TodoApiModel(
      userId: 11,
      id: 1,
      title: 'Test title',
      completed: true,
    );
  }
}

class _FakeAuthSessionRepository extends AuthSessionRepository {
  _FakeAuthSessionRepository()
    : super(secureStorageService: _FakeSecureStorageService());
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService() : super(storage: const FlutterSecureStorage());
}
