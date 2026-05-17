import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';

import '../data/models/vpn_status_model.dart';
import '../domain/entities/vpn_config_entity.dart';

class VpnEngineService {
  late final OpenVPN _engine;

  final _stageController = StreamController<String>.broadcast();
  final _statusController = StreamController<VpnStatusModel>.broadcast();

  Stream<String> get vpnStageStream => _stageController.stream;
  Stream<VpnStatusModel> get vpnStatusStream => _statusController.stream;

  VpnEngineService() {
    _engine = OpenVPN(
      onVpnStageChanged: (stage, rawStage) {
        _stageController.add(rawStage);
      },
      onVpnStatusChanged: (status) {
        if (status == null) return;
        _statusController.add(
          VpnStatusModel(
            duration: status.duration,
            byteIn: status.byteIn,
            byteOut: status.byteOut,
            lastPacketReceive: status.packetsIn,
          ),
        );
      },
    );
    _engine.initialize();
  }

  Future<void> startVpn(VpnConfigEntity config) async {
    final granted = await _engine.requestPermissionAndroid();
    if (!granted) throw Exception('VPN permission denied');

    String ovpnConfig = utf8.decode(base64Decode(config.config));
    ovpnConfig = _patchOvpnConfig(ovpnConfig);
    final hasInlineClientCert =
        _hasInlineBlock(ovpnConfig, 'cert') &&
        _hasInlineBlock(ovpnConfig, 'key');
    // openvpn_flutter appends "client-cert-not-required" when certIsRequired is
    // false, so pass true for VPNGate profiles that already include cert/key.
    if (!ovpnConfig.endsWith('\n')) ovpnConfig += '\n';
    debugPrint('[VPN] patched config:\n$ovpnConfig');
    await _engine.connect(
      ovpnConfig,
      config.country,
      username: config.username.isEmpty ? null : config.username,
      password: config.password.isEmpty ? null : config.password,
      certIsRequired: hasInlineClientCert,
    );
  }

  // VPNGate configs often contain directives deprecated/removed in OpenVPN 2.5+
  // that cause the process to exit immediately. This patches them to be compatible.
  String _patchOvpnConfig(String config) {
    // Normalize line endings — Windows-style \r\n breaks directive matching
    final normalized = config.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    final patched = <String>[];
    bool hasCipher = false;
    bool hasDataCiphers = false;
    bool hasAuthUserPass = false;

    for (final line in lines) {
      final trimmed = line.trim().toLowerCase();
      final uncommented = trimmed.replaceFirst(RegExp(r'^[#;]\s*'), '');

      // VPNGate profiles often comment this out even though they require the
      // standard vpn/vpn credentials supplied by the app.
      if (uncommented == 'auth-user-pass' ||
          uncommented.startsWith('auth-user-pass ')) {
        hasAuthUserPass = true;
        patched.add('auth-user-pass');
        continue;
      }

      if (uncommented == 'client-cert-not-required') {
        continue;
      }

      // Replace deprecated BF-CBC cipher
      if (trimmed.startsWith('cipher ')) {
        hasCipher = true;
        if (trimmed.contains('bf-cbc')) {
          patched.add('cipher AES-128-CBC');
          continue;
        }
      }

      // Rename legacy ncp-ciphers to data-ciphers (renamed in OpenVPN 2.5)
      if (trimmed.startsWith('ncp-ciphers ')) {
        hasDataCiphers = true;
        patched.add(
          'data-ciphers ${line.trim().substring('ncp-ciphers '.length)}',
        );
        continue;
      }

      if (trimmed.startsWith('data-ciphers ')) {
        hasDataCiphers = true;
      }

      // Replace deprecated comp-lzo with modern equivalent
      if (trimmed == 'comp-lzo' || trimmed.startsWith('comp-lzo ')) {
        patched.add('compress');
        continue;
      }

      // keysize was removed in OpenVPN 2.5 (key length is negotiated via cipher)
      if (trimmed.startsWith('keysize ')) {
        continue;
      }

      // tls-remote was removed in OpenVPN 2.5; drop it to allow connection
      if (trimmed.startsWith('tls-remote ')) {
        continue;
      }

      // ns-cert-type was removed in OpenVPN 2.5; replace with remote-cert-tls
      if (trimmed.startsWith('ns-cert-type ')) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length > 1) {
          patched.add('remote-cert-tls ${parts[1]}');
        }
        continue;
      }

      patched.add(line);
    }

    // Ensure cipher negotiation works with both old and new servers
    if (!hasDataCiphers) {
      patched.add(
        'data-ciphers AES-256-GCM:AES-128-GCM:AES-256-CBC:AES-128-CBC',
      );
    }
    if (!hasCipher) {
      patched.add('cipher AES-128-CBC');
    }
    if (!hasAuthUserPass) {
      patched.add('auth-user-pass');
    }

    return '${patched.join('\n')}\n';
  }

  bool _hasInlineBlock(String config, String blockName) {
    final pattern = RegExp(
      '<$blockName>.*?</$blockName>',
      caseSensitive: false,
      dotAll: true,
    );
    return pattern.hasMatch(config);
  }

  Future<void> stopVpn() async {
    _engine.disconnect();
  }

  Future<String> currentStage() async {
    final stage = await _engine.stage();
    return stage.toString().split('.').last;
  }

  void dispose() {
    _stageController.close();
    _statusController.close();
  }
}
