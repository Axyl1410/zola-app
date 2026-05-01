import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/di/providers/repositories_providers.dart';
import 'package:zola/domain/models/auth_user.dart';

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
    final repository = ref.read(authSessionRepositoryProvider);
    final token = await repository.getValidToken();
    state = (token != null && token.isNotEmpty)
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    if (state == AuthStatus.unauthenticated) {
      _tokenExpiryTimer?.cancel();
      // Ensure profile cache is always cleared when session is invalid.
      await repository.clearSession();
    }
  }

  Future<void> markAuthenticated(String token, {AuthUser? user}) async {
    final repository = ref.read(authSessionRepositoryProvider);
    await repository.saveToken(token);
    if (user != null) {
      await repository.saveUser(user);
    } else {
      await repository.clearUser();
    }
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
