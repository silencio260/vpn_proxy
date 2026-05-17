import 'package:equatable/equatable.dart';

class VpnServerEntity extends Equatable {
  final String hostname;
  final String ip;
  final String ping;
  final int speed;
  final String countryLong;
  final String countryShort;
  final int numVpnSessions;
  final String openVpnConfigBase64;

  const VpnServerEntity({
    required this.hostname,
    required this.ip,
    required this.ping,
    required this.speed,
    required this.countryLong,
    required this.countryShort,
    required this.numVpnSessions,
    required this.openVpnConfigBase64,
  });

  static const empty = VpnServerEntity(
    hostname: '',
    ip: '',
    ping: '',
    speed: 0,
    countryLong: '',
    countryShort: '',
    numVpnSessions: 0,
    openVpnConfigBase64: '',
  );

  bool get isEmpty => openVpnConfigBase64.isEmpty;

  @override
  List<Object?> get props => [
        hostname,
        ip,
        ping,
        speed,
        countryLong,
        countryShort,
        numVpnSessions,
        openVpnConfigBase64,
      ];
}
