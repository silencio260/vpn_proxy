import '../../domain/entities/proxy_deep_entity.dart';

class ProxyDeepModel extends ProxyDeepEntity {
  const ProxyDeepModel({
    super.tunnelOk,
    super.egressIp,
    super.egressCountry,
    super.egressRegion,
    super.egressCity,
    super.realLatencyMs,
    super.downloadMbps,
    super.downloadTier,
    super.uploadMbps,
    super.uploadTier,
    super.testedAt,
    super.error,
  });

  factory ProxyDeepModel.fromJson(Map<String, dynamic> json) => ProxyDeepModel(
    tunnelOk: json['tunnelOk'] as bool?,
    egressIp: json['egressIp']?.toString(),
    egressCountry: json['egressCountry']?.toString(),
    egressRegion: json['egressRegion']?.toString(),
    egressCity: json['egressCity']?.toString(),
    realLatencyMs: _parseNullableInt(json['realLatencyMs']),
    downloadMbps: _parseNullableDouble(json['downloadMbps']),
    downloadTier: json['downloadTier']?.toString(),
    uploadMbps: _parseNullableDouble(json['uploadMbps']),
    uploadTier: json['uploadTier']?.toString(),
    testedAt: _parseNullableDate(json['testedAt']),
    error: json['error']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'tunnelOk': tunnelOk,
    'egressIp': egressIp,
    'egressCountry': egressCountry,
    'egressRegion': egressRegion,
    'egressCity': egressCity,
    'realLatencyMs': realLatencyMs,
    'downloadMbps': downloadMbps,
    'downloadTier': downloadTier,
    'uploadMbps': uploadMbps,
    'uploadTier': uploadTier,
    'testedAt': testedAt?.toIso8601String(),
    'error': error,
  };

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _parseNullableDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
