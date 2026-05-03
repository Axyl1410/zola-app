import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zola/domain/models/auth_user.dart';
import 'package:zola/ui/features/admin/views/screens/admin_screen.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_view_model.dart';
import 'package:zola/ui/features/auth/view_models/current_user_provider.dart';

void main() {
  testWidgets('AdminScreen does not force logout for banned outcome', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authStatusNotifierProvider.overrideWith(
          () => _FakeAuthStatusNotifier(SessionValidationOutcome.banned),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = _buildTestRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final notifier =
        container.read(authStatusNotifierProvider.notifier)
            as _FakeAuthStatusNotifier;
    expect(notifier.logoutCalled, isFalse);
    expect(_currentLocation(router), '/admin');
  });

  testWidgets('AdminScreen redirects non-admin user to personal screen', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(
          (ref) => Future<AuthUser?>.value(
            const AuthUser(
              id: 'u_user',
              name: 'Normal User',
              email: 'user@zola.app',
              emailVerified: true,
              role: 'user',
            ),
          ),
        ),
        authStatusNotifierProvider.overrideWith(
          () => _FakeAuthStatusNotifier(SessionValidationOutcome.active),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = _buildTestRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final notifier =
        container.read(authStatusNotifierProvider.notifier)
            as _FakeAuthStatusNotifier;
    expect(notifier.logoutCalled, isFalse);
    expect(_currentLocation(router), '/home/personal');
    expect(find.byType(_PersonalPlaceholder), findsOneWidget);
  });

  testWidgets(
    'AdminScreen redirects to personal screen on transient failure',
    (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authStatusNotifierProvider.overrideWith(
            () => _FakeAuthStatusNotifier(
              SessionValidationOutcome.transientFailure,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = _buildTestRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      final notifier =
          container.read(authStatusNotifierProvider.notifier)
              as _FakeAuthStatusNotifier;
      expect(notifier.logoutCalled, isFalse);
      expect(_currentLocation(router), '/home/personal');
      expect(find.byType(_PersonalPlaceholder), findsOneWidget);
    },
  );
}

GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/admin',
    routes: [
      GoRoute(path: '/admin', builder: (_, _) => const AdminScreen()),
      GoRoute(
        path: '/home/personal',
        builder: (_, _) => const _PersonalPlaceholder(),
      ),
    ],
  );
}

String _currentLocation(GoRouter router) {
  return router.routerDelegate.currentConfiguration.uri.toString();
}

class _PersonalPlaceholder extends StatelessWidget {
  const _PersonalPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('personal-placeholder')));
  }
}

class _FakeAuthStatusNotifier extends AuthStatusNotifier {
  _FakeAuthStatusNotifier(this.outcome);

  final SessionValidationOutcome outcome;
  bool logoutCalled = false;

  @override
  AuthStatus build() => AuthStatus.authenticated;

  @override
  Future<SessionValidationOutcome> validateSessionForCriticalAction() async {
    return outcome;
  }

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
