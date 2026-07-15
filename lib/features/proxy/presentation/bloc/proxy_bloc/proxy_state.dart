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
  final bool selectionIsManual;

  const ProxyLoaded({
    required this.proxies,
    required this.selectedProxy,
    this.selectionIsManual = false,
  });

  ProxyLoaded copyWith({
    List<ProxyEntity>? proxies,
    ProxyEntity? selectedProxy,
    bool? selectionIsManual,
  }) => ProxyLoaded(
    proxies: proxies ?? this.proxies,
    selectedProxy: selectedProxy ?? this.selectedProxy,
    selectionIsManual: selectionIsManual ?? this.selectionIsManual,
  );

  @override
  List<Object?> get props => [proxies, selectedProxy, selectionIsManual];
}

class ProxyError extends ProxyState {
  final String message;

  const ProxyError(this.message);

  @override
  List<Object?> get props => [message];
}
