import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/ui/features/auth/view_models/login_providers.dart';
import 'package:zola/ui/features/auth/view_models/login_view_model.dart';

class LoginView extends ConsumerWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<LoginState>(loginNotifierProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    final state = ref.watch(loginNotifierProvider);
    final notifier = ref.read(loginNotifierProvider.notifier);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.account_circle_outlined, size: 56),
              const SizedBox(height: 12),
              const Text('Đăng nhập để tiếp tục'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: state.isLoading ? null : notifier.signInWithGoogle,
                child: Text(
                  state.isLoading ? 'Đang đăng nhập...' : 'Login Google',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
