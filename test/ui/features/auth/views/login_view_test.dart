import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zola/ui/features/auth/view_models/login_providers.dart';
import 'package:zola/ui/features/auth/views/login_view.dart';

void main() {
  group('LoginView highlight', () {
    testWidgets('shows caption when lastLoginMethod is google', (tester) async {
      final container = ProviderContainer(
        overrides: [
          lastLoginMethodProvider.overrideWith(
            (ref) => Future<String?>.value('google'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LoginView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lần trước bạn đăng nhập bằng Google'), findsOneWidget);
    });

    testWidgets('hides caption when lastLoginMethod is null', (tester) async {
      final container = ProviderContainer(
        overrides: [
          lastLoginMethodProvider.overrideWith(
            (ref) => Future<String?>.value(null),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LoginView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lần trước bạn đăng nhập bằng Google'), findsNothing);
    });

    testWidgets('hides caption when lastLoginMethod is a different method', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          lastLoginMethodProvider.overrideWith(
            (ref) => Future<String?>.value('email-password'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LoginView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lần trước bạn đăng nhập bằng Google'), findsNothing);
    });
  });
}
