import 'package:flutter/material.dart';

class ColorSchemeService {
  Future<ColorScheme> fromImageUrl(String imageUrl) {
    return ColorScheme.fromImageProvider(provider: NetworkImage(imageUrl));
  }
}
