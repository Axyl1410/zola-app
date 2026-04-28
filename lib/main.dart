import 'package:flutter/material.dart';
import 'package:zola/ui/features/home/views/home_view.dart';

import 'di/injector.dart';
import 'ui/core/constants/showcase_constants.dart';
import 'ui/features/showcase/view_models/showcase_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final ShowcaseViewModel _viewModel;
  static const bool _useMaterial3 = true;
  static const ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _viewModel = sl<ShowcaseViewModel>();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Zola',
        themeMode: _themeMode,
        theme: _buildLightTheme(),
        // darkTheme: _buildDarkTheme(),
        // home: ShowcaseHome(useMaterial3: _useMaterial3, viewModel: _viewModel),
        home: HomeView(),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      colorSchemeSeed:
          _viewModel.colorSelectionMethod == ColorSelectionMethod.colorSeed
          ? _viewModel.colorSelected.color
          : null,
      colorScheme: _viewModel.colorSelectionMethod == ColorSelectionMethod.image
          ? _viewModel.imageColorScheme
          : null,
      useMaterial3: _useMaterial3,
      brightness: Brightness.light,
    );
  }

  // ThemeData _buildDarkTheme() {
  //   return ThemeData(
  //     colorSchemeSeed:
  //         _viewModel.colorSelectionMethod == ColorSelectionMethod.colorSeed
  //         ? _viewModel.colorSelected.color
  //         : _viewModel.imageColorScheme.primary,
  //     useMaterial3: _useMaterial3,
  //     brightness: Brightness.dark,
  //   );
  // }
}
