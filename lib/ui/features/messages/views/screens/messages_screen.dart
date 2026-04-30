import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/domain/models/google_auth_result.dart';
import 'package:zola/ui/core/widgets/default_home_app_bar.dart';
import 'package:zola/ui/features/messages/view_models/messages_providers.dart';
import 'package:zola/ui/features/messages/view_models/messages_view_model.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  bool _isHandlingAuthResult = false;
  int _counter = 0;

  Future<void> _handleAuthResult(GoogleAuthResult authResult) async {
    _isHandlingAuthResult = true;
    try {
      if (!mounted) {
        return;
      }
      _logAuthResult(authResult);
      final currentState = ref.read(messagesNotifierProvider);
      _logBackendResult(currentState);
      final statusCode = currentState.backendStatusCode;
      final message = statusCode == null
          ? 'Google login done. Backend response missing.'
          : 'Google + Backend done. Status: $statusCode';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      if (mounted) {
        ref.read(messagesNotifierProvider.notifier).clearAuthResult();
      }
    } finally {
      _isHandlingAuthResult = false;
    }
  }

  void _logAuthResult(GoogleAuthResult authResult) {
    debugPrint('========== GOOGLE_LOGIN_SUCCESS ==========');
    debugPrint('idToken: ${authResult.idToken ?? "null"}');
    debugPrint('accessToken: ${authResult.accessToken}');
    debugPrint('==========================================');
  }

  void _logBackendResult(MessagesState state) {
    debugPrint('===== BACKEND_SIGN_IN_SOCIAL_RESPONSE =====');
    debugPrint('statusCode: ${state.backendStatusCode}');
    debugPrint('body: ${state.backendResponseBody}');
    debugPrint('===============================================');
  }

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
          SnackBar(content: Text('Google sign-in error: $nextError')),
        );
      }

      final authResult = next.authResult;
      final shouldHandleAuth =
          authResult != null && previous?.authResult != authResult;
      if (shouldHandleAuth && !_isHandlingAuthResult) {
        unawaited(_handleAuthResult(authResult));
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
            const Text('Tin nhan'),
            Text('$_counter'),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () => setState(() => _counter++),
              child: const Text('Click me'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: state.isLoading ? null : notifier.signInWithGoogle,
              child: Text(
                state.isLoading ? 'Signing in...' : 'Login Google + Backend',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
