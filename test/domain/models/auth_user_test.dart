import 'package:flutter_test/flutter_test.dart';
import 'package:zola/domain/models/auth_user.dart';

void main() {
  group('AuthUser', () {
    test('fromJson maps all supported fields', () {
      final result = AuthUser.fromJson({
        'id': 'u_1',
        'name': 'Alice',
        'email': 'alice@example.com',
        'emailVerified': true,
        'image': 'https://example.com/avatar.png',
        'createdAt': '2026-05-01T10:00:00.000Z',
        'updatedAt': '2026-05-01T10:30:00.000Z',
        'lastLoginMethod': 'google',
        'role': 'admin',
        'banned': false,
        'banReason': 'none',
        'banExpires': '2026-05-02T00:00:00.000Z',
      });

      expect(result, isNotNull);
      expect(result!.id, 'u_1');
      expect(result.name, 'Alice');
      expect(result.email, 'alice@example.com');
      expect(result.emailVerified, isTrue);
      expect(result.image, 'https://example.com/avatar.png');
      expect(result.createdAt, '2026-05-01T10:00:00.000Z');
      expect(result.updatedAt, '2026-05-01T10:30:00.000Z');
      expect(result.lastLoginMethod, 'google');
      expect(result.role, 'admin');
      expect(result.banned, isFalse);
      expect(result.banReason, 'none');
      expect(result.banExpires, '2026-05-02T00:00:00.000Z');
    });

    test('fromJson keeps backward compatibility with old payloads', () {
      final result = AuthUser.fromJson({
        'id': 'u_2',
        'name': 'Bob',
        'email': 'bob@example.com',
        'emailVerified': false,
      });

      expect(result, isNotNull);
      expect(result!.role, isNull);
      expect(result.lastLoginMethod, isNull);
      expect(result.banned, isFalse);
      expect(result.banReason, isNull);
      expect(result.banExpires, isNull);
    });

    test('toJson serializes new fields', () {
      final user = AuthUser(
        id: 'u_3',
        name: 'Carol',
        email: 'carol@example.com',
        emailVerified: true,
        role: 'user',
        banned: true,
        banReason: 'policy violation',
        banExpires: '2026-06-01T00:00:00.000Z',
        lastLoginMethod: 'oauth',
      );

      final json = user.toJson();

      expect(json['lastLoginMethod'], 'oauth');
      expect(json['role'], 'user');
      expect(json['banned'], isTrue);
      expect(json['banReason'], 'policy violation');
      expect(json['banExpires'], '2026-06-01T00:00:00.000Z');
    });

    test('fromJson maps last_login_method when lastLoginMethod absent', () {
      final result = AuthUser.fromJson({
        'id': 'u_snake',
        'name': 'Snake',
        'email': 'snake@example.com',
        'emailVerified': false,
        'last_login_method': 'email',
      });

      expect(result, isNotNull);
      expect(result!.lastLoginMethod, 'email');
    });

    test('fromJson returns null for missing required fields', () {
      final result = AuthUser.fromJson({
        'id': 'u_4',
        'name': 'No Email',
      });

      expect(result, isNull);
    });
  });
}
