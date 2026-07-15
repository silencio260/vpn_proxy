import 'dart:async';
import 'dart:io';
import 'dart:math';

import '../../../core/network/network_info.dart';
import '../../../core/utils/app_constants.dart';
import '../domain/entities/proxy_entity.dart';
import 'proxy_engine_service.dart';

class ProxyProbeResult {
  final ProxyEntity proxy;
  final bool alive;
  final int? latencyMs;

  const ProxyProbeResult({
    required this.proxy,
    required this.alive,
    this.latencyMs,
  });
}

/// Live, device-side availability checks. Database health is used only to
/// order candidates; every selected proxy must pass these checks in the
/// current network session before it is treated as connected.
class ProxyAvailabilityService {
  final NetworkInfo networkInfo;
  final ProxyEngineService engine;

  static const _directCheckTimeout = Duration(milliseconds: 2500);
  static const _socketTimeout = Duration(milliseconds: 850);
  static const _proxyCheckTimeout = Duration(seconds: 4);
  static const _parallelPreflightCount = 8;

  static final _directCheckUris = <Uri>[
    Uri.parse('https://www.google.com/generate_204'),
    Uri.parse('https://www.cloudflare.com/cdn-cgi/trace'),
  ];

  const ProxyAvailabilityService({
    required this.networkInfo,
    required this.engine,
  });

  /// Uses the existing connectivity checker plus two direct HTTPS paths. The
  /// app package bypasses the VPN service, so these requests represent the
  /// user's own network even while Xray is running.
  Future<bool> hasDirectInternet() async {
    final checker = networkInfo.isConnected
        .timeout(_directCheckTimeout, onTimeout: () => false)
        .catchError((_) => false);
    final endpointChecks = _directCheckUris.map(_canReachDirectly).toList();
    final results = await Future.wait<bool>([checker, ...endpointChecks]);
    return results.any((reachable) => reachable);
  }

