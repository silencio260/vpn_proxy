import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vpn_proxy/features/vpn/data/datasources/local/vpn_local_data_source.dart';
import 'package:vpn_proxy/features/vpn/domain/entities/vpn_server_health_entity.dart';

void main() {
  test(
    'server health cache returns fresh entries and drops expired ones',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final dataSource = VpnLocalDataSourceImpl(prefs: prefs);
      final checkedAt = DateTime(2026, 5, 24, 10);

      await dataSource.cacheServerHealth(
        VpnServerHealthEntity(
          serverKey: 'vpn-a',
          status: VpnServerHealthStatus.online,
          latencyMs: 42,
          checkedAt: checkedAt,
        ),
      );

      final fresh = await dataSource.getCachedServerHealth(
        now: checkedAt.add(const Duration(hours: 9, minutes: 59)),
        ttl: const Duration(hours: 10),
      );
      expect(fresh.keys, contains('vpn-a'));
      expect(fresh['vpn-a']?.status, VpnServerHealthStatus.online);
      expect(fresh['vpn-a']?.latencyMs, 42);

      final expired = await dataSource.getCachedServerHealth(
        now: checkedAt.add(const Duration(hours: 10, minutes: 1)),
        ttl: const Duration(hours: 10),
      );
      expect(expired, isEmpty);
    },
  );
}
