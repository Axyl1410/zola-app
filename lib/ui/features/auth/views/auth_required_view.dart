import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';

class AuthRequiredView extends ConsumerWidget {
  const AuthRequiredView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.lock_outline, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Phiên đăng nhập đã hết hạn.\nVui lòng đăng nhập lại.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(authStatusNotifierProvider.notifier)
                      .refreshAuthStatus();
                },
                child: const Text('Kiểm tra lại phiên'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
