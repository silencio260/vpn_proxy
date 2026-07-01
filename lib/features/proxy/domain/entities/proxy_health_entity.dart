import 'package:equatable/equatable.dart';

class ProxyHealthEntity extends Equatable {
  final String status;
  final int? latencyMs;
  final String? signal;
  final String? speed;
  final DateTime? checkedAt;
  final String? error;

  const ProxyHealthEntity({
    required this.status,
    this.latencyMs,
    this.signal,
    this.speed,
    this.checkedAt,
    this.error,
  });

  @override
  List<Object?> get props => [
    status,
    latencyMs,
    signal,
    speed,
    checkedAt,
    error,
  ];
}
