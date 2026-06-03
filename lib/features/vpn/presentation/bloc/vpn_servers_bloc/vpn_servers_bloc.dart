import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/usecase/base_usecase.dart';
import '../../../../../core/utils/app_constants.dart';
import '../../../data/datasources/local/vpn_local_data_source.dart';
import '../../../domain/entities/vpn_server_entity.dart';
import '../../../domain/entities/vpn_server_health_entity.dart';
import '../../../domain/usecases/get_cached_vpn_servers_usecase.dart';
import '../../../domain/usecases/get_vpn_servers_usecase.dart';
import '../../../domain/usecases/save_selected_vpn_usecase.dart';
import '../../../services/vpn_server_health_service.dart';

part 'vpn_servers_event.dart';
part 'vpn_servers_state.dart';

class VpnServersBloc extends Bloc<VpnServersEvent, VpnServersState> {
  final GetVpnServersUseCase getVpnServers;
  final GetCachedVpnServersUseCase getCachedVpnServers;
  final SaveSelectedVpnUseCase saveSelectedVpn;
  final VpnLocalDataSource localDataSource;
  final VpnServerHealthService healthService;

  int _healthRunId = 0;

  VpnServersBloc({
    required this.getVpnServers,
    required this.getCachedVpnServers,
    required this.saveSelectedVpn,
    required this.localDataSource,
    required this.healthService,
  }) : super(const VpnServersInitial()) {
    on<FetchVpnServersEvent>(_onFetch);
    on<LoadCachedVpnServersEvent>(_onLoadCached);
    on<SelectVpnServerEvent>(_onSelect);
    on<_VpnServerHealthUpdatedEvent>(_onHealthUpdated);
    on<_VpnServerHealthProgressEvent>(_onHealthProgress);
  }

  Future<void> _onFetch(
    FetchVpnServersEvent event,
    Emitter<VpnServersState> emit,
  ) async {
    final previous =
        state is VpnServersLoaded ? state as VpnServersLoaded : null;
    if (previous == null) {
      emit(const VpnServersLoading());
    } else {
      emit(previous.copyWith(isHealthChecking: true));
    }
    final result = await getVpnServers(NoParams.instance);
    await result.fold(
      (failure) async {
        if (previous == null) {
          emit(VpnServersError(_mapFailure(failure)));
        } else {
          emit(previous.copyWith(isHealthChecking: false));
        }
      },
      (servers) async {
        final health = await _freshCachedHealth();
        final selectedServer = _resolveSelectedServer(
          servers: servers,
          previousSelected: previous?.selectedServer,
        );
        emit(
          VpnServersLoaded(
            servers: servers,
            selectedServer: selectedServer,
            healthByServerKey: health,
          ),
        );
        _startHealthRefresh(
          servers: servers,
          cachedHealth: health,
          force: event.forceHealthRefresh,
        );
      },
    );
  }

  Future<void> _onLoadCached(
    LoadCachedVpnServersEvent event,
    Emitter<VpnServersState> emit,
  ) async {
    emit(const VpnServersLoading());
    final result = await getCachedVpnServers(NoParams.instance);
    await result.fold(
      (failure) async => emit(VpnServersError(_mapFailure(failure))),
      (servers) async {
        final health = await _freshCachedHealth();
        emit(
          VpnServersLoaded(
            servers: servers,
            selectedServer:
                servers.isNotEmpty ? servers.first : VpnServerEntity.empty,
            healthByServerKey: health,
          ),
        );
        _startHealthRefresh(
          servers: servers,
          cachedHealth: health,
          force: event.forceHealthRefresh,
        );
      },
    );
  }

  Future<void> _onSelect(
    SelectVpnServerEvent event,
    Emitter<VpnServersState> emit,
  ) async {
    final current = state;
    if (current is VpnServersLoaded) {
      await saveSelectedVpn(event.server);
      emit(current.copyWith(selectedServer: event.server));
    }
  }

