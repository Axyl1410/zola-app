import 'package:flutter/material.dart';

import '../../../../data/repositories/showcase_theme_repository.dart';
import '../../../core/constants/showcase_constants.dart';

class ShowcaseViewModel extends ChangeNotifier {
  ShowcaseViewModel({ShowcaseThemeRepository? themeRepository})
    : _themeRepository = themeRepository ?? ShowcaseThemeRepository();

  final ShowcaseThemeRepository _themeRepository;

  ColorSeed _colorSelected = ColorSeed.baseColor;
  ColorImageProvider _imageSelected = ColorImageProvider.leaves;
  ColorScheme _imageColorScheme = const ColorScheme.light();
  ColorSelectionMethod _colorSelectionMethod = ColorSelectionMethod.colorSeed;
  int _selectedScreenIndex = ScreenSelected.component.value;

  ColorSeed get colorSelected => _colorSelected;
  ColorImageProvider get imageSelected => _imageSelected;
  ColorScheme get imageColorScheme => _imageColorScheme;
  ColorSelectionMethod get colorSelectionMethod => _colorSelectionMethod;
  int get selectedScreenIndex => _selectedScreenIndex;

  void selectColor(int value) {
    _colorSelectionMethod = ColorSelectionMethod.colorSeed;
    _colorSelected = ColorSeed.values[value];
    notifyListeners();
  }

  Future<void> selectImage(int value) async {
    final image = ColorImageProvider.values[value];
    final newScheme = await _themeRepository.getColorSchemeFromImageUrl(
      image.url,
    );
    _colorSelectionMethod = ColorSelectionMethod.image;
    _imageSelected = image;
    _imageColorScheme = newScheme;
    notifyListeners();
  }

  void selectScreen(int index) {
    if (_selectedScreenIndex == index) {
      return;
    }
    _selectedScreenIndex = index;
    notifyListeners();
  }
}
