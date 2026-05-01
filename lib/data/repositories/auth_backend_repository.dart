import 'dart:convert';

import 'package:zola/data/services/auth_remote_service.dart';
import 'package:zola/domain/models/auth_user.dart';
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
    _throwIfHttpError(response.statusCode, response.body);

    final payload = _decodeBodyAsMap(response.body);
    final root = _extractDataMap(payload) ?? payload;
    final token = root['token'];
    if (token is! String || token.isEmpty) {
      throw Exception('Backend response missing token');
    }
    final user = _parseAuthUser(root['user']);

    return AuthBackendSignInResult(
      statusCode: response.statusCode,
      token: token,
      user: user,
      url: root['url'] is String ? root['url'] as String : null,
      redirect: root['redirect'] is bool ? root['redirect'] as bool : null,
    );
  }

  Future<void> signOut({required String bearerToken}) async {
    final response = await _authRemoteService.signOut(bearerToken: bearerToken);
    _throwIfHttpError(response.statusCode, response.body);
  }

  Future<AuthBackendSessionResult> getSession({required String bearerToken}) async {
    final response = await _authRemoteService.getSession(bearerToken: bearerToken);
    _throwIfHttpError(response.statusCode, response.body);
    final payload = _decodeBodyAsMap(response.body);
    final root = _extractDataMap(payload) ?? payload;
    final sessionRaw = root['session'];
    if (sessionRaw is! Map<String, dynamic>) {
      throw Exception('Backend response missing session');
    }
    final session = AuthBackendSession.fromJson(sessionRaw);
    if (session == null) {
      throw Exception('Backend response has invalid session');
    }
    return AuthBackendSessionResult(
      statusCode: response.statusCode,
      session: session,
      user: _parseAuthUser(root['user']),
    );
  }

  Map<String, dynamic> _decodeBodyAsMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Backend response is not a JSON object');
    }
    return decoded;
  }

  void _throwIfHttpError(int statusCode, String body) {
    if (statusCode < 400 || statusCode > 599) {
      return;
    }
    final message = _extractErrorMessage(body);
    if (message != null) {
      throw AuthBackendHttpException(statusCode: statusCode, message: message);
    }
    throw AuthBackendHttpException(
      statusCode: statusCode,
      message: 'Request failed with status code $statusCode',
    );
  }

  String? _extractErrorMessage(String body) {
    try {
      final payload = _decodeBodyAsMap(body);
      final message = payload['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Map<String, dynamic>? _extractDataMap(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return null;
  }

  AuthUser? _parseAuthUser(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return AuthUser.fromJson(raw);
    }
    return null;
  }
}

class AuthBackendHttpException implements Exception {
  const AuthBackendHttpException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() => 'AuthBackendHttpException($statusCode): $message';
}

class AuthBackendSignInResult {
  const AuthBackendSignInResult({
    required this.statusCode,
    required this.token,
    this.user,
    this.url,
    this.redirect,
  });

  final int statusCode;
  final String token;
  final AuthUser? user;
  final String? url;
  final bool? redirect;
}

class AuthBackendSessionResult {
  const AuthBackendSessionResult({
    required this.statusCode,
    required this.session,
    this.user,
  });

  final int statusCode;
  final AuthBackendSession session;
  final AuthUser? user;
}

class AuthBackendSession {
  const AuthBackendSession({
    required this.id,
    required this.expiresAt,
    required this.token,
    this.createdAt,
    this.updatedAt,
    this.ipAddress,
    this.userAgent,
    this.userId,
    this.impersonatedBy,
  });

  final String id;
  final String expiresAt;
  final String token;
  final String? createdAt;
  final String? updatedAt;
  final String? ipAddress;
  final String? userAgent;
  final String? userId;
  final String? impersonatedBy;

  static AuthBackendSession? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final expiresAt = json['expiresAt'];
    final token = json['token'];
    if (id is! String || expiresAt is! String || token is! String) {
      return null;
    }
    return AuthBackendSession(
      id: id,
      expiresAt: expiresAt,
      token: token,
      createdAt: json['createdAt'] is String ? json['createdAt'] as String : null,
      updatedAt: json['updatedAt'] is String ? json['updatedAt'] as String : null,
      ipAddress: json['ipAddress'] is String ? json['ipAddress'] as String : null,
      userAgent: json['userAgent'] is String ? json['userAgent'] as String : null,
      userId: json['userId'] is String ? json['userId'] as String : null,
      impersonatedBy: json['impersonatedBy'] is String
          ? json['impersonatedBy'] as String
          : null,
    );
  }
}
