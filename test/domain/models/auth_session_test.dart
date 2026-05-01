import 'package:flutter_test/flutter_test.dart';
import 'package:zola/domain/models/auth_session.dart';

void main() {
  group('AuthSession', () {
    test('toStorageMap serializes all fields to string values', () {
      final receivedAt = DateTime.utc(2026, 1, 1, 10, 0, 0);
      final expiresAt = DateTime.utc(2026, 1, 8, 10, 0, 0);
      final session = AuthSession(
        token: 'token-123',
        receivedAt: receivedAt,
        expiresAt: expiresAt,
      );

      final result = session.toStorageMap();

      expect(result, <String, String>{
        'token': 'token-123',
        'receivedAt': receivedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      });
    });

    test('fromStorageMap returns session when map is valid', () {
      final receivedAt = DateTime.utc(2026, 2, 1, 8, 30, 0);
      final expiresAt = DateTime.utc(2026, 2, 8, 8, 30, 0);

      final result = AuthSession.fromStorageMap({
        'token': 'abc',
        'receivedAt': receivedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      });

      expect(result, isNotNull);
      expect(result!.token, 'abc');
      expect(result.receivedAt, receivedAt);
      expect(result.expiresAt, expiresAt);
    });

    test('fromStorageMap returns null for missing required keys', () {
      final result = AuthSession.fromStorageMap({
        'token': 'abc',
        'receivedAt': DateTime.utc(2026, 2, 1).toIso8601String(),
      });

      expect(result, isNull);
    });

    test('fromStorageMap returns null for invalid datetime values', () {
      final result = AuthSession.fromStorageMap({
        'token': 'abc',
        'receivedAt': 'invalid-date',
        'expiresAt': DateTime.utc(2026, 2, 8).toIso8601String(),
      });

      expect(result, isNull);
    });

    test('isExpired returns false when expiration is in the future', () {
      final session = AuthSession(
        token: 'future-token',
        receivedAt: DateTime.now().subtract(const Duration(minutes: 1)),
        expiresAt: DateTime.now().add(const Duration(minutes: 1)),
      );

      expect(session.isExpired, isFalse);
    });

    test('isExpired returns true when expiration is in the past', () {
      final session = AuthSession(
        token: 'past-token',
        receivedAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(session.isExpired, isTrue);
    });

    test('isExpired returns true at boundary when expiresAt is now', () async {
      final now = DateTime.now();
      final session = AuthSession(
        token: 'boundary-token',
        receivedAt: now.subtract(const Duration(minutes: 1)),
        expiresAt: now,
      );

      await Future<void>.delayed(const Duration(milliseconds: 1));
      expect(session.isExpired, isTrue);
    });

    test('isExpired handles near-boundary values consistently', () async {
      final baseNow = DateTime.now();
      final almostExpired = AuthSession(
        token: 'almost-expired',
        receivedAt: baseNow.subtract(const Duration(minutes: 1)),
        expiresAt: baseNow.add(const Duration(milliseconds: 2)),
      );
      final justExpired = AuthSession(
        token: 'just-expired',
        receivedAt: baseNow.subtract(const Duration(minutes: 1)),
        expiresAt: baseNow.subtract(const Duration(milliseconds: 2)),
      );

      expect(justExpired.isExpired, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 3));
      expect(almostExpired.isExpired, isTrue);
    });
  });
}
