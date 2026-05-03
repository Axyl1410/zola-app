import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/ui/features/auth/view_models/auth_status_providers.dart';
import 'package:zola/ui/routing/app_router.dart';

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
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Zola',
      themeMode: _themeMode,
      theme: _buildLightTheme(),
      routerConfig: router,
      builder: (context, child) {
        final logoutOverlay = ref.watch(logoutInProgressProvider);
        final belowAppBarTop =
            MediaQuery.paddingOf(context).top + kToolbarHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            child ?? const SizedBox.shrink(),
            if (logoutOverlay)
              Positioned(
                left: 0,
                right: 0,
                top: belowAppBarTop,
                child: const SizedBox(
                  height: 3,
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              ),
          ],
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(useMaterial3: _useMaterial3, brightness: Brightness.light);
  }
}
