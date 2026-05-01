import 'api_config.dart';

class ApiEndpoints {
  static Uri _build(String baseUrl, String path) => Uri.parse('$baseUrl$path');

  static Uri _buildBackend(String path) {
    if (ApiConfig.backendBaseUrl.isEmpty) {
      throw Exception(
        'Missing BACKEND_BASE_URL. Run with --dart-define-from-file=env/dev.json',
      );
    }
    return _build(ApiConfig.backendBaseUrl, path);
  }

  static Uri authSignInSocial() {
    return _buildBackend('/api/auth/sign-in/social');
  }

  static Uri authSignOut() {
    return _buildBackend('/api/auth/sign-out');
  }

  static Uri authGetSession() {
    return _buildBackend('/api/auth/get-session');
  }
}
