import 'package:flutter/material.dart';

import '../services/color_scheme_service.dart';

class ShowcaseThemeRepository {
  ShowcaseThemeRepository({ColorSchemeService? colorSchemeService})
    : _colorSchemeService = colorSchemeService ?? ColorSchemeService();

  final ColorSchemeService _colorSchemeService;

  Future<ColorScheme> getColorSchemeFromImageUrl(String imageUrl) {
    return _colorSchemeService.fromImageUrl(imageUrl);
  }
}
