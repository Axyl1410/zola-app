import 'package:flutter/material.dart';
import 'package:zola/di/injector.dart';
import 'package:zola/ui/features/home/view_models/school_view_model.dart';

import '../widgets/default_home_app_bar.dart';

class SchoolScreen extends StatefulWidget {
  const SchoolScreen({super.key});

  @override
  State<SchoolScreen> createState() => _SchoolScreenState();
}

class _SchoolScreenState extends State<SchoolScreen> {
  late final SchoolViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = sl<SchoolViewModel>();
    _viewModel.loadTodo(1);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildDefaultHomeAppBar(title: 'School'),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.errorMessage != null) {
      return RefreshIndicator(
        onRefresh: () => _viewModel.loadTodo(1),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error: ${_viewModel.errorMessage}\n\nPull down to retry.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    final todo = _viewModel.todo;
    if (todo == null) {
      return RefreshIndicator(
        onRefresh: () => _viewModel.loadTodo(1),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No data\n\nPull down to refresh.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _viewModel.loadTodo(1),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('userId: ${todo.userId}'),
                  Text('id: ${todo.id}'),
                  Text('title: ${todo.title}'),
                  Text('completed: ${todo.completed}'),
                  TextButton(
                    onPressed: () => _viewModel.loadTodo(1),
                    child: const Text('reload'),
                  ),
                  const Text(
                    'Pull down anywhere to refresh.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