  Future<bool> _canReachDirectly(Uri uri) async {
    final client = HttpClient()
      ..connectionTimeout = _directCheckTimeout
      ..findProxy = (_) => 'DIRECT';
    try {
      final request = await client.getUrl(uri).timeout(_directCheckTimeout);
      final response = await request.close().timeout(_directCheckTimeout);
      await response.drain<void>().timeout(_directCheckTimeout);
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  /// Finds the first fully usable proxy. TCP probes run concurrently in small
  /// batches; successful endpoints are then verified with Xray's full outbound
  /// delay test because an open port alone does not prove the proxy works.
  Future<ProxyProbeResult?> findAvailable(
    Iterable<ProxyEntity> candidates, {
    Set<String> excludedIds = const {},
  }) async {
    final ordered =
        candidates
            .where(
              (proxy) =>
                  !proxy.isEmpty &&
                  !excludedIds.contains(proxy.id) &&
                  proxy.address.isNotEmpty &&
                  proxy.port > 0,
            )
            .toList()
          ..sort(_compareDatabaseHints);
    final random = Random.secure();
    _shuffleQualityWindows(ordered, random);

    for (
      var offset = 0;
      offset < ordered.length;
      offset += _parallelPreflightCount
    ) {
      final proposedEnd = offset + _parallelPreflightCount;
      final end = proposedEnd < ordered.length ? proposedEnd : ordered.length;
      final batch = ordered.sublist(offset, end);
      final reachable =
          (await Future.wait(
            batch.map(_tcpProbe),
          )).where((result) => result.alive).toList()..sort(
            (a, b) => (a.latencyMs ?? 999999).compareTo(b.latencyMs ?? 999999),
          );
      _shuffleFastestWindows(reachable, random);

      for (final result in reachable) {
        final verified = await verifyProxy(
          result.proxy,
          preflightLatencyMs: result.latencyMs ?? 0,
        );
        if (verified.alive) return verified;
      }
    }
    return null;
  }

  /// Debug support: searches for a genuinely unavailable configuration using
  /// the same device-side probes as production. Database-dead entries are
  /// attempted first, but a server is returned only after a live check fails.
  Future<ProxyEntity?> findUnavailable(Iterable<ProxyEntity> candidates) async {
    final random = Random.secure();
    final usable = candidates
        .where(
          (proxy) =>
              !proxy.isEmpty && proxy.address.isNotEmpty && proxy.port > 0,
        )
        .toList();
    final likelyDead = usable.where((proxy) => _statusRank(proxy) == 2).toList()
      ..shuffle(random);
    final remaining = usable.where((proxy) => _statusRank(proxy) != 2).toList()
      ..shuffle(random);
    final ordered = <ProxyEntity>[...likelyDead, ...remaining];

    for (
      var offset = 0;
      offset < ordered.length;
      offset += _parallelPreflightCount
    ) {
      final proposedEnd = offset + _parallelPreflightCount;
      final end = proposedEnd < ordered.length ? proposedEnd : ordered.length;
      final results = await Future.wait(
        ordered.sublist(offset, end).map(_tcpProbe),
      );
      final unreachable = results.where((result) => !result.alive).toList()
        ..shuffle(random);
      if (unreachable.isNotEmpty) return unreachable.first.proxy;

      results.shuffle(random);
      for (final result in results) {
        final verified = await verifyProxy(
          result.proxy,
          preflightLatencyMs: result.latencyMs ?? 0,
        );
        if (!verified.alive) return result.proxy;
      }
    }
    return null;
  }

  Future<ProxyProbeResult> verifyProxy(
    ProxyEntity proxy, {
    int? preflightLatencyMs,
  }) async {
    final endpoint = preflightLatencyMs == null
        ? await _tcpProbe(proxy)
        : ProxyProbeResult(
            proxy: proxy,
            alive: true,
            latencyMs: preflightLatencyMs,
          );
    if (!endpoint.alive) return endpoint;

    try {
      final delay = await engine
          .getServerDelay(proxy)
          .timeout(_proxyCheckTimeout, onTimeout: () => -1);
      return ProxyProbeResult(
        proxy: proxy,
        alive: delay >= 0,
        latencyMs: delay >= 0 ? delay : endpoint.latencyMs,
      );
    } catch (_) {
      return ProxyProbeResult(
        proxy: proxy,
        alive: false,
        latencyMs: endpoint.latencyMs,
      );
    }
  }

  Future<bool> isConnectedProxyAlive() async {
    final checks = await Future.wait<bool>(
      _directCheckUris.map(_canReachViaConnectedProxy),
    );
    return checks.any((reachable) => reachable);
  }

  /// Sends an actual HTTPS request through Xray's local HTTP inbound. This is
  /// more reliable than the plugin's connected-delay callback during startup,
  /// and proves that traffic can traverse the active proxy end to end.
  Future<bool> _canReachViaConnectedProxy(Uri uri) async {
    final client = HttpClient()
      ..connectionTimeout = _proxyCheckTimeout
      ..findProxy = (_) => 'PROXY 127.0.0.1:${AppConstants.localHttpProxyPort}';
    try {
      final request = await client.getUrl(uri).timeout(_proxyCheckTimeout);
      final response = await request.close().timeout(_proxyCheckTimeout);
      await response.drain<void>().timeout(_proxyCheckTimeout);
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<ProxyProbeResult> _tcpProbe(ProxyEntity proxy) async {
    final watch = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(
        proxy.address,
        proxy.port,
        timeout: _socketTimeout,
      );
      watch.stop();
      return ProxyProbeResult(
        proxy: proxy,
        alive: true,
        latencyMs: watch.elapsedMilliseconds,
      );
    } catch (_) {
      watch.stop();
      return ProxyProbeResult(
        proxy: proxy,
        alive: false,
        latencyMs: watch.elapsedMilliseconds,
      );
    } finally {
      socket?.destroy();
    }
  }

  static int _compareDatabaseHints(ProxyEntity a, ProxyEntity b) {
    final status = _statusRank(a).compareTo(_statusRank(b));
    if (status != 0) return status;
    final latencyA = a.health?.latencyMs ?? a.deep?.realLatencyMs ?? 999999;
    final latencyB = b.health?.latencyMs ?? b.deep?.realLatencyMs ?? 999999;
    return latencyA.compareTo(latencyB);
  }

  static int _statusRank(ProxyEntity proxy) {
    if (proxy.health?.status == 'alive' || proxy.deep?.tunnelOk == true)
      return 0;
    if (proxy.health?.status == 'dead' || proxy.deep?.tunnelOk == false)
      return 2;
    return 1;
  }

  /// Preserve broad health/latency quality while varying candidates within a
  /// small nearby window. This prevents every device with the same published
  /// list from deterministically choosing the exact same first server.
  static void _shuffleQualityWindows(List<ProxyEntity> proxies, Random random) {
    var groupStart = 0;
    while (groupStart < proxies.length) {
      final rank = _statusRank(proxies[groupStart]);
      var groupEnd = groupStart + 1;
      while (groupEnd < proxies.length &&
          _statusRank(proxies[groupEnd]) == rank) {
        groupEnd++;
      }
      for (var offset = groupStart; offset < groupEnd; offset += 4) {
        final end = offset + 4 < groupEnd ? offset + 4 : groupEnd;
        final window = proxies.sublist(offset, end)..shuffle(random);
        proxies.setRange(offset, end, window);
      }
      groupStart = groupEnd;
    }
  }

  /// Live TCP latency still matters, but any of the three fastest reachable
  /// endpoints is a reasonable first full-protocol candidate.
  static void _shuffleFastestWindows(
    List<ProxyProbeResult> results,
    Random random,
  ) {
    for (var offset = 0; offset < results.length; offset += 3) {
      final end = offset + 3 < results.length ? offset + 3 : results.length;
      final window = results.sublist(offset, end)..shuffle(random);
      results.setRange(offset, end, window);
    }
  }
}
