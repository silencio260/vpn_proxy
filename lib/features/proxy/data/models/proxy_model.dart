import '../../domain/entities/proxy_deep_entity.dart';
import '../../domain/entities/proxy_entity.dart';
import '../../domain/entities/proxy_health_entity.dart';
import 'proxy_deep_model.dart';
import 'proxy_health_model.dart';

class ProxyModel extends ProxyEntity {
  const ProxyModel({
    required super.id,
    required super.remark,
    required super.address,
    required super.port,
    required super.type,
    required super.network,
    required super.tls,
    required super.raw,
    super.health,
    super.deep,
  });

  /// Parses a single flattened proxy entry from the `proxies[]` array.
  /// `health`/`deep` are left null here — they live in separate top-level
  /// maps in the Firestore doc and are merged in by the repository.
  factory ProxyModel.fromJson(Map<String, dynamic> json) => ProxyModel(
    id: json['id']?.toString() ?? '',
    remark: json['remark']?.toString() ?? '',
    address: json['address']?.toString() ?? '',
    port: _parseInt(json['port']),
    type: json['type']?.toString() ?? 'unknown',
    network: json['network']?.toString() ?? '',
    tls: _parseBool(json['tls']),
    raw: json['raw']?.toString() ?? '',
    health:
        json['health'] == null
            ? null
            : ProxyHealthModel.fromJson(json['health'] as Map<String, dynamic>),
    deep:
        json['deep'] == null
            ? null
            : ProxyDeepModel.fromJson(json['deep'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'remark': remark,
    'address': address,
    'port': port,
    'type': type,
    'network': network,
    'tls': tls,
    'raw': raw,
    'health':
        health == null ? null : (health as ProxyHealthModel).toJson(),
    'deep': deep == null ? null : (deep as ProxyDeepModel).toJson(),
  };

  ProxyModel copyWith({ProxyHealthEntity? health, ProxyDeepEntity? deep}) =>
      ProxyModel(
        id: id,
        remark: remark,
        address: address,
        port: port,
        type: type,
        network: network,
        tls: tls,
        raw: raw,
        health: health ?? this.health,
        deep: deep ?? this.deep,
      );

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }
}
