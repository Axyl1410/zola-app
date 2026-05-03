import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_view_model.dart';

/// Bridges Riverpod's [authStatusNotifierProvider] to a [Listenable]
/// so [GoRouter.refreshListenable] can re-evaluate redirects on auth changes.
class AuthStatusListenable extends ChangeNotifier {
  AuthStatusListenable(Ref ref) {
    _subscription = ref.listen<AuthStatus>(
      authStatusNotifierProvider,
      (_, _) => notifyListeners(),
      fireImmediately: false,
    );
    ref.onDispose(dispose);
  }

  late final ProviderSubscription<AuthStatus> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
