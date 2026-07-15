part of 'proxy_bloc.dart';

abstract class ProxyEvent extends Equatable {
  const ProxyEvent();

  @override
  List<Object?> get props => [];
}

class FetchProxiesEvent extends ProxyEvent {
  final bool forceRefresh;

  const FetchProxiesEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class LoadCachedProxiesEvent extends ProxyEvent {
  const LoadCachedProxiesEvent();
}

class SelectProxyEvent extends ProxyEvent {
  final ProxyEntity proxy;
  final bool isManual;

  const SelectProxyEvent(this.proxy, {this.isManual = true});

  @override
  List<Object?> get props => [proxy, isManual];
}

class ClearProxySelectionEvent extends ProxyEvent {
  const ClearProxySelectionEvent();
}
