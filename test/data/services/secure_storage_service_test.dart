import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zola/data/services/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late Map<String, String> storage;

  setUp(() {
    storage = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          final arguments =
              (methodCall.arguments as Map?)?.cast<String, dynamic>() ??
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
                message:
                    'Method ${methodCall.method} is not implemented in test',
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

    test('writeValue overrides existing keys', () async {
      final service = SecureStorageService();
      await service.writeValue(key: 'k1', value: 'v1');
      await service.writeValue(key: 'k1', value: 'v2');
      expect(await service.readValue('k1'), 'v2');
    });

    test('readValue returns null for missing key', () async {
      final service = SecureStorageService();
      expect(await service.readValue('missing'), isNull);
    });
  });
}
