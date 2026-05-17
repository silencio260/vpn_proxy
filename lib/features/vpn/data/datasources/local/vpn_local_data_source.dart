import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/utils/app_constants.dart';
import '../../models/vpn_server_model.dart';

abstract class VpnLocalDataSource {
  Future<List<VpnServerModel>> getCachedVpnServers();
  Future<void> cacheVpnServers(List<VpnServerModel> servers);
  Future<VpnServerModel?> getCachedSelectedVpn();
  Future<void> cacheSelectedVpn(VpnServerModel server);
}

class VpnLocalDataSourceImpl implements VpnLocalDataSource {
  final SharedPreferences prefs;

  VpnLocalDataSourceImpl({required this.prefs});

  @override
  Future<List<VpnServerModel>> getCachedVpnServers() async {
    final json = prefs.getString(AppConstants.vpnListKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => VpnServerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheVpnServers(List<VpnServerModel> servers) async {
    final json = jsonEncode(servers.map((s) => s.toJson()).toList());
    await prefs.setString(AppConstants.vpnListKey, json);
  }

  @override
  Future<VpnServerModel?> getCachedSelectedVpn() async {
    final json = prefs.getString(AppConstants.selectedVpnKey);
    if (json == null) return null;
    return VpnServerModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  @override
  Future<void> cacheSelectedVpn(VpnServerModel server) async {
    await prefs.setString(AppConstants.selectedVpnKey, jsonEncode(server.toJson()));
  }
}
