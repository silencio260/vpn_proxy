import '../../domain/entities/proxy_health_entity.dart';

class ProxyHealthModel extends ProxyHealthEntity {
  const ProxyHealthModel({
    required super.status,
    super.latencyMs,
    super.signal,
    super.speed,
    super.checkedAt,
    super.error,
  });

  factory ProxyHealthModel.fromJson(Map<String, dynamic> json) =>
      ProxyHealthModel(
        status: json['status']?.toString() ?? 'unknown',
        latencyMs: _parseNullableInt(json['latencyMs']),
        signal: json['signal']?.toString(),
        speed: json['speed']?.toString(),
        checkedAt: _parseNullableDate(json['checkedAt']),
        error: json['error']?.toString(),
      );

  Map<String, dynamic> toJson() => {
    'status': status,
    'latencyMs': latencyMs,
    'signal': signal,
    'speed': speed,
    'checkedAt': checkedAt?.toIso8601String(),
    'error': error,
  };

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _parseNullableDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
