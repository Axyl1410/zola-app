import 'package:flutter_test/flutter_test.dart';
import 'package:zola/domain/models/google_auth_result.dart';

void main() {
  group('GoogleAuthResult', () {
    test('stores all provided values', () {
      const result = GoogleAuthResult(
        idToken: 'id-token',
        accessToken: 'access-token',
      );

      expect(result.idToken, 'id-token');
      expect(result.accessToken, 'access-token');
    });

    test('accepts nullable id token', () {
      const result = GoogleAuthResult(
        idToken: null,
        accessToken: 'access-token',
      );

      expect(result.idToken, isNull);
    });
  });
}
