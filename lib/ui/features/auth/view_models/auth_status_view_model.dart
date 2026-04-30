import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/di/providers/repositories_providers.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthStatusNotifier extends Notifier<AuthStatus> {
  Timer? _tokenExpiryTimer;

  @override
  AuthStatus build() {
    ref.onDispose(() {
      _tokenExpiryTimer?.cancel();
    });
    Future.microtask(refreshAuthStatus);
    return AuthStatus.checking;
  }

  Future<void> enableSessionGuard() async {
    await refreshAuthStatus();
    await _scheduleExpiryCheckFromSession();
  }

  Future<void> disableSessionGuard() async {
    _tokenExpiryTimer?.cancel();
  }

  Future<void> onAppResumed() async {
    await enableSessionGuard();
  }

  Future<void> refreshAuthStatus() async {
    final token = await ref.read(authSessionRepositoryProvider).getValidToken();
    state = (token != null && token.isNotEmpty)
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    if (state == AuthStatus.unauthenticated) {
      _tokenExpiryTimer?.cancel();
    }
  }

  Future<void> markAuthenticated(String token) async {
    await ref.read(authSessionRepositoryProvider).saveToken(token);
    state = AuthStatus.authenticated;
    await _scheduleExpiryCheckFromSession();
  }

  Future<void> logout() async {
    await ref.read(authSessionRepositoryProvider).clearSession();
    state = AuthStatus.unauthenticated;
    _tokenExpiryTimer?.cancel();
  }

  Future<void> _scheduleExpiryCheckFromSession() async {
    _tokenExpiryTimer?.cancel();
    final session = await ref.read(authSessionRepositoryProvider).getSession();
    if (session == null) {
      return;
    }
    final remaining = session.expiresAt.difference(DateTime.now().toUtc());
    if (remaining <= Duration.zero) {
      await refreshAuthStatus();
      return;
    }
    _tokenExpiryTimer = Timer(remaining, () {
      unawaited(refreshAuthStatus());
    });
  }
}
