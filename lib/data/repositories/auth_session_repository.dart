import '../../domain/models/auth_session.dart';
import '../services/secure_storage_service.dart';

class AuthSessionRepository {
  AuthSessionRepository({SecureStorageService? secureStorageService})
    : _secureStorageService = secureStorageService ?? SecureStorageService();

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
