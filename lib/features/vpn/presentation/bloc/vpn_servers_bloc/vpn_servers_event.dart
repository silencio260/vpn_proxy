part of 'vpn_servers_bloc.dart';

abstract class VpnServersEvent extends Equatable {
  const VpnServersEvent();

  @override
  List<Object?> get props => [];
}

class FetchVpnServersEvent extends VpnServersEvent {
  final bool forceHealthRefresh;

  const FetchVpnServersEvent({this.forceHealthRefresh = false});

  @override
  List<Object?> get props => [forceHealthRefresh];
}

class LoadCachedVpnServersEvent extends VpnServersEvent {
  final bool forceHealthRefresh;

  const LoadCachedVpnServersEvent({this.forceHealthRefresh = false});

  @override
  List<Object?> get props => [forceHealthRefresh];
}

class SelectVpnServerEvent extends VpnServersEvent {
  final VpnServerEntity server;
  const SelectVpnServerEvent(this.server);

  @override
  List<Object?> get props => [server];
}

class _VpnServerHealthUpdatedEvent extends VpnServersEvent {
  final int runId;
  final int checkedCount;
  final int totalCount;
  final VpnServerHealthEntity health;

  const _VpnServerHealthUpdatedEvent({
    required this.runId,
    required this.checkedCount,
    required this.totalCount,
    required this.health,
  });

  @override
  List<Object?> get props => [runId, checkedCount, totalCount, health];
}

class _VpnServerHealthProgressEvent extends VpnServersEvent {
  final int runId;
  final int checkedCount;
  final int totalCount;
  final bool isChecking;

  const _VpnServerHealthProgressEvent({
    required this.runId,
    required this.checkedCount,
    required this.totalCount,
    required this.isChecking,
  });

  @override
  List<Object?> get props => [runId, checkedCount, totalCount, isChecking];
}
