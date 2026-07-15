import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';

import '../../../core/constants/app_packages.dart';
import '../../../core/utils/app_constants.dart';
import '../../vpn/data/models/vpn_status_model.dart';
import '../domain/entities/proxy_entity.dart';

/// Wraps the Xray-core Android VpnService (via `flutter_v2ray`) so the app can
/// dial the vless/vmess/trojan/shadowsocks share links published in the
/// Firestore proxy list. Mirrors [VpnEngineService]'s surface (two broadcast
/// streams + start/stop) so a connection bloc can consume either engine the
/// same way — stage strings are normalised to the same lowercase tokens the
/// connection state-machine already understands ('connected'/'connecting'/
/// 'disconnected'/'error').
class ProxyEngineService {
  late final FlutterV2ray _engine;
  Future<void>? _initFuture;

  final _stageController = StreamController<String>.broadcast();
  final _statusController = StreamController<VpnStatusModel>.broadcast();

  Stream<String> get stageStream => _stageController.stream;
  Stream<VpnStatusModel> get statusStream => _statusController.stream;

  ProxyEngineService() {
    _engine = FlutterV2ray(
      onStatusChanged: (status) {
        _stageController.add(_mapState(status.state));
        _statusController.add(
          VpnStatusModel(
            duration: status.duration,
            byteIn: _formatSpeed(status.downloadSpeed),
            byteOut: _formatSpeed(status.uploadSpeed),
            lastPacketReceive: '0',
          ),
        );
      },
    );
    _initFuture = _engine.initializeV2Ray();
  }

  Future<void> _ensureInitialized() =>
      _initFuture ??= _engine.initializeV2Ray();

  /// [blockedApps] — Android package names excluded from the tunnel (split
  /// tunneling); their traffic bypasses the proxy and uses the normal network.
  ///
  /// This app's own package ([kOwnPackageName]) is always added to that set so
  /// the app's own traffic — ad requests, Firebase/Firestore, analytics —
  /// egresses on the real network instead of the user's exit node. It is forced
  /// (never user-configurable) and is also hidden from the split-tunnel picker,
  /// so users cannot route it back through the tunnel.
  Future<void> startProxy(
    ProxyEntity proxy, {
    List<String> blockedApps = const [],
  }) async {
    await _ensureInitialized();

    // Always exclude ourselves, de-duplicated. Never empty, so it is always
    // passed through to the VpnService's disallowedApplications.
    final effectiveBlockedApps = <String>{...blockedApps, kOwnPackageName};

    // The `raw` field is a standard share link (ss://, vless://, vmess://,
    // trojan://). parseFromURL throws on anything it can't understand — let it
    // bubble up so the bloc surfaces a clear error rather than hanging.
    final V2RayURL parsed = FlutterV2ray.parseFromURL(proxy.raw);

    final granted = await _engine.requestPermission();
    if (!granted) throw Exception('VPN permission denied');

    final remark =
        parsed.remark.isNotEmpty
            ? parsed.remark
            : (proxy.remark.isNotEmpty ? proxy.remark : proxy.address);

    debugPrint('[PROXY] starting Xray for ${proxy.type} → $remark');
    await _engine.startV2Ray(
      remark: remark,
      config: _withLocalHttpInbound(parsed.getFullConfiguration()),
      blockedApps: effectiveBlockedApps.toList(),
      // Always run the full VpnService tunnel — stealth vs vpn mode is a
      // server-selection concern (TLS camouflage), never proxyOnly.
      proxyOnly: false,
    );
  }

  /// Performs a real Xray outbound test without starting Android's VPN service.
  /// A positive delay proves that the share-link configuration can carry an
  /// HTTPS request; `-1` means the proxy/configuration could not be used.
  Future<int> getServerDelay(
    ProxyEntity proxy, {
    String testUrl = 'https://www.google.com/generate_204',
  }) async {
    await _ensureInitialized();
    final parsed = FlutterV2ray.parseFromURL(proxy.raw);
    return _engine.getServerDelay(
      config: parsed.getFullConfiguration(),
      url: testUrl,
    );
  }

  /// Validates the currently running outbound. The plugin returns `-1` when
  /// the core is not connected or the test request cannot traverse the proxy.
  Future<int> getConnectedServerDelay({
    String testUrl = 'https://www.google.com/generate_204',
  }) async {
    await _ensureInitialized();
    return _engine.getConnectedServerDelay(url: testUrl);
  }

  /// Append a local HTTP proxy inbound to the Xray config so in-app requests
  /// can opt into the tunnel by proxying through 127.0.0.1 (this app itself is
  /// excluded from the VpnService tunnel). Xray forwards them to the active
  /// outbound, so they egress at the exit node. Falls back to the original
  /// config untouched if the JSON is not in the expected shape.
  String _withLocalHttpInbound(String config) {
    try {
      final map = jsonDecode(config) as Map<String, dynamic>;
      final inbounds =
          (map['inbounds'] as List?)?.cast<dynamic>() ?? <dynamic>[];
      inbounds.add({
        'tag': 'in_http_local',
        'listen': '127.0.0.1',
        'port': AppConstants.localHttpProxyPort,
        'protocol': 'http',
        'settings': <String, dynamic>{},
      });
      map['inbounds'] = inbounds;
      return jsonEncode(map);
    } catch (e) {
      debugPrint('[PROXY] could not add local http inbound: $e');
      return config;
    }
  }

  Future<void> stopProxy() async {
    await _engine.stopV2Ray();
  }

  void dispose() {
    _stageController.close();
    _statusController.close();
  }

  /// Normalise the plugin's status string to the tokens the connection bloc's
  /// stage-mapper expects. The native side reports values like "CONNECTED" /
  /// "DISCONNECTED"; match defensively in case a version prefixes them.
  String _mapState(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('disconnected')) return 'disconnected';
    if (s.contains('connected')) return 'connected';
    if (s.contains('connecting')) return 'connecting';
    if (s.contains('error')) return 'error';
    return s;
  }

  String _formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond <= 0) return '0 KB/s';
    const kb = 1024;
    const mb = 1024 * 1024;
    if (bytesPerSecond >= mb) {
      return '${(bytesPerSecond / mb).toStringAsFixed(1)} MB/s';
    }
    if (bytesPerSecond >= kb) {
      return '${(bytesPerSecond / kb).toStringAsFixed(1)} KB/s';
    }
    return '$bytesPerSecond B/s';
  }
}
