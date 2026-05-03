import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_view_model.dart';
import 'package:zola/ui/features/auth/views/auth_required_view.dart';
import 'package:zola/ui/features/auth/views/banned_view.dart';
import 'package:zola/ui/features/auth/views/login_view.dart';
import 'package:zola/ui/features/home/views/home_view.dart';
import 'package:zola/ui/routing/app_router.dart';

void main() {
  testWidgets('App routes to LoginView when unauthenticated', (
    WidgetTester tester,
  ) async {
    await _pumpAppWithAuth(tester, AuthStatus.unauthenticated);

    expect(find.byType(LoginView), findsOneWidget);
  });

  testWidgets('App routes to HomeView when authenticated', (
    WidgetTester tester,
  ) async {
    await _pumpAppWithAuth(tester, AuthStatus.authenticated);

    expect(find.byType(HomeView), findsOneWidget);
  });

  testWidgets('App routes to BannedView when banned', (
    WidgetTester tester,
  ) async {
    await _pumpAppWithAuth(tester, AuthStatus.banned);

    expect(find.byType(BannedView), findsOneWidget);
  });

  testWidgets('App shows loading view while checking', (
    WidgetTester tester,
  ) async {
    await _pumpAppWithAuth(tester, AuthStatus.checking);

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('App routes to AuthRequiredView when recovery is required', (
    WidgetTester tester,
  ) async {
    await _pumpAppWithAuth(tester, AuthStatus.sessionRecoveryRequired);

    expect(find.byType(AuthRequiredView), findsOneWidget);
  });

  testWidgets('App route transitions from recovery to authenticated', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authStatusNotifierProvider.overrideWith(
          () => _FakeAuthStatusNotifier(AuthStatus.sessionRecoveryRequired),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _AuthRouterHost(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(AuthRequiredView), findsOneWidget);

    final notifier =
        container.read(authStatusNotifierProvider.notifier)
            as _FakeAuthStatusNotifier;
    notifier.setStatus(AuthStatus.authenticated);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(HomeView), findsOneWidget);
  });
}

Future<void> _pumpAppWithAuth(
  WidgetTester tester,
  AuthStatus status,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStatusNotifierProvider.overrideWith(
          () => _FakeAuthStatusNotifier(status),
        ),
      ],
      child: const _AuthRouterHost(),
    ),
  );
  // Let GoRouter resolve the initial redirect. Avoid pumpAndSettle because
  // BannedView and the loading view contain indeterminate animations.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

class _AuthRouterHost extends ConsumerWidget {
  const _AuthRouterHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(routerConfig: ref.watch(appRouterProvider));
  }
}

class _FakeAuthStatusNotifier extends AuthStatusNotifier {
  _FakeAuthStatusNotifier(this.initialStatus);

  final AuthStatus initialStatus;

  @override
  AuthStatus build() => initialStatus;

  @override
  Future<void> enableSessionGuard() async {}

  void setStatus(AuthStatus next) {
    state = next;
  }
}
