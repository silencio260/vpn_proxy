import 'package:flutter_test/flutter_test.dart';
import 'package:vpn_proxy/features/vpn/domain/entities/vpn_server_entity.dart';
import 'package:vpn_proxy/features/vpn/domain/entities/vpn_server_health_entity.dart';
import 'package:vpn_proxy/features/vpn/domain/vpn_server_quality_sorter.dart';

VpnServerEntity _server({
  required String ip,
  required String country,
  required String ping,
  required int speed,
}) => VpnServerEntity(
  hostname: '$country.example.com',
  ip: ip,
  ping: ping,
  speed: speed,
  countryLong: country,
  countryShort: country.substring(0, 2).toUpperCase(),
  numVpnSessions: 1,
  openVpnConfigBase64: 'config-$ip',
);

void main() {
  test('sorts online servers first and offline servers last', () {
    final online = _server(
      ip: '10.0.0.1',
      country: 'Alpha',
      ping: '80',
      speed: 20000000,
    );
    final unknown = _server(
      ip: '10.0.0.2',
      country: 'Beta',
      ping: '20',
      speed: 90000000,
    );
    final offline = _server(
      ip: '10.0.0.3',
      country: 'Gamma',
      ping: '10',
      speed: 100000000,
    );
    final now = DateTime(2026, 5, 24);
    final health = {
      '10.0.0.1': VpnServerHealthEntity(
        serverKey: '10.0.0.1',
        status: VpnServerHealthStatus.online,
        latencyMs: 80,
        checkedAt: now,
      ),
      '10.0.0.3': VpnServerHealthEntity(
        serverKey: '10.0.0.3',
        status: VpnServerHealthStatus.offline,
        latencyMs: 10,
        checkedAt: now,
      ),
    };

    final sorted = [offline, unknown, online]
      ..sort((a, b) => VpnServerQualitySorter.compare(a, b, health));

    expect(sorted, [online, unknown, offline]);
  });

  test('uses stronger signal before provider download speed', () {
    final strong = _server(
      ip: '10.0.0.4',
      country: 'Delta',
      ping: '40',
      speed: 10000000,
    );
    final fastButWeak = _server(
      ip: '10.0.0.5',
      country: 'Echo',
      ping: '220',
      speed: 100000000,
    );

    final sorted = [fastButWeak, strong]
      ..sort((a, b) => VpnServerQualitySorter.compare(a, b, const {}));

    expect(sorted.first, strong);
  });
}
