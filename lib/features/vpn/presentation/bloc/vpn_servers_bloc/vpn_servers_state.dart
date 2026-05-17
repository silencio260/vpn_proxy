part of 'vpn_servers_bloc.dart';

abstract class VpnServersState extends Equatable {
  const VpnServersState();

  @override
  List<Object?> get props => [];
}

class VpnServersInitial extends VpnServersState {
  const VpnServersInitial();
}

class VpnServersLoading extends VpnServersState {
  const VpnServersLoading();
}

class VpnServersLoaded extends VpnServersState {
  final List<VpnServerEntity> servers;
  final VpnServerEntity selectedServer;

  const VpnServersLoaded({
    required this.servers,
    required this.selectedServer,
  });

  @override
  List<Object?> get props => [servers, selectedServer];
}

class VpnServersError extends VpnServersState {
  final String message;

  const VpnServersError(this.message);

  @override
  List<Object?> get props => [message];
}
