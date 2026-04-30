import 'package:flutter_test/flutter_test.dart';
import 'package:zola/data/config/api_config.dart';
import 'package:zola/data/config/api_endpoints.dart';

void main() {
  group('ApiEndpoints', () {
    test('authSignInSocial throws when BACKEND_BASE_URL is missing', () {
      expect(ApiConfig.backendBaseUrl, isEmpty);
      expect(() => ApiEndpoints.authSignInSocial(), throwsA(isA<Exception>()));
    });

    test('authSignOut throws when BACKEND_BASE_URL is missing', () {
      expect(ApiConfig.backendBaseUrl, isEmpty);
      expect(() => ApiEndpoints.authSignOut(), throwsA(isA<Exception>()));
    });
  });
}
