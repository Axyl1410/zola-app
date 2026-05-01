import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';

const _unsetMessagesField = Object();

class MessagesState {
  const MessagesState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  MessagesState copyWith({
    bool? isLoading,
    Object? errorMessage = _unsetMessagesField,
  }) {
    return MessagesState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unsetMessagesField)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class MessagesNotifier extends Notifier<MessagesState> {
  @override
  MessagesState build() => const MessagesState();

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(authStatusNotifierProvider.notifier).logout();
      state = state.copyWith(isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }
}
