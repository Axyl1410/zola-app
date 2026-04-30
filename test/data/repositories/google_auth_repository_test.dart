import 'package:flutter_test/flutter_test.dart';
import 'package:zola/data/models/google_sign_in_tokens_model.dart';
import 'package:zola/data/repositories/google_auth_repository.dart';
import 'package:zola/data/services/google_sign_in_service.dart';

void main() {
  group('GoogleAuthRepository', () {
    test('maps sign-in tokens model to domain result', () async {
      final fakeService = _FakeGoogleSignInService();
      final repository = GoogleAuthRepository(googleSignInService: fakeService);

      final result = await repository.signInWithGoogle();

      expect(fakeService.signInCalled, isTrue);
      expect(result.idToken, 'id-token');
      expect(result.accessToken, 'access-token');
    });
  });
}

class _FakeGoogleSignInService extends GoogleSignInService {
  bool signInCalled = false;

  @override
  Future<GoogleSignInTokensModel> signIn() async {
    signInCalled = true;
    return const GoogleSignInTokensModel(
      idToken: 'id-token',
      accessToken: 'access-token',
    );
  }
}
