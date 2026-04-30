import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zola/data/services/color_scheme_service.dart';
import 'package:zola/data/services/google_sign_in_service.dart';
import 'package:zola/data/services/secure_storage_service.dart';

final colorSchemeServiceProvider = Provider<ColorSchemeService>((ref) {
  return ColorSchemeService();
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService();
});
