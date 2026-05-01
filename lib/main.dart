import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_view_model.dart';
import 'package:zola/ui/features/auth/views/auth_required_view.dart';
import 'package:zola/ui/features/auth/views/banned_view.dart';
import 'package:zola/ui/features/auth/views/login_view.dart';
import 'package:zola/ui/features/home/views/home_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  static const bool _useMaterial3 = true;
  static const ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(
      ref.read(authStatusNotifierProvider.notifier).enableSessionGuard(),
    );
  }

  @override
  void dispose() {
    unawaited(
      ref.read(authStatusNotifierProvider.notifier).disableSessionGuard(),
    );
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(authStatusNotifierProvider.notifier).onAppResumed());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(authStatusNotifierProvider);
    return MaterialApp(
      key: ValueKey<AuthStatus>(authStatus),
      debugShowCheckedModeBanner: false,
      title: 'Zola',
      themeMode: _themeMode,
      theme: _buildLightTheme(),
      home: switch (authStatus) {
        AuthStatus.checking => const _AuthLoadingView(),
        AuthStatus.sessionRecoveryRequired => const AuthRequiredView(),
        AuthStatus.authenticated => const HomeView(),
        AuthStatus.banned => const BannedView(),
        AuthStatus.unauthenticated => const LoginView(),
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(useMaterial3: _useMaterial3, brightness: Brightness.light);
  }

  // ThemeData _buildDarkTheme() {
  //   return ThemeData(
  //     colorSchemeSeed:
  //         state.colorSelectionMethod == ColorSelectionMethod.colorSeed
  //         ? state.colorSelected.color
  //         : state.imageColorScheme.primary,
  //     useMaterial3: _useMaterial3,
  //     brightness: Brightness.dark,
  //   );
  // }
}

class _AuthLoadingView extends StatelessWidget {
  const _AuthLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
