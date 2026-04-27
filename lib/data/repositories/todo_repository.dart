import '../../domain/models/todo_item.dart';
import '../services/todo_remote_service.dart';

class TodoRepository {
  TodoRepository({required TodoRemoteService todoRemoteService})
    : _todoRemoteService = todoRemoteService;

  final TodoRemoteService _todoRemoteService;

  Future<TodoItem> getTodoById(int id) async {
    final apiModel = await _todoRemoteService.fetchTodoById(id);
    return TodoItem(
      userId: apiModel.userId,
      id: apiModel.id,
      title: apiModel.title,
      completed: apiModel.completed,
    );
  }
}
