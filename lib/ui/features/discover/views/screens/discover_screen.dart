import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/ui/core/widgets/default_home_app_bar.dart';
import 'package:zola/ui/features/discover/view_models/school_providers.dart';
import 'package:zola/ui/features/discover/view_models/school_view_model.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(schoolNotifierProvider.notifier).loadTodo(1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schoolNotifierProvider);
    final notifier = ref.read(schoolNotifierProvider.notifier);
    return Scaffold(
      appBar: buildDefaultHomeAppBar(title: 'Khám phá dịch vụ'),
      body: _buildBody(state, notifier),
    );
  }

  Widget _buildBody(SchoolState state, SchoolNotifier notifier) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return RefreshIndicator(
        onRefresh: () => notifier.loadTodo(1),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error: ${state.errorMessage}\n\nPull down to retry.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    final todo = state.todo;
    if (todo == null) {
      return RefreshIndicator(
        onRefresh: () => notifier.loadTodo(1),
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
      onRefresh: () => notifier.loadTodo(1),
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
                    onPressed: () => notifier.loadTodo(1),
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
