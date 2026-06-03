import 'package:equatable/equatable.dart';

enum VpnServerHealthStatus { unknown, checking, online, offline }

class VpnServerHealthEntity extends Equatable {
  final String serverKey;
  final VpnServerHealthStatus status;
  final int? latencyMs;
  final DateTime checkedAt;

  const VpnServerHealthEntity({
    required this.serverKey,
    required this.status,
    required this.checkedAt,
    this.latencyMs,
  });

  VpnServerHealthEntity copyWith({
    String? serverKey,
    VpnServerHealthStatus? status,
    int? latencyMs,
    bool clearLatency = false,
    DateTime? checkedAt,
  }) => VpnServerHealthEntity(
    serverKey: serverKey ?? this.serverKey,
    status: status ?? this.status,
    latencyMs: clearLatency ? null : latencyMs ?? this.latencyMs,
    checkedAt: checkedAt ?? this.checkedAt,
  );

  @override
  List<Object?> get props => [serverKey, status, latencyMs, checkedAt];
}
