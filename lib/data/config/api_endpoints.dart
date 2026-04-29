import 'api_config.dart';

class ApiEndpoints {
  static Uri _build(String baseUrl, String path) => Uri.parse('$baseUrl$path');

  static Uri authSignInSocial() {
    if (ApiConfig.backendBaseUrl.isEmpty) {
      throw Exception(
        'Missing BACKEND_BASE_URL. Run with --dart-define-from-file=env/dev.json',
      );
    }
    return _build(ApiConfig.backendBaseUrl, '/api/auth/sign-in/social');
  }
}
