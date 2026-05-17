import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;

import '../../../../../core/error/error_handler.dart';
import '../../../../../core/utils/app_constants.dart';
import '../../models/ip_details_model.dart';
import '../../models/vpn_server_model.dart';

abstract class VpnRemoteDataSource {
  Future<List<VpnServerModel>> getVpnServers();
  Future<IpDetailsModel> getIpDetails();
}

class VpnRemoteDataSourceImpl implements VpnRemoteDataSource {
  final http.Client client;

  VpnRemoteDataSourceImpl({required this.client});

  @override
  Future<List<VpnServerModel>> getVpnServers() async {
    try {
      final response = await client
          .get(Uri.parse(AppConstants.vpnGateUrl))
          .timeout(Duration(seconds: AppConstants.requestTimeout));

      if (response.statusCode != 200) {
        throw Exception('Failed to load VPN servers: ${response.statusCode}');
      }

      final lines = const LineSplitter().convert(response.body);
      // First line is a comment (*vpn_servers), second is CSV header
      final csvLines = lines.where((l) => !l.startsWith('*')).join('\n');

      final rows = const CsvToListConverter(eol: '\n').convert(csvLines);
      if (rows.isEmpty) return [];

      final headers = rows.first.map((e) => e.toString()).toList();
      final servers = <VpnServerModel>[];

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length != headers.length) continue;
        final json = <String, dynamic>{};
        for (int j = 0; j < headers.length; j++) {
          json[headers[j]] = row[j];
        }
        final server = VpnServerModel.fromJson(json);
        if (server.openVpnConfigBase64.isNotEmpty) {
          servers.add(server);
        }
      }

      return servers;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<IpDetailsModel> getIpDetails() async {
    try {
      final response = await client
          .get(Uri.parse(AppConstants.ipDetailsUrl))
          .timeout(Duration(seconds: AppConstants.requestTimeout));

      if (response.statusCode != 200) {
        throw Exception('Failed to get IP details: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return IpDetailsModel.fromJson(json);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
