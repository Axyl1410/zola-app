import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_view_model.dart';
import 'package:zola/ui/features/auth/views/auth_required_view.dart';
import 'package:zola/ui/features/auth/views/banned_view.dart';
import 'package:zola/ui/features/auth/views/login_view.dart';
import 'package:zola/ui/features/home/views/home_view.dart';

void main() {
  testWidgets('App routes to LoginView when unauthenticated', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStatusNotifierProvider.overrideWith(
            () => _FakeAuthStatusNotifier(AuthStatus.unauthenticated),
          ),
        ],
        child: const _AuthRouteHost(),
      ),
    );
    await tester.pump();

    expect(find.byType(LoginView), findsOneWidget);
  });

  testWidgets('App routes to HomeView when authenticated', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStatusNotifierProvider.overrideWith(
            () => _FakeAuthStatusNotifier(AuthStatus.authenticated),
          ),
        ],
        child: const _AuthRouteHost(),
      ),
    );
    await tester.pump();

    expect(find.byType(HomeView), findsOneWidget);
  });

  testWidgets('App routes to BannedView when banned', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStatusNotifierProvider.overrideWith(
            () => _FakeAuthStatusNotifier(AuthStatus.banned),
          ),
        ],
        child: const _AuthRouteHost(),
      ),
    );
    await tester.pump();

    expect(find.byType(BannedView), findsOneWidget);
  });

  testWidgets('App shows loading view while checking', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStatusNotifierProvider.overrideWith(
            () => _FakeAuthStatusNotifier(AuthStatus.checking),
          ),
        ],
        child: const _AuthRouteHost(),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('App routes to AuthRequiredView when recovery is required', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStatusNotifierProvider.overrideWith(
            () => _FakeAuthStatusNotifier(AuthStatus.sessionRecoveryRequired),
          ),
        ],
        child: const _AuthRouteHost(),
      ),
    );
    await tester.pump();

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
        child: const _AuthRouteHost(),
      ),
    );
    await tester.pump();
    expect(find.byType(AuthRequiredView), findsOneWidget);

    final notifier = container.read(authStatusNotifierProvider.notifier)
        as _FakeAuthStatusNotifier;
    notifier.setStatus(AuthStatus.authenticated);
    await tester.pump();

    expect(find.byType(HomeView), findsOneWidget);
  });
}

class _AuthRouteHost extends ConsumerWidget {
  const _AuthRouteHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authStatusNotifierProvider);
    return MaterialApp(
      home: switch (authStatus) {
        AuthStatus.checking => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        AuthStatus.sessionRecoveryRequired => const AuthRequiredView(),
        AuthStatus.authenticated => const HomeView(),
        AuthStatus.banned => const BannedView(),
        AuthStatus.unauthenticated => const LoginView(),
      },
    );
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
