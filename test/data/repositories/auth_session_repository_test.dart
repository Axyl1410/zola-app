import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zola/data/repositories/auth_session_repository.dart';
import 'package:zola/data/services/secure_storage_service.dart';
import 'package:zola/domain/models/auth_session.dart';
import 'package:zola/domain/models/auth_user.dart';

void main() {
  group('AuthSessionRepository', () {
    late _FakeSecureStorageService fakeService;
    late AuthSessionRepository repository;

    setUp(() {
      fakeService = _FakeSecureStorageService();
      repository = AuthSessionRepository(secureStorageService: fakeService);
    });

    test('saveToken persists token and computes expiry from ttl', () async {
      const ttl = Duration(hours: 4);
      final beforeCall = DateTime.now().toUtc();

      final result = await repository.saveToken('repo-token', ttl: ttl);

      final afterCall = DateTime.now().toUtc();
      expect(result.token, 'repo-token');
      expect(result.expiresAt.difference(result.receivedAt), ttl);
      expect(fakeService.storage['auth.token'], 'repo-token');
      expect(
        fakeService.storage['auth.receivedAt'],
        result.receivedAt.toIso8601String(),
      );
      expect(
        fakeService.storage['auth.expiresAt'],
        result.expiresAt.toIso8601String(),
      );
      expect(
        result.receivedAt.isAfter(beforeCall) ||
            result.receivedAt.isAtSameMomentAs(beforeCall),
        isTrue,
      );
      expect(
        result.receivedAt.isBefore(afterCall) ||
            result.receivedAt.isAtSameMomentAs(afterCall),
        isTrue,
      );
    });

    test('saveToken uses repository default ttl when omitted', () async {
      final result = await repository.saveToken('repo-token');

      expect(
        result.expiresAt.difference(result.receivedAt),
        AuthSessionRepository.defaultSessionTtl,
      );
      expect(result.token, 'repo-token');
    });

    test('saveSession delegates token and expiry to service', () async {
      final expiresAt = DateTime.utc(2026, 5, 3, 0, 0, 0);
      final receivedAt = DateTime.utc(2026, 5, 1, 0, 0, 0);

      final result = await repository.saveSession(
        token: 'server-token',
        expiresAt: expiresAt,
        receivedAt: receivedAt,
      );

      expect(fakeService.storage['auth.token'], 'server-token');
      expect(
        fakeService.storage['auth.receivedAt'],
        receivedAt.toIso8601String(),
      );
      expect(
        fakeService.storage['auth.expiresAt'],
        expiresAt.toIso8601String(),
      );
      expect(result.token, 'server-token');
      expect(result.expiresAt, expiresAt);
    });

    test('getSession delegates and returns service result', () async {
      final expected = AuthSession(
        token: 'session-token',
        receivedAt: DateTime.utc(2026, 3, 1),
        expiresAt: DateTime.utc(2026, 3, 8),
      );
      fakeService.storage['auth.token'] = expected.token;
      fakeService.storage['auth.receivedAt'] = expected.receivedAt
          .toIso8601String();
      fakeService.storage['auth.expiresAt'] = expected.expiresAt
          .toIso8601String();

      final result = await repository.getSession();

      expect(result, isNotNull);
      expect(result!.token, expected.token);
      expect(result.receivedAt, expected.receivedAt);
      expect(result.expiresAt, expected.expiresAt);
    });

    test('getValidToken returns token when session is not expired', () async {
      final now = DateTime.now().toUtc();
      fakeService.storage['auth.token'] = 'valid-token';
      fakeService.storage['auth.receivedAt'] = now
          .subtract(const Duration(minutes: 5))
          .toIso8601String();
      fakeService.storage['auth.expiresAt'] = now
          .add(const Duration(minutes: 5))
          .toIso8601String();

      final result = await repository.getValidToken();

      expect(result, 'valid-token');
    });

    test('getValidToken clears expired session', () async {
      final now = DateTime.now().toUtc();
      fakeService.storage['auth.token'] = 'expired-token';
      fakeService.storage['auth.receivedAt'] = now
          .subtract(const Duration(days: 2))
          .toIso8601String();
      fakeService.storage['auth.expiresAt'] = now
          .subtract(const Duration(days: 1))
          .toIso8601String();

      final result = await repository.getValidToken();

      expect(result, isNull);
      expect(fakeService.storage.containsKey('auth.token'), isFalse);
      expect(fakeService.storage.containsKey('auth.receivedAt'), isFalse);
      expect(fakeService.storage.containsKey('auth.expiresAt'), isFalse);
      expect(fakeService.storage.containsKey('auth.user'), isFalse);
    });

    test('saveUser/getUser roundtrip and clearUser works', () async {
      const user = AuthUser(
        id: 'u_1',
        name: 'Test User',
        email: 'test@zola.app',
        emailVerified: true,
        lastLoginMethod: 'google',
      );

      await repository.saveUser(user);
      final loaded = await repository.getUser();
      expect(loaded?.id, user.id);
      expect(loaded?.email, user.email);
      expect(loaded?.lastLoginMethod, 'google');

      await repository.clearUser();
      expect(await repository.getUser(), isNull);
    });

    test('getUser returns null for corrupted user json', () async {
      fakeService.storage['auth.user'] = '{bad json';
      expect(await repository.getUser(), isNull);
    });

    test('getUser returns null for non-map user json', () async {
      fakeService.storage['auth.user'] = '["x"]';
      expect(await repository.getUser(), isNull);
    });

    test('getSession returns null for corrupted session fields', () async {
      fakeService.storage['auth.token'] = 'token-123';
      fakeService.storage['auth.receivedAt'] = 'not-a-date';
      fakeService.storage['auth.expiresAt'] = 'also-not-a-date';

      final session = await repository.getSession();
      expect(session, isNull);
    });

    test('getValidToken fails safe for corrupted session fields', () async {
      fakeService.storage['auth.token'] = 'token-123';
      fakeService.storage['auth.receivedAt'] = 'broken';
      fakeService.storage['auth.expiresAt'] = 'broken';
      fakeService.storage['auth.user'] = '{"id":"u_1"}';

      final token = await repository.getValidToken();

      expect(token, isNull);
      expect(fakeService.storage.containsKey('auth.token'), isFalse);
      expect(fakeService.storage.containsKey('auth.receivedAt'), isFalse);
      expect(fakeService.storage.containsKey('auth.expiresAt'), isFalse);
      expect(fakeService.storage.containsKey('auth.user'), isFalse);
    });

    test('clearSession deletes auth and user fields', () async {
      fakeService.storage['auth.token'] = 'x';
      fakeService.storage['auth.receivedAt'] = 'y';
      fakeService.storage['auth.expiresAt'] = 'z';
      fakeService.storage['auth.user'] = '{}';

      await repository.clearSession();

      expect(fakeService.storage, isEmpty);
    });

    group('lastLoginMethod', () {
      test('saveLastLoginMethod writes value to storage', () async {
        await repository.saveLastLoginMethod('google');
        expect(fakeService.storage['auth.lastLoginMethod'], 'google');
      });

      test('saveLastLoginMethod is a no-op for empty string', () async {
        await repository.saveLastLoginMethod('');
        expect(
          fakeService.storage.containsKey('auth.lastLoginMethod'),
          isFalse,
        );
      });

      test('getLastLoginMethod returns saved value or null', () async {
        expect(await repository.getLastLoginMethod(), isNull);

        await repository.saveLastLoginMethod('google');
        expect(await repository.getLastLoginMethod(), 'google');
      });

      test('saveLastLoginMethod overrides previous value', () async {
        await repository.saveLastLoginMethod('google');
        await repository.saveLastLoginMethod('email-password');

        expect(await repository.getLastLoginMethod(), 'email-password');
      });

      test('clearSession does NOT remove lastLoginMethod', () async {
        await repository.saveLastLoginMethod('google');
        fakeService.storage['auth.token'] = 'x';
        fakeService.storage['auth.receivedAt'] = 'y';
        fakeService.storage['auth.expiresAt'] = 'z';
        fakeService.storage['auth.user'] = '{}';

        await repository.clearSession();

        expect(fakeService.storage['auth.lastLoginMethod'], 'google');
      });

      test('clearLastLoginMethod removes the key', () async {
        await repository.saveLastLoginMethod('google');

        await repository.clearLastLoginMethod();

        expect(
          fakeService.storage.containsKey('auth.lastLoginMethod'),
          isFalse,
        );
      });
    });
  });
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService() : super(storage: const FlutterSecureStorage());

  final Map<String, String> storage = <String, String>{};

  @override
  Future<void> writeValue({required String key, required String value}) async {
    storage[key] = value;
  }

  @override
  Future<String?> readValue(String key) async {
    return storage[key];
  }

  @override
  Future<void> deleteValue(String key) async {
    storage.remove(key);
  }

  @override
  Future<Map<String, String>> readAll() async {
    return Map<String, String>.from(storage);
  }
}
