import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zola/data/repositories/auth_session_repository.dart';
import 'package:zola/data/services/secure_storage_service.dart';
import 'package:zola/domain/models/auth_session.dart';

void main() {
  group('AuthSessionRepository', () {
    late _FakeSecureStorageService fakeService;
    late AuthSessionRepository repository;

    setUp(() {
      fakeService = _FakeSecureStorageService();
      repository = AuthSessionRepository(secureStorageService: fakeService);
    });

    test('saveToken delegates token and ttl to service', () async {
      const ttl = Duration(hours: 4);

      final result = await repository.saveToken('repo-token', ttl: ttl);

      expect(fakeService.saveTokenCalls, 1);
      expect(fakeService.lastSavedToken, 'repo-token');
      expect(fakeService.lastSavedTtl, ttl);
      expect(result.token, 'repo-token');
    });

    test('getSession delegates and returns service result', () async {
      final expected = AuthSession(
        token: 'session-token',
        receivedAt: DateTime.utc(2026, 3, 1),
        expiresAt: DateTime.utc(2026, 3, 8),
      );
      fakeService.sessionToReturn = expected;

      final result = await repository.getSession();

      expect(fakeService.getSessionCalls, 1);
      expect(result, expected);
    });

    test('getValidToken delegates and returns service token', () async {
      fakeService.validTokenToReturn = 'valid-token';

      final result = await repository.getValidToken();

      expect(fakeService.getValidTokenCalls, 1);
      expect(result, 'valid-token');
    });

    test('clearSession delegates to service', () async {
      await repository.clearSession();

      expect(fakeService.clearSessionCalls, 1);
    });
  });
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService() : super(storage: const FlutterSecureStorage());

  int saveTokenCalls = 0;
  int getSessionCalls = 0;
  int getValidTokenCalls = 0;
  int clearSessionCalls = 0;

  String? lastSavedToken;
  Duration? lastSavedTtl;
  AuthSession? sessionToReturn;
  String? validTokenToReturn;

  @override
  Future<AuthSession> saveSessionToken(
    String token, {
    Duration ttl = SecureStorageService.defaultSessionTtl,
  }) async {
    saveTokenCalls++;
    lastSavedToken = token;
    lastSavedTtl = ttl;
    return AuthSession(
      token: token,
      receivedAt: DateTime.utc(2026, 1, 1),
      expiresAt: DateTime.utc(2026, 1, 1).add(ttl),
    );
  }

  @override
  Future<AuthSession?> getSession() async {
    getSessionCalls++;
    return sessionToReturn;
  }

  @override
  Future<String?> getValidToken() async {
    getValidTokenCalls++;
    return validTokenToReturn;
  }

  @override
  Future<void> clearSession() async {
    clearSessionCalls++;
  }
}
