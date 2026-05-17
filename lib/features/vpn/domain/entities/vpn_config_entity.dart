import 'package:equatable/equatable.dart';

class VpnConfigEntity extends Equatable {
  final String country;
  final String username;
  final String password;
  final String config;

  const VpnConfigEntity({
    required this.country,
    required this.username,
    required this.password,
    required this.config,
  });

  @override
  List<Object?> get props => [country, username, password, config];
}
