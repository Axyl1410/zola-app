import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zola/data/repositories/showcase_theme_repository.dart';
import 'package:zola/data/services/color_scheme_service.dart';
import 'package:zola/ui/core/constants/showcase_constants.dart';
import 'package:zola/ui/features/showcase/view_models/showcase_view_model.dart';

void main() {
  group('ShowcaseViewModel', () {
    test('selectColor updates selected color and method', () {
      final viewModel = ShowcaseViewModel(
        themeRepository: _FakeShowcaseThemeRepository(),
      );

      viewModel.selectColor(ColorSeed.values.length - 1);

      expect(viewModel.colorSelectionMethod, ColorSelectionMethod.colorSeed);
      expect(viewModel.colorSelected, ColorSeed.values.last);
    });

    test('selectImage updates image selection and scheme from repository', () async {
      final fakeRepository = _FakeShowcaseThemeRepository();
      final viewModel = ShowcaseViewModel(themeRepository: fakeRepository);

      await viewModel.selectImage(ColorImageProvider.leaves.index);

      expect(viewModel.colorSelectionMethod, ColorSelectionMethod.image);
      expect(viewModel.imageSelected, ColorImageProvider.leaves);
      expect(viewModel.imageColorScheme, fakeRepository.schemeToReturn);
      expect(fakeRepository.lastRequestedUrl, ColorImageProvider.leaves.url);
    });

    test('selectScreen ignores same index and updates on new index', () {
      final viewModel = ShowcaseViewModel(
        themeRepository: _FakeShowcaseThemeRepository(),
      );
      final initialIndex = viewModel.selectedScreenIndex;

      viewModel.selectScreen(initialIndex);
      expect(viewModel.selectedScreenIndex, initialIndex);

      viewModel.selectScreen(ScreenSelected.typography.value);
      expect(viewModel.selectedScreenIndex, ScreenSelected.typography.value);
    });
  });
}

class _FakeShowcaseThemeRepository extends ShowcaseThemeRepository {
  _FakeShowcaseThemeRepository()
    : super(colorSchemeService: _NoopColorSchemeService());

  String? lastRequestedUrl;
  final ColorScheme schemeToReturn = const ColorScheme.dark();

  @override
  Future<ColorScheme> getColorSchemeFromImageUrl(String imageUrl) async {
    lastRequestedUrl = imageUrl;
    return schemeToReturn;
  }
}

class _NoopColorSchemeService extends ColorSchemeService {
  @override
  Future<ColorScheme> fromImageUrl(String imageUrl) async {
    return const ColorScheme.light();
  }
}
