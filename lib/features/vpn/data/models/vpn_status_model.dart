import '../../domain/entities/vpn_status_entity.dart';

class VpnStatusModel extends VpnStatusEntity {
  const VpnStatusModel({
    super.duration,
    super.lastPacketReceive,
    super.byteIn,
    super.byteOut,
  });

  factory VpnStatusModel.fromMap(Map<String, String?> map) => VpnStatusModel(
        duration: map['duration'],
        lastPacketReceive: map['lastPacketReceive'],
        byteIn: map['byteIn'],
        byteOut: map['byteOut'],
      );

  Map<String, String?> toMap() => {
        'duration': duration,
        'lastPacketReceive': lastPacketReceive,
        'byteIn': byteIn,
        'byteOut': byteOut,
      };
}
