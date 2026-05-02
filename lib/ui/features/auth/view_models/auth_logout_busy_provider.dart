import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True while [AuthStatusNotifier.logout] is running (backend sign-out + local clear).
class LogoutInProgressNotifier extends Notifier<bool> {
  @override
  bool build() => false;
}

final logoutInProgressProvider =
    NotifierProvider<LogoutInProgressNotifier, bool>(
      LogoutInProgressNotifier.new,
    );
