import 'entities/vpn_server_entity.dart';
import 'entities/vpn_server_health_entity.dart';

class VpnServerQualitySorter {
  static int compare(
    VpnServerEntity a,
    VpnServerEntity b,
    Map<String, VpnServerHealthEntity> health,
  ) {
    final aHealth = health[keyForServer(a)];
    final bHealth = health[keyForServer(b)];
    final status = _statusRank(aHealth).compareTo(_statusRank(bHealth));
    if (status != 0) return status;

    final signal = _signalRank(b, bHealth).compareTo(_signalRank(a, aHealth));
    if (signal != 0) return signal;

    final speed = b.speed.compareTo(a.speed);
    if (speed != 0) return speed;

    final latency = _latency(a, aHealth).compareTo(_latency(b, bHealth));
    if (latency != 0) return latency;

    return a.countryLong.compareTo(b.countryLong);
  }

  static int _statusRank(VpnServerHealthEntity? health) {
    return switch (health?.status ?? VpnServerHealthStatus.unknown) {
      VpnServerHealthStatus.online => 0,
      VpnServerHealthStatus.unknown => 1,
      VpnServerHealthStatus.checking => 1,
      VpnServerHealthStatus.offline => 2,
    };
  }

  static int _signalRank(
    VpnServerEntity server,
    VpnServerHealthEntity? health,
  ) {
    final p = health?.latencyMs ?? int.tryParse(server.ping) ?? 0;
    if (p == 0) return 2;
    if (p < 60) return 4;
    if (p < 120) return 3;
    if (p < 200) return 2;
    return 1;
  }

  static int _latency(VpnServerEntity server, VpnServerHealthEntity? health) {
    return health?.latencyMs ?? int.tryParse(server.ping) ?? 999999;
  }

  static String keyForServer(VpnServerEntity server) {
    if (server.ip.trim().isNotEmpty) return server.ip.trim();
    if (server.hostname.trim().isNotEmpty) return server.hostname.trim();
    return server.openVpnConfigBase64.hashCode.toString();
  }
}
