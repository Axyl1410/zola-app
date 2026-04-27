import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zola/data/repositories/showcase_theme_repository.dart';
import 'package:zola/data/services/color_scheme_service.dart';

void main() {
  group('ShowcaseThemeRepository', () {
    test('delegates image url to service and returns scheme', () async {
      final fakeService = _FakeColorSchemeService();
      final repository = ShowcaseThemeRepository(colorSchemeService: fakeService);

      final result = await repository.getColorSchemeFromImageUrl(
        'https://example.com/image.png',
      );

      expect(fakeService.lastImageUrl, 'https://example.com/image.png');
      expect(result, fakeService.schemeToReturn);
    });
  });
}

class _FakeColorSchemeService extends ColorSchemeService {
  String? lastImageUrl;
  final ColorScheme schemeToReturn = const ColorScheme.dark();

  @override
  Future<ColorScheme> fromImageUrl(String imageUrl) async {
    lastImageUrl = imageUrl;
    return schemeToReturn;
  }
}
