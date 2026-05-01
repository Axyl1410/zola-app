import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/di/providers/repositories_providers.dart';
import 'package:zola/domain/models/auth_user.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';

const _unsetLoginField = Object();

class LoginState {
  const LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  LoginState copyWith({
    bool? isLoading,
    Object? errorMessage = _unsetLoginField,
    bool? isSuccess,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unsetLoginField)
          ? this.errorMessage
          : errorMessage as String?,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class LoginNotifier extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<void> signInWithGoogle() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isSuccess: false,
    );
    try {
      final authResult = await ref
          .read(googleAuthRepositoryProvider)
          .signInWithGoogle();
      final backendResult = await ref
          .read(authBackendRepositoryProvider)
          .signInWithGoogle(authResult);
      final token = _extractToken(backendResult.body);
      if (token == null || token.isEmpty) {
        throw Exception('Backend response missing token');
      }
      debugPrint('Login success token: $token');
      final user = _extractUser(backendResult.body);
      await ref
          .read(authStatusNotifierProvider.notifier)
          .markAuthenticated(token, user: user);
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        isSuccess: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
        isSuccess: false,
      );
    }
  }

  String? _extractToken(String body) {
    final root = _decodeBodyAsMap(body);
    if (root == null) {
      return null;
    }

    final data = _extractDataMap(root);
    final directToken = root['token'];
    if (directToken is String && directToken.isNotEmpty) {
      return directToken;
    }
    if (data != null) {
      final dataToken = data['token'];
      if (dataToken is String && dataToken.isNotEmpty) {
        return dataToken;
      }
    }
    return null;
  }

  AuthUser? _extractUser(String body) {
    final root = _decodeBodyAsMap(body);
    if (root == null) {
      return null;
    }

    final data = _extractDataMap(root);
    final directUser = root['user'];
    if (directUser is Map<String, dynamic>) {
      return AuthUser.fromJson(directUser);
    }
    if (data != null) {
      final dataUser = data['user'];
      if (dataUser is Map<String, dynamic>) {
        return AuthUser.fromJson(dataUser);
      }
    }
    return null;
  }

  Map<String, dynamic>? _decodeBodyAsMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Map<String, dynamic>? _extractDataMap(Map<String, dynamic> root) {
    final data = root['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return null;
  }
}
