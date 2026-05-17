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
    emit(state.copyWith(stage: VpnStage.connecting));
    try {
      final config = VpnConfigEntity(
        country: event.server.countryLong,
        username: 'vpn',
        password: 'vpn',
        config: event.server.openVpnConfigBase64,
      );
      await vpnEngine.startVpn(config);
    } catch (e) {
      emit(state.copyWith(
        stage: VpnStage.error,
        errorMessage: e.toString(),
      ));
    }
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
    final stage = switch (event.stage.toLowerCase()) {
      'connected' => VpnStage.connected,
      'connecting' || 'wait_connection' || 'authenticating' => VpnStage.connecting,
      'disconnecting' => VpnStage.disconnecting,
      _ => VpnStage.disconnected,
    };
    emit(state.copyWith(stage: stage));
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
    _stageSub?.cancel();
    _statusSub?.cancel();
    return super.close();
  }
}
