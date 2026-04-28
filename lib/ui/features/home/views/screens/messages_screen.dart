import 'package:flutter/material.dart';

import '../../view_models/messages_view_model.dart';
import '../widgets/default_home_app_bar.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    super.key,
    required this.counter,
    required this.onIncrement,
    required this.viewModel,
  });

  final int counter;
  final VoidCallback onIncrement;
  final MessagesViewModel viewModel;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_handleViewModelChanges);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_handleViewModelChanges);
    super.dispose();
  }

  Future<void> _handleViewModelChanges() async {
    final errorMessage = widget.viewModel.errorMessage;
    final authResult = widget.viewModel.authResult;
    if (!mounted) return;

    if (errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google sign-in error: $errorMessage')));
    }

    if (authResult != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authResult.idToken == null
                ? 'Login ok, but idToken is null'
                : 'Login ok, idToken/accessToken received',
          ),
        ),
      );
      await _showAuthResultDialog(
        context,
        email: authResult.email,
        idToken: authResult.idToken,
        accessToken: authResult.accessToken,
      );
      widget.viewModel.clearAuthResult();
    }
  }

  Future<void> _showAuthResultDialog(
    BuildContext context, {
    required String email,
    required String? idToken,
    required String accessToken,
  }) {
    return showDialog<void>(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: const Text('Google Login Result'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SelectableText('Email: $email'),
                    const SizedBox(height: 12),
                    SelectableText('idToken:\n${idToken ?? "null"}'),
                    const SizedBox(height: 12),
                    SelectableText('accessToken:\n$accessToken'),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildDefaultHomeAppBar(),
      body: Center(
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Text('Tin nhan'),
                Text('${widget.counter}'),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: widget.onIncrement,
                  child: const Text('Click me'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed:
                      widget.viewModel.isLoading
                          ? null
                          : widget.viewModel.signInWithGoogle,
                  child: Text(
                    widget.viewModel.isLoading
                        ? 'Signing in...'
                        : 'Test Google Login',
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
