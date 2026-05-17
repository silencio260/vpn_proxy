part of 'vpn_servers_bloc.dart';

abstract class VpnServersEvent extends Equatable {
  const VpnServersEvent();

  @override
  List<Object?> get props => [];
}

class FetchVpnServersEvent extends VpnServersEvent {
  const FetchVpnServersEvent();
}

class LoadCachedVpnServersEvent extends VpnServersEvent {
  const LoadCachedVpnServersEvent();
}

class SelectVpnServerEvent extends VpnServersEvent {
  final VpnServerEntity server;
  const SelectVpnServerEvent(this.server);

  @override
  List<Object?> get props => [server];
}
