import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/ui/features/home/views/home_view.dart';
import 'package:zola/ui/features/showcase/view_models/showcase_providers.dart';

import 'ui/core/constants/showcase_constants.dart';
import 'ui/features/showcase/view_models/showcase_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  static const bool _useMaterial3 = true;
  static const ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(showcaseNotifierProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zola',
      themeMode: _themeMode,
      theme: _buildLightTheme(state),
      // darkTheme: _buildDarkTheme(),
      // home: ShowcaseHome(useMaterial3: _useMaterial3),
      home: HomeView(),
    );
  }

  ThemeData _buildLightTheme(ShowcaseState state) {
    return ThemeData(
      colorSchemeSeed:
          state.colorSelectionMethod == ColorSelectionMethod.colorSeed
          ? state.colorSelected.color
          : null,
      colorScheme: state.colorSelectionMethod == ColorSelectionMethod.image
          ? state.imageColorScheme
          : null,
      useMaterial3: _useMaterial3,
      brightness: Brightness.light,
    );
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
