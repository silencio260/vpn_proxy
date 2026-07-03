import 'package:equatable/equatable.dart';

/// How the tunnel presents itself on the wire. Both modes route ALL device
/// traffic through the encrypted Xray tunnel (`proxyOnly` is never used) —
/// the difference is server selection:
///
/// - [stealth] (default): auto-select prefers TLS-camouflaged servers
///   (trojan / vless+tls …) so traffic is indistinguishable from ordinary
///   HTTPS and networks can't detect proxy use.
/// - [vpn]: no server restriction; plain encrypted proxying.
enum ConnectionMode { stealth, vpn }

/// User-tunable connection settings, persisted by
/// `ConnectionSettingsLocalDataSource` and exposed via
/// `ConnectionSettingsCubit`.
class ConnectionSettingsEntity extends Equatable {
  final ConnectionMode mode;

  /// Android package names excluded from the tunnel (split tunneling) —
  /// passed to the engine as `blockedApps` so their traffic uses the normal
  /// network instead of the proxy.
  final Set<String> excludedApps;

  const ConnectionSettingsEntity({
    this.mode = ConnectionMode.stealth,
    this.excludedApps = const {},
  });

  ConnectionSettingsEntity copyWith({
    ConnectionMode? mode,
    Set<String>? excludedApps,
  }) =>
      ConnectionSettingsEntity(
        mode: mode ?? this.mode,
        excludedApps: excludedApps ?? this.excludedApps,
      );

  @override
  List<Object?> get props => [mode, excludedApps];
}
