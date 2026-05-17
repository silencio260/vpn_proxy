import '../domain/entities/ip_details_entity.dart';
import '../domain/entities/vpn_server_entity.dart';
import '../domain/entities/vpn_status_entity.dart';
import 'models/ip_details_model.dart';
import 'models/vpn_server_model.dart';
import 'models/vpn_status_model.dart';

extension VpnServerModelMapper on VpnServerModel {
  VpnServerEntity toDomain() => VpnServerEntity(
        hostname: hostname,
        ip: ip,
        ping: ping,
        speed: speed,
        countryLong: countryLong,
        countryShort: countryShort,
        numVpnSessions: numVpnSessions,
        openVpnConfigBase64: openVpnConfigBase64,
      );
}

extension VpnServerEntityMapper on VpnServerEntity {
  VpnServerModel toModel() => VpnServerModel(
        hostname: hostname,
        ip: ip,
        ping: ping,
        speed: speed,
        countryLong: countryLong,
        countryShort: countryShort,
        numVpnSessions: numVpnSessions,
        openVpnConfigBase64: openVpnConfigBase64,
      );
}

extension VpnStatusModelMapper on VpnStatusModel {
  VpnStatusEntity toDomain() => VpnStatusEntity(
        duration: duration,
        lastPacketReceive: lastPacketReceive,
        byteIn: byteIn,
        byteOut: byteOut,
      );
}

extension IpDetailsModelMapper on IpDetailsModel {
  IpDetailsEntity toDomain() => IpDetailsEntity(
        country: country,
        regionName: regionName,
        city: city,
        timezone: timezone,
        isp: isp,
        query: query,
      );
}
