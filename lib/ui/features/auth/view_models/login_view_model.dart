import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/di/providers/repositories_providers.dart';
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
      await ref
          .read(authStatusNotifierProvider.notifier)
          .markAuthenticated(token);
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
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final directToken = decoded['token'];
        if (directToken is String && directToken.isNotEmpty) {
          return directToken;
        }
        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          final dataToken = data['token'];
          if (dataToken is String && dataToken.isNotEmpty) {
            return dataToken;
          }
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
