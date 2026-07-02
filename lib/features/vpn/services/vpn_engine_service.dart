import 'dart:async';

import '../data/models/vpn_status_model.dart';
import '../domain/entities/vpn_config_entity.dart';

/// Dormant OpenVPN engine.
///
/// The app dials proxies through the Xray engine
/// (`features/proxy/services/proxy_engine_service.dart`). The `openvpn_flutter`
/// plugin was removed because it and `flutter_v2ray` both ship a gomobile
/// `libgojni.so`, and two such native libraries cannot coexist in one APK.
///
/// This stub preserves the original public surface (stage/status streams,
/// start/stop, currentStage) so the remaining pure-Dart consumers
/// (`VpnConnectionBloc`, `VpnServerHealthService`, the speed-test/splash
/// screens) keep compiling. Nothing in the live UI calls [startVpn]; if it ever
/// does, it surfaces a clear error rather than silently doing nothing.
class VpnEngineService {
  final _stageController = StreamController<String>.broadcast();
  final _statusController = StreamController<VpnStatusModel>.broadcast();

  Stream<String> get vpnStageStream => _stageController.stream;
  Stream<VpnStatusModel> get vpnStatusStream => _statusController.stream;

  Future<void> startVpn(VpnConfigEntity config) async {
    _stageController.add('error');
    throw UnsupportedError(
      'The OpenVPN engine is disabled. Connect through the proxy engine '
      '(ProxyConnectionBloc) instead.',
    );
  }

  Future<void> stopVpn() async {
    _stageController.add('disconnected');
  }

  Future<String> currentStage() async => 'disconnected';

  void dispose() {
    _stageController.close();
    _statusController.close();
  }
}
