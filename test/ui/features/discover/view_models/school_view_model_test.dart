import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zola/data/repositories/auth_session_repository.dart';
import 'package:zola/data/repositories/todo_repository.dart';
import 'package:zola/data/services/api_client.dart';
import 'package:zola/data/services/secure_storage_service.dart';
import 'package:zola/data/services/todo_remote_service.dart';
import 'package:zola/di/providers.dart';
import 'package:zola/domain/models/todo_item.dart';

void main() {
  group('SchoolNotifier', () {
    test('loadTodo updates loading and todo on success', () async {
      final fakeRepository = _FakeTodoRepository();
      final container = ProviderContainer(
        overrides: [todoRepositoryProvider.overrideWithValue(fakeRepository)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(schoolNotifierProvider.notifier);

      await notifier.loadTodo(1);
      final state = container.read(schoolNotifierProvider);

      expect(fakeRepository.lastRequestedId, 1);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.todo, isNotNull);
      expect(state.todo!.title, 'Todo from repository');
    });

    test('loadTodo sets error when repository throws', () async {
      final fakeRepository = _FakeTodoRepository(throwOnFetch: true);
      final container = ProviderContainer(
        overrides: [todoRepositoryProvider.overrideWithValue(fakeRepository)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(schoolNotifierProvider.notifier);

      await notifier.loadTodo(1);
      final state = container.read(schoolNotifierProvider);

      expect(state.isLoading, isFalse);
      expect(state.todo, isNull);
      expect(state.errorMessage, isNotNull);
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
