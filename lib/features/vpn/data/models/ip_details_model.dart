import '../../domain/entities/ip_details_entity.dart';

class IpDetailsModel extends IpDetailsEntity {
  const IpDetailsModel({
    required super.country,
    required super.regionName,
    required super.city,
    required super.timezone,
    required super.isp,
    required super.query,
  });

  factory IpDetailsModel.fromJson(Map<String, dynamic> json) => IpDetailsModel(
        country: json['country']?.toString() ?? '',
        regionName: json['regionName']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        timezone: json['timezone']?.toString() ?? '',
        isp: json['isp']?.toString() ?? '',
        query: json['query']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'country': country,
        'regionName': regionName,
        'city': city,
        'timezone': timezone,
        'isp': isp,
        'query': query,
      };
}
