import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teamo/data/services/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late Map<String, String> storage;

  setUp(() {
    storage = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          final arguments = (methodCall.arguments as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};

          switch (methodCall.method) {
            case 'write':
              final key = arguments['key'] as String;
              final value = arguments['value'] as String;
              storage[key] = value;
              return null;
            case 'read':
              final key = arguments['key'] as String;
              return storage[key];
            case 'delete':
              final key = arguments['key'] as String;
              storage.remove(key);
              return null;
            case 'readAll':
              return Map<String, String>.from(storage);
            case 'deleteAll':
              storage.clear();
              return null;
            default:
              throw PlatformException(
                code: 'unimplemented',
                message: 'Method ${methodCall.method} is not implemented in test',
              );
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('SecureStorageService', () {
    test('writeValue and readValue store and retrieve values', () async {
      final service = SecureStorageService();

      await service.writeValue(key: 'k1', value: 'v1');
      final value = await service.readValue('k1');

      expect(value, 'v1');
    });

    test('deleteValue removes a stored value', () async {
      final service = SecureStorageService();
      await service.writeValue(key: 'k1', value: 'v1');

      await service.deleteValue('k1');

      expect(await service.readValue('k1'), isNull);
    });

    test('readAll returns all entries and clearAll clears them', () async {
      final service = SecureStorageService();
      await service.writeValue(key: 'k1', value: 'v1');
      await service.writeValue(key: 'k2', value: 'v2');

      final beforeClear = await service.readAll();
      await service.clearAll();
      final afterClear = await service.readAll();

      expect(beforeClear, {'k1': 'v1', 'k2': 'v2'});
      expect(afterClear, isEmpty);
    });

    test('saveSessionToken writes token and timestamps', () async {
      final service = SecureStorageService();
      const ttl = Duration(hours: 12);

      final session = await service.saveSessionToken('my-token', ttl: ttl);

      expect(session.token, 'my-token');
      expect(session.expiresAt.difference(session.receivedAt), ttl);
      expect(storage['auth.token'], 'my-token');
      expect(storage['auth.receivedAt'], session.receivedAt.toIso8601String());
      expect(storage['auth.expiresAt'], session.expiresAt.toIso8601String());
    });

    test('getSession returns null when any session field is missing', () async {
      final service = SecureStorageService();
      storage['auth.token'] = 'token-only';

      final session = await service.getSession();

      expect(session, isNull);
    });

    test('getSession returns parsed session for valid stored values', () async {
      final service = SecureStorageService();
      final receivedAt = DateTime.utc(2026, 1, 1, 10, 0, 0);
      final expiresAt = DateTime.utc(2026, 1, 2, 10, 0, 0);
      storage['auth.token'] = 'abc';
      storage['auth.receivedAt'] = receivedAt.toIso8601String();
      storage['auth.expiresAt'] = expiresAt.toIso8601String();

      final session = await service.getSession();

      expect(session, isNotNull);
      expect(session!.token, 'abc');
      expect(session.receivedAt, receivedAt);
      expect(session.expiresAt, expiresAt);
    });

    test('getValidToken returns token for non-expired session', () async {
      final service = SecureStorageService();
      final now = DateTime.now().toUtc();
      storage['auth.token'] = 'valid-token';
      storage['auth.receivedAt'] =
          now.subtract(const Duration(minutes: 5)).toIso8601String();
      storage['auth.expiresAt'] =
          now.add(const Duration(minutes: 5)).toIso8601String();

      final token = await service.getValidToken();

      expect(token, 'valid-token');
      expect(storage['auth.token'], 'valid-token');
    });

    test('getValidToken clears session and returns null when expired', () async {
      final service = SecureStorageService();
      final now = DateTime.now().toUtc();
      storage['auth.token'] = 'expired-token';
      storage['auth.receivedAt'] =
          now.subtract(const Duration(days: 2)).toIso8601String();
      storage['auth.expiresAt'] =
          now.subtract(const Duration(days: 1)).toIso8601String();

      final token = await service.getValidToken();

      expect(token, isNull);
      expect(storage.containsKey('auth.token'), isFalse);
      expect(storage.containsKey('auth.receivedAt'), isFalse);
      expect(storage.containsKey('auth.expiresAt'), isFalse);
    });

    test(
      'getValidToken returns null and clears session for zero ttl session',
      () async {
        final service = SecureStorageService();
        await service.saveSessionToken('zero-ttl-token', ttl: Duration.zero);
        await Future<void>.delayed(const Duration(milliseconds: 1));

        final token = await service.getValidToken();

        expect(token, isNull);
        expect(storage.containsKey('auth.token'), isFalse);
        expect(storage.containsKey('auth.receivedAt'), isFalse);
        expect(storage.containsKey('auth.expiresAt'), isFalse);
      },
    );

    test('clearSession deletes all auth-related fields', () async {
      final service = SecureStorageService();
      storage['auth.token'] = 'x';
      storage['auth.receivedAt'] = 'y';
      storage['auth.expiresAt'] = 'z';

      await service.clearSession();

      expect(storage, isEmpty);
    });
  });
}
