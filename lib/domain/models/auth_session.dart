class AuthSession {
  const AuthSession({
    required this.token,
    required this.receivedAt,
    required this.expiresAt,
  });

  final String token;
  final DateTime receivedAt;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, String> toStorageMap() {
    return <String, String>{
      'token': token,
      'receivedAt': receivedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  static AuthSession? fromStorageMap(Map<String, String> map) {
    final token = map['token'];
    final receivedAtRaw = map['receivedAt'];
    final expiresAtRaw = map['expiresAt'];
    if (token == null || receivedAtRaw == null || expiresAtRaw == null) {
      return null;
    }

    final receivedAt = DateTime.tryParse(receivedAtRaw);
    final expiresAt = DateTime.tryParse(expiresAtRaw);
    if (receivedAt == null || expiresAt == null) {
      return null;
    }

    return AuthSession(
      token: token,
      receivedAt: receivedAt,
      expiresAt: expiresAt,
    );
  }
}
