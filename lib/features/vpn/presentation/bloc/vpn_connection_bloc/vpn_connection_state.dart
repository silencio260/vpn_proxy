part of 'vpn_connection_bloc.dart';

enum VpnStage { disconnected, connecting, connected, disconnecting, error }

class VpnConnectionState extends Equatable {
  final VpnStage stage;
  final VpnStatusEntity status;
  final IpDetailsEntity ipDetails;
  final String? errorMessage;

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
  });

  bool get isConnected => stage == VpnStage.connected;
  bool get isConnecting => stage == VpnStage.connecting || stage == VpnStage.disconnecting;

  VpnConnectionState copyWith({
    VpnStage? stage,
    VpnStatusEntity? status,
    IpDetailsEntity? ipDetails,
    String? errorMessage,
  }) =>
      VpnConnectionState(
        stage: stage ?? this.stage,
        status: status ?? this.status,
        ipDetails: ipDetails ?? this.ipDetails,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [stage, status, ipDetails, errorMessage];
}
