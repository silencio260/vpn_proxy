import 'dart:convert';
import 'dart:io';

import '../utils/app_constants.dart';

/// Result of a dev IP/location lookup.
class DevIpResult {
  final String ip;
  final String location;
  final String isp;
  const DevIpResult({
    required this.ip,
    required this.location,
    required this.isp,
  });
}

/// Developer-only IP/location lookups for the Profile → Developer section.
///
/// Two paths, and the difference is the whole point:
///  • [viaTunnel] = false — a plain request. This app is excluded from the
///    VpnService tunnel, so it egresses on the real network → real IP.
///  • [viaTunnel] = true — proxied through the local Xray HTTP inbound
///    (127.0.0.1:[AppConstants.localHttpProxyPort]), which forwards to the
///    active outbound → tunnel exit IP. Only meaningful while connected.
///
/// Uses https://ipwho.is (free, HTTPS, keyless). The legacy ip-api.com
/// endpoint is HTTP-only, which Android blocks as cleartext by default.
class DevIpCheck {
  static Future<DevIpResult> fetch({required bool viaTunnel}) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12);
    if (viaTunnel) {
      client.findProxy =
          (_) => 'PROXY 127.0.0.1:${AppConstants.localHttpProxyPort}';
    }
    try {
      final request = await client.getUrl(Uri.parse('https://ipwho.is/'));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['success'] == false) {
        throw Exception(json['message'] ?? 'lookup failed');
      }
      final city = (json['city'] as String?) ?? '';
      final region = (json['region'] as String?) ?? '';
      final country = (json['country'] as String?) ?? '';
      final parts =
          [city, region, country].where((s) => s.isNotEmpty).toList();
      return DevIpResult(
        ip: (json['ip'] as String?) ?? 'unknown',
        location: parts.isEmpty ? 'unknown' : parts.join(', '),
        isp: ((json['connection'] as Map<String, dynamic>?)?['isp']
                as String?) ??
            '',
      );
    } finally {
      client.close();
    }
  }
}
