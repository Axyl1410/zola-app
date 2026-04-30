import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zola/data/repositories/showcase_theme_repository.dart';
import 'package:zola/data/services/color_scheme_service.dart';
import 'package:zola/di/providers.dart';
import 'package:zola/ui/core/constants/showcase_constants.dart';

void main() {
  group('ShowcaseNotifier', () {
    test('selectColor updates selected color and method', () {
      final container = ProviderContainer(
        overrides: [
          showcaseThemeRepositoryProvider.overrideWithValue(
            _FakeShowcaseThemeRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(showcaseNotifierProvider.notifier);

      notifier.selectColor(ColorSeed.values.length - 1);
      final state = container.read(showcaseNotifierProvider);

      expect(state.colorSelectionMethod, ColorSelectionMethod.colorSeed);
      expect(state.colorSelected, ColorSeed.values.last);
    });

    test(
      'selectImage updates image selection and scheme from repository',
      () async {
        final fakeRepository = _FakeShowcaseThemeRepository();
        final container = ProviderContainer(
          overrides: [
            showcaseThemeRepositoryProvider.overrideWithValue(fakeRepository),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(showcaseNotifierProvider.notifier);

        await notifier.selectImage(ColorImageProvider.leaves.index);
        final state = container.read(showcaseNotifierProvider);

        expect(state.colorSelectionMethod, ColorSelectionMethod.image);
        expect(state.imageSelected, ColorImageProvider.leaves);
        expect(state.imageColorScheme, fakeRepository.schemeToReturn);
        expect(fakeRepository.lastRequestedUrl, ColorImageProvider.leaves.url);
      },
    );

    test('selectScreen ignores same index and updates on new index', () {
      final container = ProviderContainer(
        overrides: [
          showcaseThemeRepositoryProvider.overrideWithValue(
            _FakeShowcaseThemeRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(showcaseNotifierProvider.notifier);
      final initialIndex = container
          .read(showcaseNotifierProvider)
          .selectedScreenIndex;

      notifier.selectScreen(initialIndex);
      expect(
        container.read(showcaseNotifierProvider).selectedScreenIndex,
        initialIndex,
      );

      notifier.selectScreen(ScreenSelected.typography.value);
      expect(
        container.read(showcaseNotifierProvider).selectedScreenIndex,
        ScreenSelected.typography.value,
      );
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
