import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vpn_proxy/features/vpn/services/vpn_server_health_service.dart';

String _encode(String config) => base64Encode(utf8.encode(config));

void main() {
  group('VpnServerHealthService endpoint parsing', () {
    final service = VpnServerHealthService();

    test('parses TCP remote endpoint', () {
      final endpoint = service.parseEndpoint(
        _encode('''
client
proto tcp
remote vpn.example.com 443
'''),
      );

      expect(endpoint?.host, 'vpn.example.com');
      expect(endpoint?.port, 443);
      expect(endpoint?.protocol, 'tcp');
      expect(endpoint?.isTcp, isTrue);
    });

    test('parses UDP protocol from remote line', () {
      final endpoint = service.parseEndpoint(
        _encode('''
client
remote 198.51.100.7 1194 udp
'''),
      );

      expect(endpoint?.host, '198.51.100.7');
      expect(endpoint?.port, 1194);
      expect(endpoint?.protocol, 'udp');
      expect(endpoint?.isUdp, isTrue);
    });

    test('returns null when remote is missing', () {
      final endpoint = service.parseEndpoint(_encode('proto tcp\nclient\n'));

      expect(endpoint, isNull);
    });

    test('returns null for invalid base64', () {
      final endpoint = service.parseEndpoint('not-base64');

      expect(endpoint, isNull);
    });
  });
}
