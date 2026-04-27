import 'package:get_it/get_it.dart';
import 'package:zola/di/injector.dart';

typedef TestDependencyOverrides = void Function(GetIt serviceLocator);

Future<void> setupTestDependencies({
  TestDependencyOverrides? overrides,
}) async {
  await sl.reset();
  setupDependencies();
  overrides?.call(sl);
}

Future<void> resetTestDependencies() {
  return sl.reset();
}
