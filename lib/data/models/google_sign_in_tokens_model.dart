class GoogleSignInTokensModel {
  const GoogleSignInTokensModel({
    required this.email,
    required this.idToken,
    required this.accessToken,
  });

  final String email;
  final String? idToken;
  final String accessToken;
}
