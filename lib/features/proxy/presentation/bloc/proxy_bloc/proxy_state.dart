part of 'proxy_bloc.dart';

abstract class ProxyState extends Equatable {
  const ProxyState();

  @override
  List<Object?> get props => [];
}

class ProxyInitial extends ProxyState {
  const ProxyInitial();
}

class ProxyLoading extends ProxyState {
  const ProxyLoading();
}

class ProxyLoaded extends ProxyState {
  final List<ProxyEntity> proxies;
  final ProxyEntity selectedProxy;

  const ProxyLoaded({required this.proxies, required this.selectedProxy});

  ProxyLoaded copyWith({
    List<ProxyEntity>? proxies,
    ProxyEntity? selectedProxy,
  }) => ProxyLoaded(
    proxies: proxies ?? this.proxies,
    selectedProxy: selectedProxy ?? this.selectedProxy,
  );

  @override
  List<Object?> get props => [proxies, selectedProxy];
}

class ProxyError extends ProxyState {
  final String message;

  const ProxyError(this.message);

  @override
  List<Object?> get props => [message];
}
