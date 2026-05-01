import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/data/repositories/auth_backend_repository.dart';
import 'package:zola/di/providers/repositories_providers.dart';
import 'package:zola/domain/models/auth_user.dart';

enum AuthStatus { checking, authenticated, banned, unauthenticated }

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
    final isSessionActive = await ensureSessionActiveForLifecycle();
    if (!ref.mounted) {
      return;
    }
    if (!isSessionActive && state != AuthStatus.banned) {
      _tokenExpiryTimer?.cancel();
    }
  }

  Future<bool> ensureSessionActiveForLifecycle() async {
    return _ensureSessionActive(requireOnlineValidation: false);
  }

  Future<bool> ensureSessionActiveForCriticalAction() async {
    return _ensureSessionActive(requireOnlineValidation: true);
  }

  // Backward-compatible alias for existing call sites.
  Future<bool> ensureSessionActive({bool requireOnlineValidation = true}) async {
    return _ensureSessionActive(requireOnlineValidation: requireOnlineValidation);
  }

  Future<bool> _ensureSessionActive({required bool requireOnlineValidation}) async {
    final sessionRepository = ref.read(authSessionRepositoryProvider);
    final token = await sessionRepository.getValidToken();
    if (!ref.mounted) {
      return false;
    }
    if (token == null || token.isEmpty) {
      await sessionRepository.clearSession();
      if (!ref.mounted) {
        return false;
      }
      state = AuthStatus.unauthenticated;
      return false;
    }

    try {
      final sessionResult = await ref
          .read(authBackendRepositoryProvider)
          .getSession(bearerToken: token);
      if (!ref.mounted) {
        return false;
      }
      if (sessionResult.user != null) {
        await sessionRepository.saveUser(sessionResult.user!);
        if (!ref.mounted) {
          return false;
        }
        if (sessionResult.user!.banned) {
          state = AuthStatus.banned;
          return false;
        }
      }
      state = AuthStatus.authenticated;
      return true;
    } on AuthBackendHttpException catch (error) {
      if (!ref.mounted) {
        return false;
      }
      if (error.statusCode == 401) {
        await logout();
        return false;
      }
      if (!requireOnlineValidation) {
        debugPrint(
          'Session check skipped due to non-401 error: ${error.message}',
        );
        state = AuthStatus.authenticated;
        return true;
      }
      return false;
    } catch (error) {
      if (!ref.mounted) {
        return false;
      }
      if (!requireOnlineValidation) {
        debugPrint('Session check skipped due to error: $error');
        state = AuthStatus.authenticated;
        return true;
      }
      return false;
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
    state = user?.banned == true ? AuthStatus.banned : AuthStatus.authenticated;
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
