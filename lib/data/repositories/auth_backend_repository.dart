import 'package:zola/data/services/auth_remote_service.dart';
import 'package:zola/domain/models/google_auth_result.dart';

class AuthBackendRepository {
  AuthBackendRepository({required AuthRemoteService authRemoteService})
    : _authRemoteService = authRemoteService;

  final AuthRemoteService _authRemoteService;

  Future<AuthBackendSignInResult> signInWithGoogle(
    GoogleAuthResult authResult,
  ) async {
    final idToken = authResult.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('idToken is null/empty');
    }

    final response = await _authRemoteService.signInWithGoogle(
      idToken: idToken,
      accessToken: authResult.accessToken,
    );

    return AuthBackendSignInResult(
      statusCode: response.statusCode,
      body: response.body,
    );
  }
}

class AuthBackendSignInResult {
  const AuthBackendSignInResult({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}
