import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/connection_settings_entity.dart';

/// Persists the connection settings (mode + split-tunnel exclusions) to
/// SharedPreferences, mirroring the storage style used by the proxy/vpn
/// local data sources.
abstract class ConnectionSettingsLocalDataSource {
  ConnectionSettingsEntity getSettings();
  Future<void> saveMode(ConnectionMode mode);
  Future<void> saveExcludedApps(Set<String> packages);
}

class ConnectionSettingsLocalDataSourceImpl
    implements ConnectionSettingsLocalDataSource {
  final SharedPreferences prefs;
  ConnectionSettingsLocalDataSourceImpl({required this.prefs});

  static const _modeKey = 'connection_mode';
  static const _excludedAppsKey = 'split_tunnel_excluded_apps';

  @override
  ConnectionSettingsEntity getSettings() => ConnectionSettingsEntity(
        mode: _decodeMode(prefs.getString(_modeKey)),
        excludedApps: (prefs.getStringList(_excludedAppsKey) ?? []).toSet(),
      );

  @override
  Future<void> saveMode(ConnectionMode mode) =>
      prefs.setString(_modeKey, mode.name);

  @override
  Future<void> saveExcludedApps(Set<String> packages) =>
      prefs.setStringList(_excludedAppsKey, packages.toList()..sort());

  /// Stealth is the default for unknown/missing values.
  static ConnectionMode _decodeMode(String? raw) =>
      raw == ConnectionMode.vpn.name ? ConnectionMode.vpn : ConnectionMode.stealth;
}
