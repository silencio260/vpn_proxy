import '../domain/entities/proxy_deep_entity.dart';
import '../domain/entities/proxy_entity.dart';
import '../domain/entities/proxy_health_entity.dart';
import 'models/proxy_deep_model.dart';
import 'models/proxy_health_model.dart';
import 'models/proxy_model.dart';

extension ProxyHealthModelMapper on ProxyHealthModel {
  ProxyHealthEntity toDomain() => ProxyHealthEntity(
    status: status,
    latencyMs: latencyMs,
    signal: signal,
    speed: speed,
    checkedAt: checkedAt,
    error: error,
  );
}

extension ProxyDeepModelMapper on ProxyDeepModel {
  ProxyDeepEntity toDomain() => ProxyDeepEntity(
    tunnelOk: tunnelOk,
    egressIp: egressIp,
    egressCountry: egressCountry,
    egressRegion: egressRegion,
    egressCity: egressCity,
    realLatencyMs: realLatencyMs,
    downloadMbps: downloadMbps,
    downloadTier: downloadTier,
    uploadMbps: uploadMbps,
    uploadTier: uploadTier,
    testedAt: testedAt,
    error: error,
  );
}

extension ProxyModelMapper on ProxyModel {
  ProxyEntity toDomain() => ProxyEntity(
    id: id,
    remark: remark,
    address: address,
    port: port,
    type: type,
    network: network,
    tls: tls,
    raw: raw,
    health: health,
    deep: deep,
  );
}
