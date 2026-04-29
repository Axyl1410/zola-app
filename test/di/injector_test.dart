import 'package:flutter_test/flutter_test.dart';
import 'package:zola/data/repositories/auth_session_repository.dart';
import 'package:zola/data/repositories/google_auth_repository.dart';
import 'package:zola/data/repositories/showcase_theme_repository.dart';
import 'package:zola/data/repositories/todo_repository.dart';
import 'package:zola/data/services/api_client.dart';
import 'package:zola/data/services/color_scheme_service.dart';
import 'package:zola/data/services/google_sign_in_service.dart';
import 'package:zola/data/services/secure_storage_service.dart';
import 'package:zola/data/services/todo_remote_service.dart';
import 'package:zola/di/injector.dart';
import 'package:zola/ui/features/discover/view_models/school_view_model.dart';
import 'package:zola/ui/features/messages/view_models/messages_view_model.dart';
import 'package:zola/ui/features/showcase/view_models/showcase_view_model.dart';

void main() {
  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('setupDependencies registers all expected dependencies', () {
    setupDependencies();

    expect(sl.isRegistered<ColorSchemeService>(), isTrue);
    expect(sl.isRegistered<SecureStorageService>(), isTrue);
    expect(sl.isRegistered<ShowcaseThemeRepository>(), isTrue);
    expect(sl.isRegistered<AuthSessionRepository>(), isTrue);
    expect(sl.isRegistered<ApiClient>(), isTrue);
    expect(sl.isRegistered<TodoRemoteService>(), isTrue);
    expect(sl.isRegistered<TodoRepository>(), isTrue);
    expect(sl.isRegistered<GoogleSignInService>(), isTrue);
    expect(sl.isRegistered<GoogleAuthRepository>(), isTrue);
    expect(sl.isRegistered<ShowcaseViewModel>(), isTrue);
    expect(sl.isRegistered<SchoolViewModel>(), isTrue);
    expect(sl.isRegistered<MessagesViewModel>(), isTrue);
  });

  test('ShowcaseViewModel is factory and services are singletons', () {
    setupDependencies();

    final viewModelA = sl<ShowcaseViewModel>();
    final viewModelB = sl<ShowcaseViewModel>();
    final apiClientA = sl<ApiClient>();
    final apiClientB = sl<ApiClient>();

    expect(identical(viewModelA, viewModelB), isFalse);
    expect(identical(apiClientA, apiClientB), isTrue);
  });

  test('MessagesViewModel is factory and Google auth dependencies are singletons', () {
    setupDependencies();

    final viewModelA = sl<MessagesViewModel>();
    final viewModelB = sl<MessagesViewModel>();
    final repositoryA = sl<GoogleAuthRepository>();
    final repositoryB = sl<GoogleAuthRepository>();
    final serviceA = sl<GoogleSignInService>();
    final serviceB = sl<GoogleSignInService>();

    expect(identical(viewModelA, viewModelB), isFalse);
    expect(identical(repositoryA, repositoryB), isTrue);
    expect(identical(serviceA, serviceB), isTrue);
  });
}
