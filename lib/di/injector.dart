import 'package:get_it/get_it.dart';

import '../data/repositories/auth_session_repository.dart';
import '../data/repositories/showcase_theme_repository.dart';
import '../data/repositories/todo_repository.dart';
import '../data/services/api_client.dart';
import '../data/services/color_scheme_service.dart';
import '../data/services/secure_storage_service.dart';
import '../data/services/todo_remote_service.dart';
import '../ui/features/home/view_models/school_view_model.dart';
import '../ui/features/showcase/view_models/showcase_view_model.dart';

final GetIt sl = GetIt.instance;

void setupDependencies() {
  // Data layer
  if (!sl.isRegistered<ColorSchemeService>()) {
    sl.registerLazySingleton<ColorSchemeService>(ColorSchemeService.new);
  }
  if (!sl.isRegistered<SecureStorageService>()) {
    sl.registerLazySingleton<SecureStorageService>(SecureStorageService.new);
  }
  if (!sl.isRegistered<ShowcaseThemeRepository>()) {
    sl.registerLazySingleton<ShowcaseThemeRepository>(
      () => ShowcaseThemeRepository(colorSchemeService: sl()),
    );
  }
  if (!sl.isRegistered<AuthSessionRepository>()) {
    sl.registerLazySingleton<AuthSessionRepository>(
      () => AuthSessionRepository(secureStorageService: sl()),
    );
  }
  if (!sl.isRegistered<ApiClient>()) {
    sl.registerLazySingleton<ApiClient>(
      () => ApiClient(authSessionRepository: sl()),
    );
  }
  if (!sl.isRegistered<TodoRemoteService>()) {
    sl.registerLazySingleton<TodoRemoteService>(
      () => TodoRemoteService(apiClient: sl()),
    );
  }
  if (!sl.isRegistered<TodoRepository>()) {
    sl.registerLazySingleton<TodoRepository>(
      () => TodoRepository(todoRemoteService: sl()),
    );
  }

  // Presentation layer
  if (!sl.isRegistered<ShowcaseViewModel>()) {
    sl.registerFactory<ShowcaseViewModel>(
      () => ShowcaseViewModel(themeRepository: sl()),
    );
  }
  if (!sl.isRegistered<SchoolViewModel>()) {
    sl.registerFactory<SchoolViewModel>(
      () => SchoolViewModel(todoRepository: sl()),
    );
  }
}
