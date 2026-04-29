import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zola/di/injector.dart';
import 'package:zola/domain/models/google_auth_result.dart';
import 'package:zola/ui/core/widgets/default_home_app_bar.dart';
import 'package:zola/ui/features/messages/view_models/messages_view_model.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _isHandlingAuthResult = false;
  int _counter = 0;
  late final MessagesViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = sl<MessagesViewModel>();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    final errorMessage = _viewModel.errorMessage;
    final authResult = _viewModel.authResult;
    if (!mounted) {
      return;
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in error: $errorMessage')),
      );
    }

    if (authResult == null || _isHandlingAuthResult) {
      return;
    }
    unawaited(_handleAuthResult(authResult));
  }

  Future<void> _handleAuthResult(GoogleAuthResult authResult) async {
    _isHandlingAuthResult = true;
    try {
      if (!mounted) {
        return;
      }
      _logAuthResult(authResult);
      _logBackendResult();
      final statusCode = _viewModel.backendStatusCode;
      final message = statusCode == null
          ? 'Google login done. Backend response missing.'
          : 'Google + Backend done. Status: $statusCode';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      if (mounted) {
        _viewModel.clearAuthResult();
      }
    } finally {
      _isHandlingAuthResult = false;
    }
  }

  void _logAuthResult(GoogleAuthResult authResult) {
    debugPrint('========== GOOGLE_LOGIN_SUCCESS ==========');
    debugPrint('email: ${authResult.email}');
    debugPrint('idToken: ${authResult.idToken ?? "null"}');
    debugPrint('accessToken: ${authResult.accessToken}');
    debugPrint('==========================================');
  }

  void _logBackendResult() {
    debugPrint('===== BACKEND_SIGN_IN_SOCIAL_RESPONSE =====');
    debugPrint('statusCode: ${_viewModel.backendStatusCode}');
    debugPrint('body: ${_viewModel.backendResponseBody}');
    debugPrint('===============================================');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildDefaultHomeAppBar(),
      body: Center(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return Column(
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
                  onPressed: _viewModel.isLoading
                      ? null
                      : _viewModel.signInWithGoogle,
                  child: Text(
                    _viewModel.isLoading
                        ? 'Signing in...'
                        : 'Login Google + Backend',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
