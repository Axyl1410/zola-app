import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zola/domain/models/auth_session.dart';
import 'package:zola/domain/models/auth_user.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? _defaultStorage;

  static const Duration defaultSessionTtl = Duration(days: 7);

  static const _tokenKey = 'auth.token';
  static const _receivedAtKey = 'auth.receivedAt';
  static const _expiresAtKey = 'auth.expiresAt';
  static const _userKey = 'auth.user';

  static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  final FlutterSecureStorage _storage;

  Future<void> writeValue({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> readValue(String key) async {
    return _storage.read(key: key);
  }

  Future<void> deleteValue(String key) async {
    await _storage.delete(key: key);
  }

  Future<Map<String, String>> readAll() async {
    return _storage.readAll();
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<AuthSession> saveSessionToken(
    String token, {
    Duration ttl = defaultSessionTtl,
  }) async {
    final receivedAt = DateTime.now().toUtc();
    final expiresAt = receivedAt.add(ttl);
    final session = AuthSession(
      token: token,
      receivedAt: receivedAt,
      expiresAt: expiresAt,
    );

    final storageMap = session.toStorageMap();
    await _storage.write(key: _tokenKey, value: storageMap['token']);
    await _storage.write(key: _receivedAtKey, value: storageMap['receivedAt']);
    await _storage.write(key: _expiresAtKey, value: storageMap['expiresAt']);
    return session;
  }

  Future<AuthSession?> getSession() async {
    final token = await _storage.read(key: _tokenKey);
    final receivedAt = await _storage.read(key: _receivedAtKey);
    final expiresAt = await _storage.read(key: _expiresAtKey);
    if (token == null || receivedAt == null || expiresAt == null) {
      return null;
    }

    return AuthSession.fromStorageMap({
      'token': token,
      'receivedAt': receivedAt,
      'expiresAt': expiresAt,
    });
  }

  Future<String?> getValidToken() async {
    final session = await getSession();
    if (session == null) {
      return null;
    }
    if (session.isExpired) {
      await clearSession();
      return null;
    }
    return session.token;
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _receivedAtKey);
    await _storage.delete(key: _expiresAtKey);
    await _storage.delete(key: _userKey);
  }

  Future<void> saveUser(AuthUser user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<AuthUser?> getUser() async {
    final raw = await _storage.read(key: _userKey);
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
    await _storage.delete(key: _userKey);
  }
}
