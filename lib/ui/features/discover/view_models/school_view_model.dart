import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/di/providers/repositories_providers.dart';
import 'package:zola/domain/models/todo_item.dart';

const _unsetSchoolField = Object();

class SchoolState {
  const SchoolState({this.isLoading = false, this.errorMessage, this.todo});

  final bool isLoading;
  final String? errorMessage;
  final TodoItem? todo;

  SchoolState copyWith({
    bool? isLoading,
    Object? errorMessage = _unsetSchoolField,
    Object? todo = _unsetSchoolField,
  }) {
    return SchoolState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unsetSchoolField)
          ? this.errorMessage
          : errorMessage as String?,
      todo: identical(todo, _unsetSchoolField) ? this.todo : todo as TodoItem?,
    );
  }
}

class SchoolNotifier extends Notifier<SchoolState> {
  @override
  SchoolState build() => const SchoolState();

  Future<void> loadTodo(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final todo = await ref.read(todoRepositoryProvider).getTodoById(id);
      state = state.copyWith(isLoading: false, errorMessage: null, todo: todo);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
        todo: null,
      );
    }
  }
}
