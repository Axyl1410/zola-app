import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zola/data/repositories/auth_session_repository.dart';
import 'package:zola/data/repositories/todo_repository.dart';
import 'package:zola/data/services/api_client.dart';
import 'package:zola/data/services/secure_storage_service.dart';
import 'package:zola/data/services/todo_remote_service.dart';
import 'package:zola/domain/models/todo_item.dart';
import 'package:zola/ui/features/home/view_models/school_view_model.dart';

void main() {
  group('SchoolViewModel', () {
    test('loadTodo updates loading and todo on success', () async {
      final fakeRepository = _FakeTodoRepository();
      final viewModel = SchoolViewModel(todoRepository: fakeRepository);

      await viewModel.loadTodo(1);

      expect(fakeRepository.lastRequestedId, 1);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.todo, isNotNull);
      expect(viewModel.todo!.title, 'Todo from repository');
    });

    test('loadTodo sets error when repository throws', () async {
      final fakeRepository = _FakeTodoRepository(throwOnFetch: true);
      final viewModel = SchoolViewModel(todoRepository: fakeRepository);

      await viewModel.loadTodo(1);

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.todo, isNull);
      expect(viewModel.errorMessage, isNotNull);
    });
  });
}

class _FakeTodoRepository extends TodoRepository {
  _FakeTodoRepository({this.throwOnFetch = false})
    : super(
        todoRemoteService: TodoRemoteService(
          apiClient: ApiClient(
            authSessionRepository: _FakeAuthSessionRepository(),
          ),
        ),
      );

  final bool throwOnFetch;
  int? lastRequestedId;

  @override
  Future<TodoItem> getTodoById(int id) async {
    lastRequestedId = id;
    if (throwOnFetch) {
      throw Exception('Repository error');
    }
    return const TodoItem(
      userId: 1,
      id: 1,
      title: 'Todo from repository',
      completed: false,
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
