import 'dart:io' show Platform;

import 'package:starter_kit/starter_kit.dart';

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

  // --- Connection lifecycle ---

  void logProxyConnectTapped(ProxyEntity proxy) => logEvent(
    AppAnalyticsEvents.proxyConnectTapped,
    parameters: _proxyParams(proxy),
  );

  void logProxyConnected(ProxyEntity proxy) => logEvent(
    AppAnalyticsEvents.proxyConnected,
    parameters: _proxyParams(proxy),
  );

  void logProxyConnectFailed(ProxyEntity proxy, {String? reason}) => logEvent(
    AppAnalyticsEvents.proxyConnectFailed,
    parameters: {
      ..._proxyParams(proxy),
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    },
  );

  void logProxyDisconnected({String source = 'user'}) => logEvent(
    AppAnalyticsEvents.proxyDisconnected,
    parameters: {'source': source, ..._platform()},
  );

  // --- Selection ---

  void logProxySelected(ProxyEntity proxy, {bool auto = false}) => logEvent(
    auto
        ? AppAnalyticsEvents.serverAutoSelected
        : AppAnalyticsEvents.proxySelected,
    parameters: _proxyParams(proxy),
  );

  // --- Speed test ---

  void logSpeedTestStarted() => logEvent(
    AppAnalyticsEvents.speedTestStarted,
    parameters: _platform(),
  );

  void logSpeedTestCompleted({
    double? downloadMbps,
    double? uploadMbps,
    int? pingMs,
  }) => logEvent(
    AppAnalyticsEvents.speedTestCompleted,
    parameters: {
      if (downloadMbps != null) 'download_mbps': downloadMbps,
      if (uploadMbps != null) 'upload_mbps': uploadMbps,
      if (pingMs != null) 'ping_ms': pingMs,
      ..._platform(),
    },
  );

  // --- Internal enrichment ---

  /// PII-safe subset of a proxy. Deliberately omits the raw share link and the
  /// server IP/host; keeps protocol/transport/label and a coarse health flag.
  Map<String, dynamic> _proxyParams(ProxyEntity proxy) => {
    'protocol': proxy.type,
    'network': proxy.network,
    'tls': proxy.tls,
    if (proxy.remark.isNotEmpty) 'server_label': proxy.remark,
    'has_health': proxy.health != null,
    ..._platform(),
  };

  Map<String, dynamic> _platform() => {'platform': Platform.operatingSystem};
}
