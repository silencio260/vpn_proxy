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

  const SelectProxyEvent(this.proxy);

  @override
  List<Object?> get props => [proxy];
}
