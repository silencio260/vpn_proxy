import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/usecase/base_usecase.dart';
import '../../../domain/entities/proxy_entity.dart';
import '../../../domain/usecases/get_cached_proxies_usecase.dart';
import '../../../domain/usecases/get_proxies_usecase.dart';

part 'proxy_event.dart';
part 'proxy_state.dart';

class ProxyBloc extends Bloc<ProxyEvent, ProxyState> {
  final GetProxiesUseCase getProxies;
  final GetCachedProxiesUseCase getCachedProxies;

  ProxyBloc({required this.getProxies, required this.getCachedProxies})
    : super(const ProxyInitial()) {
    on<FetchProxiesEvent>(_onFetch);
    on<LoadCachedProxiesEvent>(_onLoadCached);
    on<SelectProxyEvent>(_onSelect);
    on<ClearProxySelectionEvent>(_onClearSelection);
  }

  Future<void> _onFetch(
    FetchProxiesEvent event,
    Emitter<ProxyState> emit,
  ) async {
    final previousSelected = state is ProxyLoaded
        ? (state as ProxyLoaded).selectedProxy
        : null;
    final previousSelectionWasManual =
        state is ProxyLoaded && (state as ProxyLoaded).selectionIsManual;
    emit(const ProxyLoading());
    final result = await getProxies(NoParams.instance);
    result.fold((failure) => emit(ProxyError(_mapFailure(failure))), (proxies) {
      final selected = previousSelected == null || previousSelected.isEmpty
          ? ProxyEntity.empty
          : proxies.firstWhere(
              (proxy) => proxy.id == previousSelected.id,
              orElse: () => ProxyEntity.empty,
            );
      emit(
        ProxyLoaded(
          proxies: proxies,
          selectedProxy: selected,
          selectionIsManual: !selected.isEmpty && previousSelectionWasManual,
        ),
      );
    });
  }

  Future<void> _onLoadCached(
    LoadCachedProxiesEvent event,
    Emitter<ProxyState> emit,
  ) async {
    if (state is ProxyLoaded || state is ProxyLoading) return;
    emit(const ProxyLoading());
    final result = await getCachedProxies(NoParams.instance);
    result.fold(
      // Cached read failing or coming back empty is not fatal — revert to
      // the initial state so a subsequent FetchProxiesEvent can still
      // attempt a network fetch.
      (failure) => emit(const ProxyInitial()),
      (proxies) {
        if (proxies.isEmpty) {
          emit(const ProxyInitial());
          return;
        }
        emit(ProxyLoaded(proxies: proxies, selectedProxy: ProxyEntity.empty));
      },
    );
  }

  void _onSelect(SelectProxyEvent event, Emitter<ProxyState> emit) {
    final current = state;
    if (current is ProxyLoaded) {
      emit(
        current.copyWith(
          selectedProxy: event.proxy,
          selectionIsManual: event.isManual,
        ),
      );
    }
  }

  void _onClearSelection(
    ClearProxySelectionEvent event,
    Emitter<ProxyState> emit,
  ) {
    final current = state;
    if (current is ProxyLoaded && !current.selectedProxy.isEmpty) {
      emit(
        current.copyWith(
          selectedProxy: ProxyEntity.empty,
          selectionIsManual: false,
        ),
      );
    }
  }

  String _mapFailure(Failure failure) => switch (failure) {
    NoInternetConnectionFailure() => 'No internet connection',
    ConnectTimeOutFailure() => 'Connection timed out',
    ServerFailure() => 'Server error',
    _ => 'Unexpected error',
  };
}
