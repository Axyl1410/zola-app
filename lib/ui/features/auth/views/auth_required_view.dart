import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';
import 'package:zola/ui/features/auth/views/login_view.dart';

class AuthRequiredView extends ConsumerWidget {
  const AuthRequiredView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            children: <Widget>[
              const Spacer(),
              const Icon(
                Icons.lock_clock_outlined,
                size: 60,
                color: Colors.lightBlue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Phiên đăng nhập đã hết hạn',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Để tiếp tục sử dụng ứng dụng,\nvui lòng đăng nhập lại.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginView(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Đăng nhập lại'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  ref
                      .read(authStatusNotifierProvider.notifier)
                      .refreshAuthStatus();
                },
                child: const Text('Kiểm tra lại phiên'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
