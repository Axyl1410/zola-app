// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:zola/main.dart';
import 'di/test_injector.dart';

void main() {
  setUp(() async {
    await setupTestDependencies();
  });

  tearDown(() async {
    await resetTestDependencies();
  });

  testWidgets('App renders home search UI', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(App());
    await tester.pumpAndSettle();

    expect(find.text('Tìm kiếm'), findsOneWidget);
    expect(find.text('hello world'), findsOneWidget);
  });
}
