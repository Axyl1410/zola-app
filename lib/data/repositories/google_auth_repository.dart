import '../../domain/models/google_auth_result.dart';
import '../services/google_sign_in_service.dart';

class GoogleAuthRepository {
  GoogleAuthRepository({required GoogleSignInService googleSignInService})
    : _googleSignInService = googleSignInService;

  final GoogleSignInService _googleSignInService;

  Future<GoogleAuthResult> signInWithGoogle() async {
    final signInResult = await _googleSignInService.signIn();
    return GoogleAuthResult(
      email: signInResult.email,
      idToken: signInResult.idToken,
      accessToken: signInResult.accessToken,
    );
  }
}
