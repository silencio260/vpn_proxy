import '../../domain/entities/vpn_server_health_entity.dart';

class VpnServerHealthModel extends VpnServerHealthEntity {
  const VpnServerHealthModel({
    required super.serverKey,
    required super.status,
    required super.checkedAt,
    super.latencyMs,
  });

  factory VpnServerHealthModel.fromJson(Map<String, dynamic> json) {
    final statusName = json['status']?.toString() ?? '';
    return VpnServerHealthModel(
      serverKey: json['serverKey']?.toString() ?? '',
      status: VpnServerHealthStatus.values.firstWhere(
        (s) => s.name == statusName,
        orElse: () => VpnServerHealthStatus.unknown,
      ),
      latencyMs:
          json['latencyMs'] is int
              ? json['latencyMs'] as int
              : int.tryParse(json['latencyMs']?.toString() ?? ''),
      checkedAt:
          DateTime.tryParse(json['checkedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory VpnServerHealthModel.fromDomain(VpnServerHealthEntity entity) =>
      VpnServerHealthModel(
        serverKey: entity.serverKey,
        status: entity.status,
        latencyMs: entity.latencyMs,
        checkedAt: entity.checkedAt,
      );

  Map<String, dynamic> toJson() => {
    'serverKey': serverKey,
    'status': status.name,
    'latencyMs': latencyMs,
    'checkedAt': checkedAt.toIso8601String(),
  };
}
