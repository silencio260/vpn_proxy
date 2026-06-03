import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/entities/vpn_server_entity.dart';
import '../domain/entities/vpn_server_health_entity.dart';
import 'vpn_engine_service.dart';

class VpnConfigEndpoint {
  final String host;
  final int port;
  final String protocol;

  const VpnConfigEndpoint({
    required this.host,
    required this.port,
    required this.protocol,
  });

  bool get isTcp => protocol.toLowerCase().startsWith('tcp');
  bool get isUdp => protocol.toLowerCase().startsWith('udp');
}

class VpnServerHealthService {
  final VpnEngineService? vpnEngine;
  final Future<String> Function()? stageProvider;
  final Duration connectTimeout;

  const VpnServerHealthService({
    this.vpnEngine,
    this.stageProvider,
    this.connectTimeout = const Duration(seconds: 3),
  });

  static String keyForServer(VpnServerEntity server) {
    if (server.ip.trim().isNotEmpty) return server.ip.trim();
    if (server.hostname.trim().isNotEmpty) return server.hostname.trim();
    return server.openVpnConfigBase64.hashCode.toString();
  }

  VpnConfigEndpoint? parseEndpoint(String openVpnConfigBase64) {
    try {
      final decoded = utf8.decode(base64Decode(openVpnConfigBase64));
      return parseEndpointFromConfig(decoded);
    } catch (_) {
      return null;
    }
  }

  VpnConfigEndpoint? parseEndpointFromConfig(String config) {
    final lines = config
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    String? proto;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#') || line.startsWith(';')) {
        continue;
      }
      final parts = line.split(RegExp(r'\s+'));
      if (parts.isEmpty) continue;
      if (parts.first.toLowerCase() == 'proto' && parts.length > 1) {
        proto = parts[1].toLowerCase();
      }
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#') || line.startsWith(';')) {
        continue;
      }
      final parts = line.split(RegExp(r'\s+'));
      if (parts.isEmpty || parts.first.toLowerCase() != 'remote') continue;
      if (parts.length < 2) return null;

      final host = parts[1];
      final port = parts.length > 2 ? int.tryParse(parts[2]) ?? 1194 : 1194;
      final remoteProto = parts.length > 3 ? parts[3].toLowerCase() : null;
      return VpnConfigEndpoint(
        host: host,
        port: port,
        protocol: remoteProto ?? proto ?? 'udp',
      );
    }

    return null;
  }

  Future<VpnServerHealthEntity> checkServer(VpnServerEntity server) async {
    final key = keyForServer(server);
    final checkedAt = DateTime.now();
    final endpoint = parseEndpoint(server.openVpnConfigBase64);
    if (endpoint == null) {
      return VpnServerHealthEntity(
        serverKey: key,
        status: VpnServerHealthStatus.unknown,
        checkedAt: checkedAt,
      );
    }

    try {
      await InternetAddress.lookup(endpoint.host).timeout(connectTimeout);
    } catch (_) {
      return VpnServerHealthEntity(
        serverKey: key,
        status: VpnServerHealthStatus.offline,
        checkedAt: checkedAt,
      );
    }

    if (!endpoint.isTcp) {
      return VpnServerHealthEntity(
        serverKey: key,
        status: VpnServerHealthStatus.unknown,
        checkedAt: checkedAt,
      );
    }

    final watch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        endpoint.host,
        endpoint.port,
        timeout: connectTimeout,
      );
      watch.stop();
      socket.destroy();
      return VpnServerHealthEntity(
        serverKey: key,
        status: VpnServerHealthStatus.online,
        latencyMs: watch.elapsedMilliseconds,
        checkedAt: DateTime.now(),
      );
    } catch (_) {
      watch.stop();
      return VpnServerHealthEntity(
        serverKey: key,
        status: VpnServerHealthStatus.offline,
        latencyMs: watch.elapsedMilliseconds,
        checkedAt: DateTime.now(),
      );
    }
  }

  Future<bool> get isVpnBusy async {
    try {
      final provider = stageProvider ?? vpnEngine?.currentStage;
      if (provider == null) return false;
      final stage = (await provider()).toLowerCase();
      return stage == 'connected' ||
          stage == 'connecting' ||
          stage == 'wait' ||
          stage == 'wait_connection' ||
          stage == 'auth' ||
          stage == 'tcp_connect' ||
          stage == 'udp_connect';
    } catch (_) {
      return false;
    }
  }
}
