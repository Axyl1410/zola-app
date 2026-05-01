import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/ui/core/widgets/default_home_app_bar.dart';
import 'package:zola/ui/features/messages/view_models/messages_providers.dart';
import 'package:zola/ui/features/messages/view_models/messages_view_model.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen<MessagesState>(messagesNotifierProvider, (previous, next) {
      if (!mounted) {
        return;
      }

      final previousError = previous?.errorMessage;
      final nextError = next.errorMessage;
      if (nextError != null && nextError != previousError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(nextError)),
        );
      }
    });
    final state = ref.watch(messagesNotifierProvider);
    final notifier = ref.read(messagesNotifierProvider.notifier);

    return Scaffold(
      appBar: buildDefaultHomeAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text('Tin nhắn'),
            Text('$_counter'),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () => setState(() => _counter++),
              child: const Text('Bấm thử'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: state.isLoading ? null : notifier.logout,
              child: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    );
  }
}
