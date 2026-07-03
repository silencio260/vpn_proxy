import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/analytics/app_analytics_service.dart';
import '../../data/datasources/connection_settings_local_data_source.dart';
import '../../domain/entities/connection_settings_entity.dart';

/// Holds the user's connection settings (stealth/vpn mode + split-tunnel
/// exclusions). Seeds its state synchronously from SharedPreferences (via the
/// data source) so consumers — including ProxyConnectionBloc at connect time —
/// always see persisted values without an async load step.
class ConnectionSettingsCubit extends Cubit<ConnectionSettingsEntity> {
  final ConnectionSettingsLocalDataSource dataSource;

  ConnectionSettingsCubit({required this.dataSource})
      : super(dataSource.getSettings());

  Future<void> setMode(ConnectionMode mode) async {
    if (mode == state.mode) return;
    emit(state.copyWith(mode: mode));
    AppAnalyticsService.instance.logConnectionModeChanged(mode.name);
    await dataSource.saveMode(mode);
  }

  Future<void> toggleVpnMode(bool enabled) =>
      setMode(enabled ? ConnectionMode.vpn : ConnectionMode.stealth);

  /// Adds/removes [packageName] from the split-tunnel exclusion set.
  Future<void> toggleAppExclusion(String packageName) async {
    final next = Set<String>.from(state.excludedApps);
    if (!next.remove(packageName)) next.add(packageName);
    emit(state.copyWith(excludedApps: next));
    await dataSource.saveExcludedApps(next);
  }
}
