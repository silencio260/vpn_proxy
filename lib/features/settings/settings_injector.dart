import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/datasources/connection_settings_local_data_source.dart';
import 'data/datasources/installed_apps_data_source.dart';
import 'presentation/cubit/connection_settings_cubit.dart';

/// Registers the settings feature's dependencies. Must run after `initVpn(sl)`
/// since it reuses the `SharedPreferences` singleton registered there.
Future<void> initSettings(GetIt sl) async {
  // Data sources
  sl.registerLazySingleton<ConnectionSettingsLocalDataSource>(
    () => ConnectionSettingsLocalDataSourceImpl(prefs: sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<InstalledAppsDataSource>(
    () => InstalledAppsDataSourceImpl(),
  );

  // Cubit — a singleton (not a factory) because ProxyConnectionBloc reads the
  // live settings at connect time and the profile/split-tunneling screens
  // mutate the same instance.
  sl.registerLazySingleton<ConnectionSettingsCubit>(
    () => ConnectionSettingsCubit(
      dataSource: sl<ConnectionSettingsLocalDataSource>(),
    ),
  );
}
