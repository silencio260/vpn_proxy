import 'package:equatable/equatable.dart';

class VpnStatusEntity extends Equatable {
  final String? duration;
  final String? lastPacketReceive;
  final String? byteIn;
  final String? byteOut;

  const VpnStatusEntity({
    this.duration,
    this.lastPacketReceive,
    this.byteIn,
    this.byteOut,
  });

  static const empty = VpnStatusEntity();

  @override
  List<Object?> get props => [duration, lastPacketReceive, byteIn, byteOut];
}
