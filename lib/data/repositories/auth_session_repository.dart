import 'dart:convert';

import 'package:zola/data/services/auth_token_provider.dart';
import 'package:zola/data/services/secure_storage_service.dart';
import 'package:zola/domain/models/auth_session.dart';
import 'package:zola/domain/models/auth_user.dart';

class AuthSessionRepository implements AuthTokenProvider {
  AuthSessionRepository({required SecureStorageService secureStorageService})
    : _secureStorageService = secureStorageService;

  static const Duration defaultSessionTtl = Duration(days: 7);
  static const String _tokenKey = 'auth.token';
  static const String _receivedAtKey = 'auth.receivedAt';
  static const String _expiresAtKey = 'auth.expiresAt';
  static const String _userKey = 'auth.user';
  static const String _lastLoginMethodKey = 'auth.lastLoginMethod';

  final SecureStorageService _secureStorageService;

  Future<AuthSession> saveToken(
    String token, {
    Duration ttl = defaultSessionTtl,
  }) async {
    final receivedAt = DateTime.now().toUtc();
    final expiresAt = receivedAt.add(ttl);
    return saveSession(token: token, expiresAt: expiresAt, receivedAt: receivedAt);
  }

  Future<AuthSession> saveSession({
    required String token,
    required DateTime expiresAt,
    DateTime? receivedAt,
  }) async {
    final normalizedReceivedAt = (receivedAt ?? DateTime.now().toUtc()).toUtc();
    final normalizedExpiresAt = expiresAt.toUtc();
    final session = AuthSession(
      token: token,
      receivedAt: normalizedReceivedAt,
      expiresAt: normalizedExpiresAt,
    );
    final storageMap = session.toStorageMap();
    await _secureStorageService.writeValue(
      key: _tokenKey,
      value: storageMap['token']!,
    );
    await _secureStorageService.writeValue(
      key: _receivedAtKey,
      value: storageMap['receivedAt']!,
    );
    await _secureStorageService.writeValue(
      key: _expiresAtKey,
      value: storageMap['expiresAt']!,
    );
    return session;
  }

  Future<AuthSession?> getSession() async {
    final token = await _secureStorageService.readValue(_tokenKey);
    final receivedAt = await _secureStorageService.readValue(_receivedAtKey);
    final expiresAt = await _secureStorageService.readValue(_expiresAtKey);
    if (token == null || receivedAt == null || expiresAt == null) {
      return null;
    }
    return AuthSession.fromStorageMap({
      'token': token,
      'receivedAt': receivedAt,
      'expiresAt': expiresAt,
    });
  }

  @override
  Future<String?> getValidToken() {
    return _getValidTokenInternal();
  }

  Future<String?> _getValidTokenInternal() async {
    final session = await getSession();
    if (session == null) {
      // Fail-safe: if session artifacts exist but cannot be parsed, clear them.
      if (await _hasSessionArtifacts()) {
        await clearSession();
      }
      return null;
    }
    if (session.isExpired) {
      await clearSession();
      return null;
    }
    return session.token;
  }

  Future<bool> _hasSessionArtifacts() async {
    final token = await _secureStorageService.readValue(_tokenKey);
    final receivedAt = await _secureStorageService.readValue(_receivedAtKey);
    final expiresAt = await _secureStorageService.readValue(_expiresAtKey);
    return token != null || receivedAt != null || expiresAt != null;
  }

  Future<void> saveUser(AuthUser user) async {
    await _secureStorageService.writeValue(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<AuthUser?> getUser() async {
    final raw = await _secureStorageService.readValue(_userKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return AuthUser.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUser() async {
    await _secureStorageService.deleteValue(_userKey);
  }

  Future<void> saveLastLoginMethod(String method) async {
    if (method.isEmpty) {
      return;
    }
    await _secureStorageService.writeValue(
      key: _lastLoginMethodKey,
      value: method,
    );
  }

  Future<String?> getLastLoginMethod() {
    return _secureStorageService.readValue(_lastLoginMethodKey);
  }

  Future<void> clearLastLoginMethod() {
    return _secureStorageService.deleteValue(_lastLoginMethodKey);
  }

  Future<void> clearSession() async {
    await _secureStorageService.deleteValue(_tokenKey);
    await _secureStorageService.deleteValue(_receivedAtKey);
    await _secureStorageService.deleteValue(_expiresAtKey);
    await _secureStorageService.deleteValue(_userKey);
  }
}
