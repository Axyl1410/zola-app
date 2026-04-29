import 'package:flutter_test/flutter_test.dart';
import 'package:zola/data/models/google_sign_in_tokens_model.dart';
import 'package:zola/data/repositories/google_auth_repository.dart';
import 'package:zola/data/services/google_sign_in_service.dart';
import 'package:zola/domain/models/google_auth_result.dart';
import 'package:zola/ui/features/messages/view_models/messages_view_model.dart';

void main() {
  group('MessagesViewModel', () {
    test('signInWithGoogle sets auth result on success', () async {
      final fakeRepository = _FakeGoogleAuthRepository();
      final viewModel = MessagesViewModel(googleAuthRepository: fakeRepository);

      await viewModel.signInWithGoogle();

      expect(fakeRepository.signInCalled, isTrue);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.authResult, isNotNull);
      expect(viewModel.authResult!.email, 'user@example.com');
      expect(viewModel.authResult!.idToken, 'id-token');
      expect(viewModel.authResult!.accessToken, 'access-token');
    });

    test('signInWithGoogle sets error message on failure', () async {
      final fakeRepository = _FakeGoogleAuthRepository(throwOnSignIn: true);
      final viewModel = MessagesViewModel(googleAuthRepository: fakeRepository);

      await viewModel.signInWithGoogle();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.authResult, isNull);
      expect(viewModel.errorMessage, contains('Google sign-in failed'));
    });

    test('clearAuthResult resets stored auth result', () async {
      final fakeRepository = _FakeGoogleAuthRepository();
      final viewModel = MessagesViewModel(googleAuthRepository: fakeRepository);
      await viewModel.signInWithGoogle();

      viewModel.clearAuthResult();

      expect(viewModel.authResult, isNull);
    });
  });
}

class _FakeGoogleAuthRepository extends GoogleAuthRepository {
  _FakeGoogleAuthRepository({this.throwOnSignIn = false})
    : super(googleSignInService: _NoopGoogleSignInService());

  final bool throwOnSignIn;
  bool signInCalled = false;

  @override
  Future<GoogleAuthResult> signInWithGoogle() async {
    signInCalled = true;
    if (throwOnSignIn) {
      throw Exception('Google sign-in failed');
    }
    return const GoogleAuthResult(
      email: 'user@example.com',
      idToken: 'id-token',
      accessToken: 'access-token',
    );
  }
}

class _NoopGoogleSignInService extends GoogleSignInService {
  @override
  Future<GoogleSignInTokensModel> signIn() {
    throw UnimplementedError();
  }
}
