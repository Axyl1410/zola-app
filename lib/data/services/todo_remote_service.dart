import 'dart:convert';

import 'package:zola/data/models/todo_api_model.dart';

import 'api_client.dart';

class TodoRemoteService {
  TodoRemoteService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<TodoApiModel> fetchTodoById(int id) async {
    final response = await _apiClient.get(
      Uri.parse('https://jsonplaceholder.typicode.com/todos/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch todo. Status: ${response.statusCode}');
    }

    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    return TodoApiModel.fromJson(jsonMap);
  }
}
