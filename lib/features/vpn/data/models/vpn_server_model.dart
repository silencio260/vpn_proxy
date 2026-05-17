import '../../domain/entities/vpn_server_entity.dart';

class VpnServerModel extends VpnServerEntity {
  const VpnServerModel({
    required super.hostname,
    required super.ip,
    required super.ping,
    required super.speed,
    required super.countryLong,
    required super.countryShort,
    required super.numVpnSessions,
    required super.openVpnConfigBase64,
  });

  factory VpnServerModel.fromJson(Map<String, dynamic> json) => VpnServerModel(
        hostname: json['HostName']?.toString() ?? '',
        ip: json['IP']?.toString() ?? '',
        ping: json['Ping']?.toString() ?? '0',
        speed: _parseInt(json['Speed']),
        countryLong: json['CountryLong']?.toString() ?? '',
        countryShort: json['CountryShort']?.toString() ?? '',
        numVpnSessions: _parseInt(json['NumVpnSessions']),
        openVpnConfigBase64:
            json['OpenVPN_ConfigData_Base64']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'HostName': hostname,
        'IP': ip,
        'Ping': ping,
        'Speed': speed,
        'CountryLong': countryLong,
        'CountryShort': countryShort,
        'NumVpnSessions': numVpnSessions,
        'OpenVPN_ConfigData_Base64': openVpnConfigBase64,
      };

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}
