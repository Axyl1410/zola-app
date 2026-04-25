// Copyright 2021 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'src/constants.dart';
import 'src/home.dart';

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
  ColorSeed _colorSelected = ColorSeed.baseColor;
  ColorImageProvider _imageSelected = ColorImageProvider.leaves;
  ColorScheme? _imageColorScheme = const ColorScheme.light();
  ColorSelectionMethod _colorSelectionMethod = ColorSelectionMethod.colorSeed;

  void _handleColorSelect(int value) {
    setState(() {
      _colorSelectionMethod = ColorSelectionMethod.colorSeed;
      _colorSelected = ColorSeed.values[value];
    });
  }

  void _handleImageSelect(int value) {
    final String url = ColorImageProvider.values[value].url;
    ColorScheme.fromImageProvider(provider: NetworkImage(url)).then((
      newScheme,
    ) {
      setState(() {
        _colorSelectionMethod = ColorSelectionMethod.image;
        _imageSelected = ColorImageProvider.values[value];
        _imageColorScheme = newScheme;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material 3',
      themeMode: _themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: Home(
        useMaterial3: _useMaterial3,
        colorSelected: _colorSelected,
        imageSelected: _imageSelected,
        handleColorSelect: _handleColorSelect,
        handleImageSelect: _handleImageSelect,
        colorSelectionMethod: _colorSelectionMethod,
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      colorSchemeSeed: _colorSelectionMethod == ColorSelectionMethod.colorSeed
          ? _colorSelected.color
          : null,
      colorScheme: _colorSelectionMethod == ColorSelectionMethod.image
          ? _imageColorScheme
          : null,
      useMaterial3: _useMaterial3,
      brightness: Brightness.light,
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorSchemeSeed: _colorSelectionMethod == ColorSelectionMethod.colorSeed
          ? _colorSelected.color
          : _imageColorScheme!.primary,
      useMaterial3: _useMaterial3,
      brightness: Brightness.dark,
    );
  }
}
