import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/utils/app_constants.dart';
import '../../models/proxy_model.dart';

abstract class ProxyLocalDataSource {
  Future<List<ProxyModel>> getCachedProxies();
  Future<void> cacheProxies(List<ProxyModel> proxies);
}

class ProxyLocalDataSourceImpl implements ProxyLocalDataSource {
  final SharedPreferences prefs;

  ProxyLocalDataSourceImpl({required this.prefs});

  @override
  Future<List<ProxyModel>> getCachedProxies() async {
    final json = prefs.getString(AppConstants.proxyListCacheKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => ProxyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheProxies(List<ProxyModel> proxies) async {
    final json = jsonEncode(proxies.map((p) => p.toJson()).toList());
    await prefs.setString(AppConstants.proxyListCacheKey, json);
  }
}
