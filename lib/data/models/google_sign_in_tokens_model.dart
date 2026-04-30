class GoogleSignInTokensModel {
  const GoogleSignInTokensModel({
    required this.idToken,
    required this.accessToken,
  });

  final String? idToken;
  final String accessToken;
}