  void _onHealthUpdated(
    _VpnServerHealthUpdatedEvent event,
    Emitter<VpnServersState> emit,
  ) {
    if (event.runId != _healthRunId || state is! VpnServersLoaded) return;
    final current = state as VpnServersLoaded;
    final health = Map<String, VpnServerHealthEntity>.of(
      current.healthByServerKey,
    )..[event.health.serverKey] = event.health;
    emit(
      current.copyWith(
        healthByServerKey: health,
        isHealthChecking: event.checkedCount < event.totalCount,
        healthCheckedCount: event.checkedCount,
        healthTotalCount: event.totalCount,
      ),
    );
  }

  void _onHealthProgress(
    _VpnServerHealthProgressEvent event,
    Emitter<VpnServersState> emit,
  ) {
    if (event.runId != _healthRunId || state is! VpnServersLoaded) return;
    final current = state as VpnServersLoaded;
    emit(
      current.copyWith(
        isHealthChecking: event.isChecking,
        healthCheckedCount: event.checkedCount,
        healthTotalCount: event.totalCount,
      ),
    );
  }

  Future<Map<String, VpnServerHealthEntity>> _freshCachedHealth() {
    return localDataSource.getCachedServerHealth(
      now: DateTime.now(),
      ttl: AppConstants.vpnHealthCacheTtl,
    );
  }

  VpnServerEntity _resolveSelectedServer({
    required List<VpnServerEntity> servers,
    VpnServerEntity? previousSelected,
  }) {
    if (servers.isEmpty) return VpnServerEntity.empty;
    if (previousSelected == null || previousSelected.isEmpty) {
      return servers.first;
    }
    return servers.firstWhere(
      (server) =>
          VpnServerHealthService.keyForServer(server) ==
          VpnServerHealthService.keyForServer(previousSelected),
      orElse: () => servers.first,
    );
  }

  void _startHealthRefresh({
    required List<VpnServerEntity> servers,
    required Map<String, VpnServerHealthEntity> cachedHealth,
    required bool force,
  }) {
    _healthRunId++;
    final runId = _healthRunId;
    final candidates =
        force
            ? servers
            : servers
                .where(
                  (server) =>
                      !cachedHealth.containsKey(
                        VpnServerHealthService.keyForServer(server),
                      ),
                )
                .toList();

    if (candidates.isEmpty) {
      add(
        _VpnServerHealthProgressEvent(
          runId: runId,
          checkedCount: 0,
          totalCount: 0,
          isChecking: false,
        ),
      );
      return;
    }

    unawaited(_runHealthRefresh(runId, candidates));
  }

  Future<void> _runHealthRefresh(
    int runId,
    List<VpnServerEntity> servers,
  ) async {
    add(
      _VpnServerHealthProgressEvent(
        runId: runId,
        checkedCount: 0,
        totalCount: servers.length,
        isChecking: true,
      ),
    );

    for (var i = 0; i < servers.length; i++) {
      if (runId != _healthRunId) return;
      final isBusy = await healthService.isVpnBusy;
      if (isBusy) {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (runId != _healthRunId) return;
      }

      final server = servers[i];
      final checking = VpnServerHealthEntity(
        serverKey: VpnServerHealthService.keyForServer(server),
        status: VpnServerHealthStatus.checking,
        checkedAt: DateTime.now(),
      );
      add(
        _VpnServerHealthUpdatedEvent(
          runId: runId,
          checkedCount: i,
          totalCount: servers.length,
          health: checking,
        ),
      );

      final health = await healthService.checkServer(server);
      if (runId != _healthRunId) return;
      await localDataSource.cacheServerHealth(health);
      add(
        _VpnServerHealthUpdatedEvent(
          runId: runId,
          checkedCount: i + 1,
          totalCount: servers.length,
          health: health,
        ),
      );

      await Future<void>.delayed(
        isBusy ? const Duration(seconds: 1) : const Duration(milliseconds: 150),
      );
      if (runId != _healthRunId) return;
    }

    add(
      _VpnServerHealthProgressEvent(
        runId: runId,
        checkedCount: servers.length,
        totalCount: servers.length,
        isChecking: false,
      ),
    );
  }

  String _mapFailure(Failure failure) {
    return switch (failure) {
      NoInternetConnectionFailure() => 'No internet connection',
      ConnectTimeOutFailure() => 'Connection timed out',
      ServerFailure() => 'Server error',
      _ => 'Unexpected error',
    };
  }

  @override
  Future<void> close() {
    _healthRunId++;
    return super.close();
  }
}
