import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zola/domain/models/auth_user.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_view_model.dart';
import 'package:zola/ui/features/auth/view_models/current_user_provider.dart';
import 'package:zola/ui/features/auth/views/banned_view.dart';

void main() {
  testWidgets('BannedView shows reason, formatted time, and logout works', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(
          (ref) => Future<AuthUser?>.value(
            const AuthUser(
              id: 'u_1',
              name: 'Banned User',
              email: 'banned@zola.app',
              emailVerified: true,
              banned: true,
              banReason: 'Vi phạm điều khoản',
              banExpires: '2026-05-01T22:15:00',
            ),
          ),
        ),
        authStatusNotifierProvider.overrideWith(
          () => _FakeAuthStatusNotifier(AuthStatus.banned),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BannedView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tài khoản đã bị khóa'), findsOneWidget);
    expect(find.text('Lý do'), findsOneWidget);
    expect(find.text('Vi phạm điều khoản'), findsOneWidget);
    expect(find.text('01/05/2026 22:15'), findsOneWidget);

    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    final notifier =
        container.read(authStatusNotifierProvider.notifier)
            as _FakeAuthStatusNotifier;
    expect(notifier.logoutCalled, isTrue);
  });
}

class _FakeAuthStatusNotifier extends AuthStatusNotifier {
  _FakeAuthStatusNotifier(this.initialStatus);

  final AuthStatus initialStatus;
  bool logoutCalled = false;

  @override
  AuthStatus build() => initialStatus;

  @override
  Future<void> enableSessionGuard() async {}

  @override
  Future<void> disableSessionGuard() async {}

  @override
  Future<void> onAppResumed() async {}

  @override
  Future<void> logout({bool notifyBackend = true}) async {
    logoutCalled = true;
    state = AuthStatus.unauthenticated;
  }
}
