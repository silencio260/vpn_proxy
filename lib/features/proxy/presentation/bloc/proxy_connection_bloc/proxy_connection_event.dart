part of 'proxy_connection_bloc.dart';

abstract class ProxyConnectionEvent extends Equatable {
  const ProxyConnectionEvent();

  @override
  List<Object?> get props => [];
}

class ConnectProxyEvent extends ProxyConnectionEvent {
  final ProxyEntity proxy;
  final List<ProxyEntity> candidates;

  const ConnectProxyEvent(this.proxy, {this.candidates = const []});

  @override
  List<Object?> get props => [proxy, candidates];
}

/// Auto-connect request when the user has not selected a location. No proxy is
/// exposed as selected until it passes a live availability test.
class FindAndConnectProxyEvent extends ProxyConnectionEvent {
  final List<ProxyEntity> candidates;

  const FindAndConnectProxyEvent(this.candidates);

  @override
  List<Object?> get props => [candidates];
}

/// User-approved failover after the active proxy has become unhealthy.
class ReconnectToAvailableProxyEvent extends ProxyConnectionEvent {
  final List<ProxyEntity> candidates;

  const ReconnectToAvailableProxyEvent(this.candidates);

  @override
  List<Object?> get props => [candidates];
}

/// Debug-only action that searches the loaded catalog for a genuinely failing
/// server and deliberately starts it so the real failure flow can be observed.
class FindDeadProxyAndConnectEvent extends ProxyConnectionEvent {
  final List<ProxyEntity> candidates;

  const FindDeadProxyAndConnectEvent(this.candidates);

  @override
  List<Object?> get props => [candidates];
}

/// Debug-only immediate watchdog run. Bypassing the debounce makes a simulated
/// failure visible after one tap instead of waiting for two timer intervals.
class RunProxyHealthCheckNowEvent extends ProxyConnectionEvent {
  final bool bypassDebounce;

  const RunProxyHealthCheckNowEvent({this.bypassDebounce = true});

  @override
  List<Object?> get props => [bypassDebounce];
}

class ClearSimulatedProxyFailureEvent extends ProxyConnectionEvent {
  const ClearSimulatedProxyFailureEvent();
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

class ProxyForegroundChangedEvent extends ProxyConnectionEvent {
  final bool isForeground;

  const ProxyForegroundChangedEvent(this.isForeground);

  @override
  List<Object?> get props => [isForeground];
}

class _ValidateConnectedProxyEvent extends ProxyConnectionEvent {
  final int operationId;

  const _ValidateConnectedProxyEvent(this.operationId);

  @override
  List<Object?> get props => [operationId];
}

class _MonitorConnectedProxyEvent extends ProxyConnectionEvent {
  final int operationId;

  const _MonitorConnectedProxyEvent(this.operationId);

  @override
  List<Object?> get props => [operationId];
}
