part of 'vpn_connection_bloc.dart';

abstract class VpnConnectionEvent extends Equatable {
  const VpnConnectionEvent();

  @override
  List<Object?> get props => [];
}

class ConnectVpnEvent extends VpnConnectionEvent {
  final VpnServerEntity server;
  const ConnectVpnEvent(this.server);

  @override
  List<Object?> get props => [server];
}

class DisconnectVpnEvent extends VpnConnectionEvent {
  const DisconnectVpnEvent();
}

class VpnStageChangedEvent extends VpnConnectionEvent {
  final String stage;
  const VpnStageChangedEvent(this.stage);

  @override
  List<Object?> get props => [stage];
}

class VpnStatusUpdatedEvent extends VpnConnectionEvent {
  final VpnStatusEntity status;
  const VpnStatusUpdatedEvent(this.status);

  @override
  List<Object?> get props => [status];
}

class LoadIpDetailsEvent extends VpnConnectionEvent {
  const LoadIpDetailsEvent();
}
