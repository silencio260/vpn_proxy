import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/error/error_handler.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/utils/app_constants.dart';
import '../../models/proxy_deep_model.dart';
import '../../models/proxy_health_model.dart';
import '../../models/proxy_model.dart';

/// The unwrapped `published/current` document: the flat proxy list plus the
/// health/deep/enabled maps, all keyed by proxy id.
class ProxySnapshot {
  final DateTime? updatedAt;
  final int count;
  final List<ProxyModel> proxies;
  final Map<String, ProxyHealthModel> health;
  final Map<String, ProxyDeepModel> deep;
  final Map<String, bool> enabled;

  const ProxySnapshot({
    required this.updatedAt,
    required this.count,
    required this.proxies,
    required this.health,
    required this.deep,
    required this.enabled,
  });
}

abstract class ProxyRemoteDataSource {
  Future<ProxySnapshot> getProxySnapshot();
}

class ProxyRemoteDataSourceImpl implements ProxyRemoteDataSource {
  final http.Client client;

  ProxyRemoteDataSourceImpl({required this.client});

  @override
  Future<ProxySnapshot> getProxySnapshot() async {
    try {
      final response = await client
          .get(Uri.parse(AppConstants.firestorePublishedProxiesUrl))
          .timeout(Duration(seconds: AppConstants.requestTimeout));

      if (response.statusCode == 404) throw const NotFoundFailure();
      if (response.statusCode == 429) throw const TooManyRequestsFailure();
      if (response.statusCode >= 500) throw const ServerFailure();
      if (response.statusCode != 200) {
        throw Exception('Failed to load proxies: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final fields = decoded['fields'] as Map<String, dynamic>? ?? {};
      final unwrapped = _unwrapFields(fields);
      return _parseSnapshot(unwrapped);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ErrorHandler.handle(e);
    }
  }

  static Map<String, dynamic> _unwrapFields(Map<String, dynamic> fields) =>
      fields.map(
        (key, value) =>
            MapEntry(key, _unwrapFirestoreValue(value as Map<String, dynamic>)),
      );

  /// Converts a single Firestore typed-JSON value (`{"stringValue": "..."}`
  /// etc.) into a plain Dart value, recursing into arrays/maps.
  static dynamic _unwrapFirestoreValue(Map<String, dynamic> value) {
    if (value.containsKey('stringValue')) return value['stringValue'] as String;
    if (value.containsKey('integerValue')) {
      return int.parse(value['integerValue'].toString());
    }
    if (value.containsKey('doubleValue')) {
      return (value['doubleValue'] as num).toDouble();
    }
    if (value.containsKey('booleanValue')) return value['booleanValue'] as bool;
    if (value.containsKey('nullValue')) return null;
    if (value.containsKey('arrayValue')) {
      final values =
          (value['arrayValue'] as Map<String, dynamic>)['values']
              as List<dynamic>? ??
          [];
      return values
          .map((v) => _unwrapFirestoreValue(v as Map<String, dynamic>))
          .toList();
    }
    if (value.containsKey('mapValue')) {
      final mapFields =
          (value['mapValue'] as Map<String, dynamic>)['fields']
              as Map<String, dynamic>? ??
          {};
      return _unwrapFields(mapFields);
    }
    return null;
  }

  static ProxySnapshot _parseSnapshot(Map<String, dynamic> doc) {
    final proxiesRaw = doc['proxies'] as List<dynamic>? ?? [];
    final proxies =
        proxiesRaw
            .whereType<Map<String, dynamic>>()
            .map((m) => ProxyModel.fromJson(m))
            .where((p) => p.id.isNotEmpty)
            .toList();

    final healthRaw = doc['health'] as Map<String, dynamic>? ?? {};
    final health = healthRaw.map(
      (id, v) =>
          MapEntry(id, ProxyHealthModel.fromJson(v as Map<String, dynamic>)),
    );

    final deepRaw = doc['deep'] as Map<String, dynamic>? ?? {};
    final deep = deepRaw.map(
      (id, v) =>
          MapEntry(id, ProxyDeepModel.fromJson(v as Map<String, dynamic>)),
    );

    final enabledRaw = doc['enabled'] as Map<String, dynamic>? ?? {};
    final enabled = enabledRaw.map((id, v) => MapEntry(id, v == true));

    return ProxySnapshot(
      updatedAt: DateTime.tryParse(doc['updatedAt']?.toString() ?? ''),
      count: (doc['count'] as int?) ?? proxies.length,
      proxies: proxies,
      health: health,
      deep: deep,
      enabled: enabled,
    );
  }
}
