part of 'proxy_connection_bloc.dart';

abstract class ProxyConnectionEvent extends Equatable {
  const ProxyConnectionEvent();

  @override
  List<Object?> get props => [];
}

class ConnectProxyEvent extends ProxyConnectionEvent {
  final ProxyEntity proxy;
  const ConnectProxyEvent(this.proxy);

  @override
  List<Object?> get props => [proxy];
}

class DisconnectProxyEvent extends ProxyConnectionEvent {
  const DisconnectProxyEvent();
}

/// Restart the active session so freshly changed connection settings (mode /
/// split-tunnel exclusions) take effect. No-op when nothing is connected.
class ReconnectWithSettingsEvent extends ProxyConnectionEvent {
  const ReconnectWithSettingsEvent();
}

class ProxyStageChangedEvent extends ProxyConnectionEvent {
  final String stage;
  const ProxyStageChangedEvent(this.stage);

  @override
  List<Object?> get props => [stage];
}

class ProxyStatusUpdatedEvent extends ProxyConnectionEvent {
  final VpnStatusEntity status;
  const ProxyStatusUpdatedEvent(this.status);

  @override
  List<Object?> get props => [status];
}
