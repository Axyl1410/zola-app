import 'package:zola/data/services/secure_storage_service.dart';
import 'package:zola/domain/models/auth_session.dart';

class AuthSessionRepository {
  AuthSessionRepository({required SecureStorageService secureStorageService})
    : _secureStorageService = secureStorageService;

  final SecureStorageService _secureStorageService;

  Future<AuthSession> saveToken(
    String token, {
    Duration ttl = SecureStorageService.defaultSessionTtl,
  }) {
    return _secureStorageService.saveSessionToken(token, ttl: ttl);
  }

  Future<AuthSession?> getSession() {
    return _secureStorageService.getSession();
  }

  Future<String?> getValidToken() {
    return _secureStorageService.getValidToken();
  }

  Future<void> clearSession() {
    return _secureStorageService.clearSession();
  }
}
