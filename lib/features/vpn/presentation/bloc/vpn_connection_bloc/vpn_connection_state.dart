part of 'vpn_connection_bloc.dart';

enum VpnStage {
  disconnected,
  finding,
  connecting,
  validating,
  connected,
  unhealthy,
  disconnecting,
  error,
}

enum ConnectionFailureKind {
  none,
  noInternet,
  proxyUnavailable,
  permissionDenied,
  invalidConfig,
  unknown,
}

const _unsetConnectionValue = Object();

class VpnConnectionState extends Equatable {
  final VpnStage stage;
  final VpnStatusEntity status;
  final IpDetailsEntity ipDetails;
  final String? errorMessage;
  final ConnectionFailureKind failureKind;
  final String? activeProxyId;

  const VpnConnectionState({
    this.stage = VpnStage.disconnected,
    this.status = const VpnStatusEntity(),
    this.ipDetails = const IpDetailsEntity(
      country: '',
      regionName: '',
      city: '',
      timezone: '',
      isp: '',
      query: '',
    ),
    this.errorMessage,
    this.failureKind = ConnectionFailureKind.none,
    this.activeProxyId,
  });

  bool get isConnected => stage == VpnStage.connected;
  bool get isConnecting =>
      stage == VpnStage.finding ||
      stage == VpnStage.connecting ||
      stage == VpnStage.validating ||
      stage == VpnStage.disconnecting;

  VpnConnectionState copyWith({
    VpnStage? stage,
    VpnStatusEntity? status,
    IpDetailsEntity? ipDetails,
    Object? errorMessage = _unsetConnectionValue,
    ConnectionFailureKind? failureKind,
    Object? activeProxyId = _unsetConnectionValue,
  }) => VpnConnectionState(
    stage: stage ?? this.stage,
    status: status ?? this.status,
    ipDetails: ipDetails ?? this.ipDetails,
    errorMessage:
        identical(errorMessage, _unsetConnectionValue)
            ? this.errorMessage
            : errorMessage as String?,
    failureKind: failureKind ?? this.failureKind,
    activeProxyId:
        identical(activeProxyId, _unsetConnectionValue)
            ? this.activeProxyId
            : activeProxyId as String?,
  );

  @override
  List<Object?> get props => [
    stage,
    status,
    ipDetails,
    errorMessage,
    failureKind,
    activeProxyId,
  ];
}
