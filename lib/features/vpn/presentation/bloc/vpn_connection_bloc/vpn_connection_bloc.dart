import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecase/base_usecase.dart';
import '../../../domain/entities/ip_details_entity.dart';
import '../../../domain/entities/vpn_config_entity.dart';
import '../../../domain/entities/vpn_server_entity.dart';
import '../../../domain/entities/vpn_status_entity.dart';
import '../../../domain/usecases/get_ip_details_usecase.dart';
import '../../../services/vpn_engine_service.dart';

part 'vpn_connection_event.dart';
part 'vpn_connection_state.dart';

class VpnConnectionBloc
    extends Bloc<VpnConnectionEvent, VpnConnectionState> {
  final VpnEngineService vpnEngine;
  final GetIpDetailsUseCase getIpDetails;

  StreamSubscription<String>? _stageSub;
  StreamSubscription<dynamic>? _statusSub;
  Timer? _connectTimeout;
  DateTime? _suppressExitUntil;

  static const _connectTimeoutDuration = Duration(seconds: 25);
  static const _restartSuppressWindow = Duration(seconds: 3);

  VpnConnectionBloc({
    required this.vpnEngine,
    required this.getIpDetails,
  }) : super(const VpnConnectionState()) {
    on<ConnectVpnEvent>(_onConnect);
    on<DisconnectVpnEvent>(_onDisconnect);
    on<VpnStageChangedEvent>(_onStageChanged);
    on<VpnStatusUpdatedEvent>(_onStatusUpdated);
    on<LoadIpDetailsEvent>(_onLoadIpDetails);

    _stageSub = vpnEngine.vpnStageStream.listen(
      (stage) => add(VpnStageChangedEvent(stage)),
    );
    _statusSub = vpnEngine.vpnStatusStream.listen(
      (status) => add(VpnStatusUpdatedEvent(status)),
    );
  }

  Future<void> _onConnect(
    ConnectVpnEvent event,
    Emitter<VpnConnectionState> emit,
  ) async {
    // If already connecting/connected (e.g. user switching servers), stop the
    // current session first so the engine can cleanly start the new one.
    if (state.stage == VpnStage.connecting ||
        state.stage == VpnStage.connected) {
      // The pending stop will emit exiting/noprocess stage events; suppress
      // them so they don't get mapped to error for the upcoming attempt.
      _suppressExitUntil = DateTime.now().add(_restartSuppressWindow);
      try {
        await vpnEngine.stopVpn();
      } catch (_) {}
    }
    emit(state.copyWith(stage: VpnStage.connecting));
    _armConnectTimeout();
    try {
      final config = VpnConfigEntity(
        country: event.server.countryLong,
        username: 'vpn',
        password: 'vpn',
        config: event.server.openVpnConfigBase64,
      );
      await vpnEngine.startVpn(config);
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
        add(const VpnStageChangedEvent('__timeout__'));
      }
    });
  }

  Future<void> _onDisconnect(
    DisconnectVpnEvent event,
    Emitter<VpnConnectionState> emit,
  ) async {
    emit(state.copyWith(stage: VpnStage.disconnecting));
    try {
      await vpnEngine.stopVpn();
    } catch (e) {
      emit(state.copyWith(
        stage: VpnStage.disconnected,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onStageChanged(
    VpnStageChangedEvent event,
    Emitter<VpnConnectionState> emit,
  ) {
    final raw = event.stage.toLowerCase();
    final suppressing = _suppressExitUntil != null &&
        DateTime.now().isBefore(_suppressExitUntil!);
    if (suppressing &&
        (raw == 'exiting' ||
            raw == 'noprocess' ||
            raw == 'disconnected' ||
            raw == 'no_connection' ||
            raw == 'idle')) {
      return;
    }
    // While actively connecting, stale "idle"/"disconnected"/"no_connection"
    // events from the engine's startup are noise — a real teardown reaches us
    // via DisconnectVpnEvent (which sets disconnecting first) or exiting/noprocess.
    if (state.stage == VpnStage.connecting &&
        (raw == 'disconnected' ||
            raw == 'no_connection' ||
            raw == 'idle')) {
      return;
    }
    final stage = switch (raw) {
      'connected' => VpnStage.connected,
      'disconnected' || 'idle' || 'no_connection' => VpnStage.disconnected,
      'disconnecting' => VpnStage.disconnecting,
      'denied' || 'error' || 'invalid' => VpnStage.error,
      'connecting' ||
      'prepare' ||
      'vpn_generate_config' ||
      'resolve' ||
      'tcp_connect' ||
      'udp_connect' ||
      'wait' ||
      'wait_connection' ||
      'auth' ||
      'authenticating' ||
      'get_config' ||
      'assign_ip' ||
      'add_routes' ||
      'reconnect' =>
        VpnStage.connecting,
      // Engine exited without ever reaching connected → surface a failure so
      // the UI doesn't get stuck spinning forever (e.g. unreachable server).
      'exiting' || 'noprocess' =>
        state.stage == VpnStage.connecting
            ? VpnStage.error
            : VpnStage.disconnected,
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
    if (stage == VpnStage.connected) add(const LoadIpDetailsEvent());
  }

  void _onStatusUpdated(
    VpnStatusUpdatedEvent event,
    Emitter<VpnConnectionState> emit,
  ) {
    emit(state.copyWith(status: event.status));
  }

  Future<void> _onLoadIpDetails(
    LoadIpDetailsEvent event,
    Emitter<VpnConnectionState> emit,
  ) async {
    final result = await getIpDetails(NoParams.instance);
    result.fold(
      (_) {},
      (details) => emit(state.copyWith(ipDetails: details)),
    );
  }

  @override
  Future<void> close() {
    _connectTimeout?.cancel();
    _stageSub?.cancel();
    _statusSub?.cancel();
    return super.close();
  }
}
