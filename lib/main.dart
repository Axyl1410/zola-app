// Copyright 2021 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'ui/core/constants/showcase_constants.dart';
import 'ui/features/showcase/views/home_view.dart';
import 'ui/features/showcase/view_models/showcase_view_model.dart';

void main() async {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  static const bool _useMaterial3 = true;
  static const ThemeMode _themeMode = ThemeMode.system;
  final ShowcaseViewModel _viewModel = ShowcaseViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Teamo',
        themeMode: _themeMode,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        home: Home(useMaterial3: _useMaterial3, viewModel: _viewModel),
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

  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorSchemeSeed:
          _viewModel.colorSelectionMethod == ColorSelectionMethod.colorSeed
          ? _viewModel.colorSelected.color
          : _viewModel.imageColorScheme.primary,
      useMaterial3: _useMaterial3,
      brightness: Brightness.dark,
    );
  }
}
