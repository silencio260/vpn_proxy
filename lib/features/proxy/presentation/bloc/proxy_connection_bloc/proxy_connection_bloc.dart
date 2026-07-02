import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../vpn/domain/entities/vpn_status_entity.dart';
import '../../../../vpn/presentation/bloc/vpn_connection_bloc/vpn_connection_bloc.dart';
import '../../../domain/entities/proxy_entity.dart';
import '../../../services/proxy_engine_service.dart';

part 'proxy_connection_event.dart';

/// Drives the Xray proxy connection. Deliberately reuses [VpnConnectionState]
/// and [VpnStage] (imported from the vpn feature) as its emitted state so the
/// shared home-screen widgets — the connect button, speed pills, status label —
/// work against either engine without change. The stage state-machine here is a
/// clone of [VpnConnectionBloc]'s (it only reacts to protocol-agnostic stage
/// strings), minus the OpenVPN-specific config building and IP-details lookup.
class ProxyConnectionBloc extends Bloc<ProxyConnectionEvent, VpnConnectionState> {
  final ProxyEngineService engine;

  StreamSubscription<String>? _stageSub;
  StreamSubscription<dynamic>? _statusSub;
  Timer? _connectTimeout;
  DateTime? _suppressExitUntil;

  static const _connectTimeoutDuration = Duration(seconds: 25);
  static const _restartSuppressWindow = Duration(seconds: 3);

  ProxyConnectionBloc({required this.engine})
      : super(const VpnConnectionState()) {
    on<ConnectProxyEvent>(_onConnect);
    on<DisconnectProxyEvent>(_onDisconnect);
    on<ProxyStageChangedEvent>(_onStageChanged);
    on<ProxyStatusUpdatedEvent>(_onStatusUpdated);

    _stageSub = engine.stageStream.listen(
      (stage) => add(ProxyStageChangedEvent(stage)),
    );
    _statusSub = engine.statusStream.listen(
      (status) => add(ProxyStatusUpdatedEvent(status)),
    );
  }

  Future<void> _onConnect(
    ConnectProxyEvent event,
    Emitter<VpnConnectionState> emit,
  ) async {
    // If already connecting/connected (e.g. user switching proxies), stop the
    // current session first so the engine can cleanly start the new one.
    if (state.stage == VpnStage.connecting ||
        state.stage == VpnStage.connected) {
      // The pending stop emits disconnected/error stage events; suppress them
      // so they don't get mapped to a failure for the upcoming attempt.
      _suppressExitUntil = DateTime.now().add(_restartSuppressWindow);
      try {
        await engine.stopProxy();
      } catch (_) {}
    }
    emit(state.copyWith(stage: VpnStage.connecting));
    _armConnectTimeout();
    try {
      await engine.startProxy(event.proxy);
    } catch (e) {
      _connectTimeout?.cancel();
      emit(state.copyWith(
        stage: VpnStage.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _armConnectTimeout() {
    _connectTimeout?.cancel();
    _connectTimeout = Timer(_connectTimeoutDuration, () {
      if (state.stage == VpnStage.connecting) {
        add(const ProxyStageChangedEvent('__timeout__'));
      }
    });
  }

  Future<void> _onDisconnect(
    DisconnectProxyEvent event,
    Emitter<VpnConnectionState> emit,
  ) async {
    emit(state.copyWith(stage: VpnStage.disconnecting));
    try {
      await engine.stopProxy();
    } catch (e) {
      emit(state.copyWith(
        stage: VpnStage.disconnected,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onStageChanged(
    ProxyStageChangedEvent event,
    Emitter<VpnConnectionState> emit,
  ) {
    final raw = event.stage.toLowerCase();
    final suppressing = _suppressExitUntil != null &&
        DateTime.now().isBefore(_suppressExitUntil!);
    if (suppressing &&
        (raw == 'disconnected' || raw == 'idle' || raw == 'no_connection')) {
      return;
    }
    // While actively connecting, stale "disconnected"/"idle" events from the
    // engine's startup are noise — a real teardown reaches us via
    // DisconnectProxyEvent (which sets disconnecting first).
    if (state.stage == VpnStage.connecting &&
        (raw == 'disconnected' || raw == 'no_connection' || raw == 'idle')) {
      return;
    }
    final stage = switch (raw) {
      'connected' => VpnStage.connected,
      'disconnected' || 'idle' || 'no_connection' => VpnStage.disconnected,
      'disconnecting' => VpnStage.disconnecting,
      'denied' || 'error' || 'invalid' => VpnStage.error,
      'connecting' || 'prepare' || 'wait' || 'auth' || 'reconnect' =>
        VpnStage.connecting,
      '__timeout__' => VpnStage.error,
      _ => state.stage,
    };
    if (stage == state.stage) return;
    final errorMessage = stage == VpnStage.error
        ? (raw == '__timeout__' ? 'Connection timed out' : 'Connection failed')
        : null;
    if (stage == VpnStage.connected ||
        stage == VpnStage.error ||
        stage == VpnStage.disconnected) {
      _connectTimeout?.cancel();
    }
    emit(state.copyWith(stage: stage, errorMessage: errorMessage));
  }

  void _onStatusUpdated(
    ProxyStatusUpdatedEvent event,
    Emitter<VpnConnectionState> emit,
  ) {
    emit(state.copyWith(status: event.status));
  }

  @override
  Future<void> close() {
    _connectTimeout?.cancel();
    _stageSub?.cancel();
    _statusSub?.cancel();
    return super.close();
  }
}
