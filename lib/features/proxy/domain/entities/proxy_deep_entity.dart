import 'package:equatable/equatable.dart';

class ProxyDeepEntity extends Equatable {
  final bool? tunnelOk;
  final String? egressIp;
  final String? egressCountry;

  /// Geographic region / state of the exit node (e.g. "Hesse", "California").
  final String? egressRegion;

  /// City of the exit node (e.g. "Frankfurt am Main").
  final String? egressCity;
  final int? realLatencyMs;
  final double? downloadMbps;
  final String? downloadTier;
  final double? uploadMbps;
  final String? uploadTier;
  final DateTime? testedAt;
  final String? error;

  const ProxyDeepEntity({
    this.tunnelOk,
    this.egressIp,
    this.egressCountry,
    this.egressRegion,
    this.egressCity,
    this.realLatencyMs,
    this.downloadMbps,
    this.downloadTier,
    this.uploadMbps,
    this.uploadTier,
    this.testedAt,
    this.error,
  });

  @override
  List<Object?> get props => [
    tunnelOk,
    egressIp,
    egressCountry,
    egressRegion,
    egressCity,
    realLatencyMs,
    downloadMbps,
    downloadTier,
    uploadMbps,
    uploadTier,
    testedAt,
    error,
  ];
}
