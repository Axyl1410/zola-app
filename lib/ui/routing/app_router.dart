import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zola/ui/features/admin/views/screens/admin_screen.dart';
import 'package:zola/ui/features/admin/views/screens/admin_users_screen.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_view_model.dart';
import 'package:zola/ui/features/auth/views/auth_required_view.dart';
import 'package:zola/ui/features/auth/views/banned_view.dart';
import 'package:zola/ui/features/auth/views/login_view.dart';
import 'package:zola/ui/features/contacts/views/screens/contacts_screen.dart';
import 'package:zola/ui/features/contacts/views/screens/full_screen_page.dart';
import 'package:zola/ui/features/discover/views/screens/discover_screen.dart';
import 'package:zola/ui/features/home/views/home_view.dart';
import 'package:zola/ui/features/messages/views/screens/messages_screen.dart';
import 'package:zola/ui/features/personal/views/screens/personal_screen.dart';
import 'package:zola/ui/features/settings/views/screens/settings_screen.dart';
import 'package:zola/ui/features/wall/views/screens/wall_screen.dart';
import 'package:zola/ui/routing/app_routes.dart';
import 'package:zola/ui/routing/auth_loading_view.dart';
import 'package:zola/ui/routing/auth_status_listenable.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'rootNavigator',
);
final _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'homeShellNavigator',
);

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = AuthStatusListenable(ref);

  String? redirect(BuildContext context, GoRouterState state) {
    final status = ref.read(authStatusNotifierProvider);
    final loc = state.matchedLocation;
    switch (status) {
      case AuthStatus.checking:
        return loc == AppRoute.loading ? null : AppRoute.loading;
      case AuthStatus.unauthenticated:
        return loc == AppRoute.login ? null : AppRoute.login;
      case AuthStatus.banned:
        return loc == AppRoute.banned ? null : AppRoute.banned;
      case AuthStatus.sessionRecoveryRequired:
        return loc == AppRoute.authRequired ? null : AppRoute.authRequired;
      case AuthStatus.authenticated:
        return AppRoute.authOnly.contains(loc) ? AppRoute.homeMessages : null;
    }
  }

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoute.root,
    refreshListenable: listenable,
    redirect: redirect,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoute.root,
        redirect: (_, _) => AppRoute.homeMessages,
      ),
      GoRoute(
        path: AppRoute.loading,
        builder: (_, _) => const AuthLoadingView(),
      ),
      GoRoute(
        path: AppRoute.login,
        builder: (_, _) => const LoginView(),
      ),
      GoRoute(
        path: AppRoute.banned,
        builder: (_, _) => const BannedView(),
      ),
      GoRoute(
        path: AppRoute.authRequired,
        builder: (_, _) => const AuthRequiredView(),
      ),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) =>
            HomeView(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.homeMessages,
                builder: (_, _) => const MessagesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.homeContacts,
                builder: (_, _) => const ContactsScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'full',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, _) => const FullScreenPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.homeDiscover,
                builder: (_, _) => const DiscoverScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.homeWall,
                builder: (_, _) => const WallScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoute.homePersonal,
                builder: (_, _) => const PersonalScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.admin,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AdminScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'users',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, _) => const AdminUsersScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.settings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const SettingsScreen(),
      ),
    ],
  );
});
