import 'package:flutter/material.dart';
import 'package:zola/data/repositories/todo_repository.dart';
import 'package:zola/domain/models/todo_item.dart';

class SchoolViewModel extends ChangeNotifier {
  SchoolViewModel({required TodoRepository todoRepository})
    : _todoRepository = todoRepository;

  final TodoRepository _todoRepository;

  bool _isLoading = false;
  String? _errorMessage;
  TodoItem? _todo;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TodoItem? get todo => _todo;

  Future<void> loadTodo(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _todo = await _todoRepository.getTodoById(id);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
