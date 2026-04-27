import 'package:get_it/get_it.dart';

import '../data/repositories/auth_session_repository.dart';
import '../data/repositories/showcase_theme_repository.dart';
import '../data/services/color_scheme_service.dart';
import '../data/services/secure_storage_service.dart';
import '../ui/features/showcase/view_models/showcase_view_model.dart';

final GetIt sl = GetIt.instance;

void setupDependencies() {
  if (sl.isRegistered<ShowcaseViewModel>()) {
    return;
  }

  // Data layer
  sl.registerLazySingleton<ColorSchemeService>(ColorSchemeService.new);
  sl.registerLazySingleton<SecureStorageService>(SecureStorageService.new);
  sl.registerLazySingleton<ShowcaseThemeRepository>(
    () => ShowcaseThemeRepository(colorSchemeService: sl()),
  );
  sl.registerLazySingleton<AuthSessionRepository>(
    () => AuthSessionRepository(secureStorageService: sl()),
  );

  // Presentation layer
  sl.registerFactory<ShowcaseViewModel>(
    () => ShowcaseViewModel(themeRepository: sl()),
  );
}
