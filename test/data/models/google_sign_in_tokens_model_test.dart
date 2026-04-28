import 'package:flutter_test/flutter_test.dart';
import 'package:zola/data/models/google_sign_in_tokens_model.dart';

void main() {
  group('GoogleSignInTokensModel', () {
    test('stores all provided values', () {
      const model = GoogleSignInTokensModel(
        email: 'user@example.com',
        idToken: 'id-token',
        accessToken: 'access-token',
      );

      expect(model.email, 'user@example.com');
      expect(model.idToken, 'id-token');
      expect(model.accessToken, 'access-token');
    });

    test('accepts nullable id token', () {
      const model = GoogleSignInTokensModel(
        email: 'user@example.com',
        idToken: null,
        accessToken: 'access-token',
      );

      expect(model.idToken, isNull);
    });
  });
}
