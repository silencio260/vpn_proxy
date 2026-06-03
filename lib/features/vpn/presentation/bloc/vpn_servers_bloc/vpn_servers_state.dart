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
  final Map<String, VpnServerHealthEntity> healthByServerKey;
  final bool isHealthChecking;
  final int healthCheckedCount;
  final int healthTotalCount;

  const VpnServersLoaded({
    required this.servers,
    required this.selectedServer,
    this.healthByServerKey = const {},
    this.isHealthChecking = false,
    this.healthCheckedCount = 0,
    this.healthTotalCount = 0,
  });

  VpnServersLoaded copyWith({
    List<VpnServerEntity>? servers,
    VpnServerEntity? selectedServer,
    Map<String, VpnServerHealthEntity>? healthByServerKey,
    bool? isHealthChecking,
    int? healthCheckedCount,
    int? healthTotalCount,
  }) => VpnServersLoaded(
    servers: servers ?? this.servers,
    selectedServer: selectedServer ?? this.selectedServer,
    healthByServerKey: healthByServerKey ?? this.healthByServerKey,
    isHealthChecking: isHealthChecking ?? this.isHealthChecking,
    healthCheckedCount: healthCheckedCount ?? this.healthCheckedCount,
    healthTotalCount: healthTotalCount ?? this.healthTotalCount,
  );

  @override
  List<Object?> get props => [
    servers,
    selectedServer,
    healthByServerKey,
    isHealthChecking,
    healthCheckedCount,
    healthTotalCount,
  ];
}

class VpnServersError extends VpnServersState {
  final String message;

  const VpnServersError(this.message);

  @override
  List<Object?> get props => [message];
}
