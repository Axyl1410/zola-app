import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/di/providers/repositories_providers.dart';
import 'package:zola/domain/models/google_auth_result.dart';

const _unsetMessagesField = Object();

class MessagesState {
  const MessagesState({
    this.isLoading = false,
    this.errorMessage,
    this.authResult,
    this.backendStatusCode,
    this.backendResponseBody,
  });

  final bool isLoading;
  final String? errorMessage;
  final GoogleAuthResult? authResult;
  final int? backendStatusCode;
  final String? backendResponseBody;

  MessagesState copyWith({
    bool? isLoading,
    Object? errorMessage = _unsetMessagesField,
    Object? authResult = _unsetMessagesField,
    Object? backendStatusCode = _unsetMessagesField,
    Object? backendResponseBody = _unsetMessagesField,
  }) {
    return MessagesState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unsetMessagesField)
          ? this.errorMessage
          : errorMessage as String?,
      authResult: identical(authResult, _unsetMessagesField)
          ? this.authResult
          : authResult as GoogleAuthResult?,
      backendStatusCode: identical(backendStatusCode, _unsetMessagesField)
          ? this.backendStatusCode
          : backendStatusCode as int?,
      backendResponseBody: identical(backendResponseBody, _unsetMessagesField)
          ? this.backendResponseBody
          : backendResponseBody as String?,
    );
  }
}

class MessagesNotifier extends Notifier<MessagesState> {
  @override
  MessagesState build() => const MessagesState();

  Future<void> signInWithGoogle() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      backendStatusCode: null,
      backendResponseBody: null,
    );

    try {
      final authResult = await ref
          .read(googleAuthRepositoryProvider)
          .signInWithGoogle();
      final backendResult = await ref
          .read(authBackendRepositoryProvider)
          .signInWithGoogle(authResult);
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        authResult: authResult,
        backendStatusCode: backendResult.statusCode,
        backendResponseBody: backendResult.body,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
        authResult: null,
      );
    }
  }

  void clearAuthResult() {
    state = state.copyWith(authResult: null);
  }
}
