import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_view_model.dart';
import 'package:zola/ui/features/auth/views/auth_required_view.dart';

void main() {
  testWidgets('AuthRequiredView retries session when tapping check button', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authStatusNotifierProvider.overrideWith(
          () => _FakeAuthStatusNotifier(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AuthRequiredView()),
      ),
    );
    await tester.tap(find.text('Kiểm tra lại phiên'));
    await tester.pump();

    final notifier = container.read(authStatusNotifierProvider.notifier)
        as _FakeAuthStatusNotifier;
    expect(notifier.refreshCalled, isTrue);
  });

  testWidgets('AuthRequiredView logs out locally when tapping relogin', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authStatusNotifierProvider.overrideWith(
          () => _FakeAuthStatusNotifier(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AuthRequiredView()),
      ),
    );
    await tester.tap(find.text('Đăng nhập lại'));
    await tester.pump();

    final notifier = container.read(authStatusNotifierProvider.notifier)
        as _FakeAuthStatusNotifier;
    expect(notifier.logoutCalled, isTrue);
    expect(notifier.lastNotifyBackend, isFalse);
  });
}

class _FakeAuthStatusNotifier extends AuthStatusNotifier {
  bool refreshCalled = false;
  bool logoutCalled = false;
  bool? lastNotifyBackend;

  @override
  AuthStatus build() => AuthStatus.sessionRecoveryRequired;

  @override
  Future<void> refreshAuthStatus() async {
    refreshCalled = true;
  }

  @override
  Future<void> logout({bool notifyBackend = true}) async {
    logoutCalled = true;
    lastNotifyBackend = notifyBackend;
    state = AuthStatus.unauthenticated;
  }
}
