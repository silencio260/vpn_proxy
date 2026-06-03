import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vpn_proxy/core/utils/app_colors.dart';
import 'package:vpn_proxy/features/vpn/domain/entities/vpn_server_entity.dart';
import 'package:vpn_proxy/features/vpn/domain/entities/vpn_server_health_entity.dart';
import 'package:vpn_proxy/features/vpn/presentation/widgets/vpn_server_card.dart';

void main() {
  testWidgets(
    'server card renders health, signal, speed, and upload placeholder',
    (tester) async {
      final server = VpnServerEntity(
        hostname: 'vpn.example.com',
        ip: '203.0.113.8',
        ping: '95',
        speed: 80000000,
        countryLong: 'United States',
        countryShort: 'US',
        numVpnSessions: 3,
        openVpnConfigBase64: 'config',
      );
      final health = VpnServerHealthEntity(
        serverKey: '203.0.113.8',
        status: VpnServerHealthStatus.online,
        latencyMs: 42,
        checkedAt: DateTime(2026, 5, 24),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppPalette.light]),
          home: Scaffold(
            body: VpnServerCard(
              server: server,
              health: health,
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Online'), findsOneWidget);
      expect(find.text('42ms'), findsOneWidget);
      expect(find.text('Down 80 Mbps'), findsOneWidget);
      expect(find.text('Up —'), findsOneWidget);
    },
  );
}
