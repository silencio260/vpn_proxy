import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecase/base_usecase.dart';
import '../../../../../core/error/failure.dart';
import '../../../domain/entities/vpn_server_entity.dart';
import '../../../domain/usecases/get_cached_vpn_servers_usecase.dart';
import '../../../domain/usecases/get_vpn_servers_usecase.dart';
import '../../../domain/usecases/save_selected_vpn_usecase.dart';

part 'vpn_servers_event.dart';
part 'vpn_servers_state.dart';

class VpnServersBloc extends Bloc<VpnServersEvent, VpnServersState> {
  final GetVpnServersUseCase getVpnServers;
  final GetCachedVpnServersUseCase getCachedVpnServers;
  final SaveSelectedVpnUseCase saveSelectedVpn;

  VpnServersBloc({
    required this.getVpnServers,
    required this.getCachedVpnServers,
    required this.saveSelectedVpn,
  }) : super(const VpnServersInitial()) {
    on<FetchVpnServersEvent>(_onFetch);
    on<LoadCachedVpnServersEvent>(_onLoadCached);
    on<SelectVpnServerEvent>(_onSelect);
  }

  Future<void> _onFetch(
    FetchVpnServersEvent event,
    Emitter<VpnServersState> emit,
  ) async {
    emit(const VpnServersLoading());
    final result = await getVpnServers(NoParams.instance);
    result.fold(
      (failure) => emit(VpnServersError(_mapFailure(failure))),
      (servers) => emit(VpnServersLoaded(
        servers: servers,
        selectedServer: servers.isNotEmpty ? servers.first : VpnServerEntity.empty,
      )),
    );
  }

  Future<void> _onLoadCached(
    LoadCachedVpnServersEvent event,
    Emitter<VpnServersState> emit,
  ) async {
    emit(const VpnServersLoading());
    final result = await getCachedVpnServers(NoParams.instance);
    result.fold(
      (failure) => emit(VpnServersError(_mapFailure(failure))),
      (servers) => emit(VpnServersLoaded(
        servers: servers,
        selectedServer: servers.isNotEmpty ? servers.first : VpnServerEntity.empty,
      )),
    );
  }

  Future<void> _onSelect(
    SelectVpnServerEvent event,
    Emitter<VpnServersState> emit,
  ) async {
    final current = state;
    if (current is VpnServersLoaded) {
      await saveSelectedVpn(event.server);
      emit(VpnServersLoaded(
        servers: current.servers,
        selectedServer: event.server,
      ));
    }
  }

  String _mapFailure(Failure failure) {
    return switch (failure) {
      NoInternetConnectionFailure() => 'No internet connection',
      ConnectTimeOutFailure() => 'Connection timed out',
      ServerFailure() => 'Server error',
      _ => 'Unexpected error',
    };
  }
}
