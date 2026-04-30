import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/di/providers/repositories_providers.dart';
import '../../../core/constants/showcase_constants.dart';

class ShowcaseState {
  const ShowcaseState({
    this.colorSelected = ColorSeed.baseColor,
    this.imageSelected = ColorImageProvider.leaves,
    this.imageColorScheme = const ColorScheme.light(),
    this.colorSelectionMethod = ColorSelectionMethod.colorSeed,
    this.selectedScreenIndex = 0,
  });

  final ColorSeed colorSelected;
  final ColorImageProvider imageSelected;
  final ColorScheme imageColorScheme;
  final ColorSelectionMethod colorSelectionMethod;
  final int selectedScreenIndex;

  ShowcaseState copyWith({
    ColorSeed? colorSelected,
    ColorImageProvider? imageSelected,
    ColorScheme? imageColorScheme,
    ColorSelectionMethod? colorSelectionMethod,
    int? selectedScreenIndex,
  }) {
    return ShowcaseState(
      colorSelected: colorSelected ?? this.colorSelected,
      imageSelected: imageSelected ?? this.imageSelected,
      imageColorScheme: imageColorScheme ?? this.imageColorScheme,
      colorSelectionMethod: colorSelectionMethod ?? this.colorSelectionMethod,
      selectedScreenIndex: selectedScreenIndex ?? this.selectedScreenIndex,
    );
  }
}

class ShowcaseNotifier extends Notifier<ShowcaseState> {
  @override
  ShowcaseState build() => const ShowcaseState();

  void selectColor(int value) {
    state = state.copyWith(
      colorSelectionMethod: ColorSelectionMethod.colorSeed,
      colorSelected: ColorSeed.values[value],
    );
  }

  Future<void> selectImage(int value) async {
    final image = ColorImageProvider.values[value];
    final newScheme = await ref
        .read(showcaseThemeRepositoryProvider)
        .getColorSchemeFromImageUrl(image.url);
    state = state.copyWith(
      colorSelectionMethod: ColorSelectionMethod.image,
      imageSelected: image,
      imageColorScheme: newScheme,
    );
  }

  void selectScreen(int index) {
    if (state.selectedScreenIndex == index) {
      return;
    }
    state = state.copyWith(selectedScreenIndex: index);
  }
}
