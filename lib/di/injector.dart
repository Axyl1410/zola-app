import 'package:get_it/get_it.dart';
import 'package:zola/data/repositories/auth_backend_repository.dart';
import 'package:zola/data/repositories/auth_session_repository.dart';
import 'package:zola/data/repositories/google_auth_repository.dart';
import 'package:zola/data/repositories/showcase_theme_repository.dart';
import 'package:zola/data/repositories/todo_repository.dart';
import 'package:zola/data/services/api_client.dart';
import 'package:zola/data/services/auth_remote_service.dart';
import 'package:zola/data/services/color_scheme_service.dart';
import 'package:zola/data/services/google_sign_in_service.dart';
import 'package:zola/data/services/secure_storage_service.dart';
import 'package:zola/data/services/todo_remote_service.dart';
import 'package:zola/ui/features/discover/view_models/school_view_model.dart';
import 'package:zola/ui/features/messages/view_models/messages_view_model.dart';
import 'package:zola/ui/features/showcase/view_models/showcase_view_model.dart';

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
  if (!sl.isRegistered<AuthRemoteService>()) {
    sl.registerLazySingleton<AuthRemoteService>(
      () => AuthRemoteService(apiClient: sl()),
    );
  }
  if (!sl.isRegistered<GoogleSignInService>()) {
    sl.registerLazySingleton<GoogleSignInService>(GoogleSignInService.new);
  }
  if (!sl.isRegistered<GoogleAuthRepository>()) {
    sl.registerLazySingleton<GoogleAuthRepository>(
      () => GoogleAuthRepository(googleSignInService: sl()),
    );
  }
  if (!sl.isRegistered<AuthBackendRepository>()) {
    sl.registerLazySingleton<AuthBackendRepository>(
      () => AuthBackendRepository(authRemoteService: sl()),
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
  if (!sl.isRegistered<MessagesViewModel>()) {
    sl.registerFactory<MessagesViewModel>(
      () => MessagesViewModel(
        googleAuthRepository: sl(),
        authBackendRepository: sl(),
      ),
    );
  }
}
