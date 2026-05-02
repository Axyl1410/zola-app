import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/di/providers/repositories_providers.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';
import 'package:zola/ui/features/auth/view_models/login_providers.dart';

const _unsetLoginField = Object();
const _logFullToken = bool.fromEnvironment(
  'LOG_FULL_TOKEN',
  defaultValue: false,
);

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

  @visibleForTesting
  static String formatTokenForLog(
    String token, {
    bool logFullToken = _logFullToken,
  }) {
    if (logFullToken) {
      return token;
    }
    if (token.length <= 10) {
      return '${token.substring(0, 2)}***';
    }
    return '${token.substring(0, 6)}***${token.substring(token.length - 4)}';
  }

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
      final token = backendResult.token;
      if (kDebugMode) {
        final displayToken = formatTokenForLog(token);
        debugPrint('Login success token: $displayToken');
      }
      await ref
          .read(authStatusNotifierProvider.notifier)
          .markAuthenticated(token, user: backendResult.user);
      final lastLoginMethod = backendResult.user?.lastLoginMethod;
      if (lastLoginMethod != null && lastLoginMethod.isNotEmpty) {
        await ref
            .read(authSessionRepositoryProvider)
            .saveLastLoginMethod(lastLoginMethod);
        ref.invalidate(lastLoginMethodProvider);
      }
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
}
