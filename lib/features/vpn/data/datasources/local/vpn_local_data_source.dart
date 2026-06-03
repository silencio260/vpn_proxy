import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/utils/app_constants.dart';
import '../../../domain/entities/vpn_server_health_entity.dart';
import '../../models/vpn_server_health_model.dart';
import '../../models/vpn_server_model.dart';

abstract class VpnLocalDataSource {
  Future<List<VpnServerModel>> getCachedVpnServers();
  Future<void> cacheVpnServers(List<VpnServerModel> servers);
  Future<Map<String, VpnServerHealthEntity>> getCachedServerHealth({
    required DateTime now,
    required Duration ttl,
  });
  Future<void> cacheServerHealth(VpnServerHealthEntity health);
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
  Future<Map<String, VpnServerHealthEntity>> getCachedServerHealth({
    required DateTime now,
    required Duration ttl,
  }) async {
    final json = prefs.getString(AppConstants.vpnHealthKey);
    if (json == null) return {};

    final decoded = jsonDecode(json) as Map<String, dynamic>;
    final health = <String, VpnServerHealthEntity>{};
    for (final entry in decoded.entries) {
      final model = VpnServerHealthModel.fromJson(
        entry.value as Map<String, dynamic>,
      );
      if (model.serverKey.isEmpty) continue;
      if (now.difference(model.checkedAt) <= ttl) {
        health[model.serverKey] = model;
      }
    }
    return health;
  }

  @override
  Future<void> cacheServerHealth(VpnServerHealthEntity health) async {
    final json = prefs.getString(AppConstants.vpnHealthKey);
    final decoded =
        json == null
            ? <String, dynamic>{}
            : jsonDecode(json) as Map<String, dynamic>;
    decoded[health.serverKey] =
        VpnServerHealthModel.fromDomain(health).toJson();
    await prefs.setString(AppConstants.vpnHealthKey, jsonEncode(decoded));
  }

  @override
  Future<VpnServerModel?> getCachedSelectedVpn() async {
    final json = prefs.getString(AppConstants.selectedVpnKey);
    if (json == null) return null;
    return VpnServerModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  @override
  Future<void> cacheSelectedVpn(VpnServerModel server) async {
    await prefs.setString(
      AppConstants.selectedVpnKey,
      jsonEncode(server.toJson()),
    );
  }
}
