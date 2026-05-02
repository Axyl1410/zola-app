import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/data/repositories/auth_backend_repository.dart';
import 'package:zola/di/providers/repositories_providers.dart';
import 'package:zola/domain/models/auth_user.dart';
import 'package:zola/ui/features/auth/view_models/auth_logout_busy_provider.dart';
import 'package:zola/ui/features/auth/view_models/current_user_provider.dart';

enum AuthStatus {
  checking,
  sessionRecoveryRequired,
  authenticated,
  banned,
  unauthenticated,
}
enum SessionValidationOutcome { active, banned, unauthenticated, transientFailure }

class AuthStatusNotifier extends Notifier<AuthStatus> {
  Timer? _tokenExpiryTimer;
  DateTime? _lastCriticalValidationAt;
  SessionValidationOutcome? _lastCriticalValidationOutcome;
  static const Duration _criticalValidationCooldown = Duration(seconds: 5);

  void _invalidateCurrentUserIfMounted() {
    if (ref.mounted) {
      ref.invalidate(currentUserProvider);
    }
  }

  @override
  AuthStatus build() {
    ref.onDispose(() {
      _tokenExpiryTimer?.cancel();
    });
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
    final outcome = await validateSessionForLifecycle();
    if (!ref.mounted) {
      return;
    }
    if (outcome == SessionValidationOutcome.unauthenticated) {
      _tokenExpiryTimer?.cancel();
      return;
    }
    if (outcome == SessionValidationOutcome.transientFailure &&
        state == AuthStatus.checking) {
      state = AuthStatus.sessionRecoveryRequired;
    }
  }

  Future<bool> ensureSessionActiveForLifecycle() async {
    final outcome = await validateSessionForLifecycle();
    return outcome == SessionValidationOutcome.active;
  }

  Future<bool> ensureSessionActiveForCriticalAction() async {
    final outcome = await validateSessionForCriticalAction();
    return outcome == SessionValidationOutcome.active;
  }

  Future<SessionValidationOutcome> validateSessionForLifecycle() async {
    return _validateSession(requireOnlineValidation: false);
  }

  Future<SessionValidationOutcome> validateSessionForCriticalAction() async {
    final now = DateTime.now().toUtc();
    final lastAt = _lastCriticalValidationAt;
    final lastResult = _lastCriticalValidationOutcome;
    if (lastAt != null &&
        lastResult != null &&
        now.difference(lastAt) < _criticalValidationCooldown) {
      return lastResult;
    }

    final result = await _validateSession(requireOnlineValidation: true);
    _lastCriticalValidationAt = now;
    _lastCriticalValidationOutcome = result;
    return result;
  }

  void _resetCriticalValidationCache() {
    _lastCriticalValidationAt = null;
    _lastCriticalValidationOutcome = null;
  }

  @visibleForTesting
  void resetCriticalValidationCacheForTest() {
    _resetCriticalValidationCache();
  }

  Future<void> _clearLocalSessionAndSetUnauthenticated() async {
    await ref.read(authSessionRepositoryProvider).clearSession();
    _invalidateCurrentUserIfMounted();
    state = AuthStatus.unauthenticated;
    _tokenExpiryTimer?.cancel();
  }

  // Backward-compatible alias for existing call sites.
  Future<bool> ensureSessionActive({
    bool requireOnlineValidation = true,
  }) async {
    final outcome = await _validateSession(
      requireOnlineValidation: requireOnlineValidation,
    );
    return outcome == SessionValidationOutcome.active;
  }

