import 'package:equatable/equatable.dart';

import 'proxy_deep_entity.dart';
import 'proxy_health_entity.dart';

class ProxyEntity extends Equatable {
  final String id;
  final String remark;
  final String address;
  final int port;
  final String type;
  final String network;
  final bool tls;
  final String raw;
  final ProxyHealthEntity? health;
  final ProxyDeepEntity? deep;

  const ProxyEntity({
    required this.id,
    required this.remark,
    required this.address,
    required this.port,
    required this.type,
    required this.network,
    required this.tls,
    required this.raw,
    this.health,
    this.deep,
  });

  static const empty = ProxyEntity(
    id: '',
    remark: '',
    address: '',
    port: 0,
    type: 'unknown',
    network: '',
    tls: false,
    raw: '',
  );

  bool get isEmpty => raw.isEmpty;

  @override
  List<Object?> get props => [
    id,
    remark,
    address,
    port,
    type,
    network,
    tls,
    raw,
    health,
    deep,
  ];
}
