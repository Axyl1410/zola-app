import 'package:google_sign_in/google_sign_in.dart';
import 'package:zola/data/models/google_sign_in_tokens_model.dart';

class GoogleSignInService {
  static const String _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  bool _isInitialized = false;

  Future<GoogleSignInTokensModel> signIn() async {
    if (_googleServerClientId.isEmpty) {
      throw Exception(
        'Missing GOOGLE_SERVER_CLIENT_ID. Run with --dart-define=GOOGLE_SERVER_CLIENT_ID=<your-web-client-id>',
      );
    }

    if (!_isInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: _googleServerClientId,
      );
      _isInitialized = true;
    }

    final GoogleSignInAccount user = await GoogleSignIn.instance.authenticate();
    final GoogleSignInAuthentication auth = user.authentication;
    final GoogleSignInClientAuthorization authorization = await user
        .authorizationClient
        .authorizeScopes(<String>['openid', 'email', 'profile']);

    return GoogleSignInTokensModel(
      idToken: auth.idToken,
      accessToken: authorization.accessToken,
    );
  }
}
