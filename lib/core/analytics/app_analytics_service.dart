import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:genrevibes_starter_kit/starter_kit.dart';

import '../../features/proxy/domain/entities/proxy_entity.dart';
import 'app_analytics_events.dart';

/// App-specific analytics facade.
///
/// Extends the starter kit's generic [AnalyticsService] (which already knows how
/// to log standard events, ad revenue, retention and crashes) and adds typed,
/// business-level methods for the VPN Proxy features. UI/blocs call these
/// methods with the minimal domain data; enrichment (platform, protocol
/// inference, PII-safe field selection) happens here so the presentation layer
/// never assembles raw `Map<String, dynamic>` payloads or hardcodes event names.
///
/// Logging is fire-and-forget: never await these calls on a hot path.
class AppAnalyticsService extends AnalyticsService {
  AppAnalyticsService(super.bloc);

  /// Global singleton bound to the kit's analytics bloc. Available after
  /// [StarterKit.initialize] has run in `main()`.
  static final AppAnalyticsService instance =
      AppAnalyticsService(StarterKit.analyticsBloc);

  /// When true, every app event is also printed to the console (via the kit's
  /// `StarterLog`, tag `[ANALYTICS]`) as it is dispatched — visible in
  /// `flutter logs` / logcat. Defaults to debug builds only; flip on in release
  /// temporarily if you need to confirm wiring on a production build.
  static bool debugLogging = kDebugMode;

  // --- Connection lifecycle ---

  void logProxyConnectTapped(ProxyEntity proxy, {String? mode}) =>
      _log(AppAnalyticsEvents.proxyConnectTapped, _proxyParams(proxy, mode));

  void logProxyConnected(ProxyEntity proxy, {String? mode}) =>
      _log(AppAnalyticsEvents.proxyConnected, _proxyParams(proxy, mode));

  void logProxyConnectFailed(ProxyEntity proxy, {String? reason, String? mode}) =>
      _log(AppAnalyticsEvents.proxyConnectFailed, {
        ..._proxyParams(proxy, mode),
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });

  void logProxyDisconnected({String source = 'user'}) => _log(
    AppAnalyticsEvents.proxyDisconnected,
    {'source': source, ..._platform()},
  );

  // --- Selection ---

  void logProxySelected(ProxyEntity proxy, {bool auto = false}) => _log(
    auto
        ? AppAnalyticsEvents.serverAutoSelected
        : AppAnalyticsEvents.proxySelected,
    _proxyParams(proxy),
  );

  // --- Connection settings ---

  void logConnectionModeChanged(String mode) => _log(
    AppAnalyticsEvents.connectionModeChanged,
    {'mode': mode, ..._platform()},
  );

  void logSplitTunnelUpdated({required int excludedCount}) => _log(
    AppAnalyticsEvents.splitTunnelUpdated,
    {'excluded_count': excludedCount, ..._platform()},
  );

  // --- Speed test ---

  void logSpeedTestStarted() =>
      _log(AppAnalyticsEvents.speedTestStarted, _platform());

  void logSpeedTestCompleted({
    double? downloadMbps,
    double? uploadMbps,
    int? pingMs,
  }) => _log(AppAnalyticsEvents.speedTestCompleted, {
    if (downloadMbps != null) 'download_mbps': downloadMbps,
    if (uploadMbps != null) 'upload_mbps': uploadMbps,
    if (pingMs != null) 'ping_ms': pingMs,
    ..._platform(),
  });

  // --- Internal enrichment ---

  /// Single dispatch point so `debugLogging` is applied uniformly to every
  /// app event.
  void _log(String name, Map<String, dynamic> params) =>
      logEvent(name, parameters: params, debugLog: debugLogging);

  /// PII-safe subset of a proxy. Deliberately omits the raw share link and the
  /// server IP/host; keeps protocol/transport/label and a coarse health flag.
  Map<String, dynamic> _proxyParams(ProxyEntity proxy, [String? mode]) => {
    'protocol': proxy.type,
    'network': proxy.network,
    'tls': proxy.tls,
    if (mode != null) 'mode': mode,
    if (proxy.remark.isNotEmpty) 'server_label': proxy.remark,
    'has_health': proxy.health != null,
    ..._platform(),
  };

  Map<String, dynamic> _platform() => {'platform': Platform.operatingSystem};
}
