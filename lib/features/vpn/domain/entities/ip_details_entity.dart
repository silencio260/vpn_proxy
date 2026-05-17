import 'package:equatable/equatable.dart';

class IpDetailsEntity extends Equatable {
  final String country;
  final String regionName;
  final String city;
  final String timezone;
  final String isp;
  final String query;

  const IpDetailsEntity({
    required this.country,
    required this.regionName,
    required this.city,
    required this.timezone,
    required this.isp,
    required this.query,
  });

  static const empty = IpDetailsEntity(
    country: '',
    regionName: '',
    city: '',
    timezone: '',
    isp: '',
    query: '',
  );

  @override
  List<Object?> get props => [country, regionName, city, timezone, isp, query];
}
