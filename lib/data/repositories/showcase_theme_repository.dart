import 'package:flutter/material.dart';
import 'package:zola/data/services/color_scheme_service.dart';

class ShowcaseThemeRepository {
  ShowcaseThemeRepository({required ColorSchemeService colorSchemeService})
    : _colorSchemeService = colorSchemeService;

  final ColorSchemeService _colorSchemeService;

  Future<ColorScheme> getColorSchemeFromImageUrl(String imageUrl) {
    return _colorSchemeService.fromImageUrl(imageUrl);
  }
}
