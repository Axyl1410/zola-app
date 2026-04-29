import 'package:flutter/material.dart';
import 'package:zola/di/injector.dart';
import 'package:zola/ui/core/widgets/default_home_app_bar.dart';
import 'package:zola/ui/features/discover/view_models/school_view_model.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
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
      appBar: buildDefaultHomeAppBar(title: 'Khám phá dịch vụ'),
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
          children: <Widget>[
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
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(24),
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
        children: <Widget>[
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
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