  Future<SessionValidationOutcome> _validateSession({
    required bool requireOnlineValidation,
  }) async {
    final sessionRepository = ref.read(authSessionRepositoryProvider);
    final token = await sessionRepository.getValidToken();
    if (!ref.mounted) {
      return SessionValidationOutcome.unauthenticated;
    }
    if (token == null || token.isEmpty) {
      await sessionRepository.clearSession();
      _invalidateCurrentUserIfMounted();
      if (!ref.mounted) {
        return SessionValidationOutcome.unauthenticated;
      }
      state = AuthStatus.unauthenticated;
      return SessionValidationOutcome.unauthenticated;
    }

    try {
      final sessionResult = await ref
          .read(authBackendRepositoryProvider)
          .getSession(bearerToken: token);
      if (!ref.mounted) {
        return SessionValidationOutcome.unauthenticated;
      }
      final backendToken = sessionResult.session.token;
      final effectiveToken = backendToken.isEmpty ? token : backendToken;
      final backendExpiresAt = DateTime.tryParse(
        sessionResult.session.expiresAt,
      )?.toUtc();
      if (backendExpiresAt != null) {
        final receivedAtRaw = sessionResult.session.createdAt;
        final receivedAt = DateTime.tryParse(receivedAtRaw ?? '')?.toUtc();
        await sessionRepository.saveSession(
          token: effectiveToken,
          expiresAt: backendExpiresAt,
          receivedAt: receivedAt,
        );
      } else {
        await sessionRepository.saveToken(effectiveToken);
      }
      if (sessionResult.user != null) {
        await sessionRepository.saveUser(sessionResult.user!);
      } else {
        await sessionRepository.clearUser();
      }
      await _scheduleExpiryCheckFromSession();
      _invalidateCurrentUserIfMounted();
      if (!ref.mounted) {
        return SessionValidationOutcome.unauthenticated;
      }
      if (sessionResult.user?.banned == true) {
        state = AuthStatus.banned;
        return SessionValidationOutcome.banned;
      }
      state = AuthStatus.authenticated;
      return SessionValidationOutcome.active;
    } on AuthBackendHttpException catch (error) {
      if (!ref.mounted) {
        return SessionValidationOutcome.unauthenticated;
      }
      if (error.statusCode == 401) {
        await logout(notifyBackend: false);
        return SessionValidationOutcome.unauthenticated;
      }
      if (!requireOnlineValidation) {
        debugPrint(
          'Session check skipped due to non-401 error: ${error.message}',
        );
        // Keep current auth state on lifecycle lenient checks.
        if (state == AuthStatus.banned) {
          return SessionValidationOutcome.banned;
        }
        if (state == AuthStatus.authenticated) {
          return SessionValidationOutcome.active;
        }
        return SessionValidationOutcome.transientFailure;
      }
      debugPrint(
        'Critical session validation failed (${error.statusCode}): ${error.message}. Keep session, block critical action.',
      );
      return SessionValidationOutcome.transientFailure;
    } catch (error) {
      if (!ref.mounted) {
        return SessionValidationOutcome.unauthenticated;
      }
      if (!requireOnlineValidation) {
        debugPrint('Session check skipped due to error: $error');
        // Keep current auth state on lifecycle lenient checks.
        if (state == AuthStatus.banned) {
          return SessionValidationOutcome.banned;
        }
        if (state == AuthStatus.authenticated) {
          return SessionValidationOutcome.active;
        }
        return SessionValidationOutcome.transientFailure;
      }
      debugPrint(
        'Critical session validation failed: $error. Keep session, block critical action.',
      );
      return SessionValidationOutcome.transientFailure;
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
    _invalidateCurrentUserIfMounted();
    state = user?.banned == true ? AuthStatus.banned : AuthStatus.authenticated;
    _resetCriticalValidationCache();
    await _scheduleExpiryCheckFromSession();
  }

  Future<void> logout({bool notifyBackend = true}) async {
    ref.read(logoutInProgressProvider.notifier).state = true;
    try {
      _resetCriticalValidationCache();
      if (!notifyBackend) {
        await _clearLocalSessionAndSetUnauthenticated();
        return;
      }

      final sessionRepository = ref.read(authSessionRepositoryProvider);
      final token = await sessionRepository.getValidToken();
      if (token != null && token.isNotEmpty) {
        try {
          await ref
              .read(authBackendRepositoryProvider)
              .signOut(bearerToken: token);
        } catch (error) {
          // Always clear local session even if backend logout fails.
          debugPrint('Backend sign-out failed, fallback to local clear: $error');
        }
      }
      await _clearLocalSessionAndSetUnauthenticated();
    } finally {
      if (ref.mounted) {
        ref.read(logoutInProgressProvider.notifier).state = false;
      }
    }
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
