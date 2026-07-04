class AppConstants {
  static const String vpnGateUrl = 'http://www.vpngate.net/api/iphone/';
  static const String ipDetailsUrl = 'http://ip-api.com/json/';
  static const String vpnListKey = 'vpn_list';
  static const String vpnHealthKey = 'vpn_server_health';
  static const String selectedVpnKey = 'selected_vpn';
  static const int requestTimeout = 30;
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration vpnHealthCacheTtl = Duration(hours: 10);

  static const String firestorePublishedProxiesUrl =
      'https://firestore.googleapis.com/v1/projects/vpn-proxy-project-9bb30/databases/(default)/documents/published/current';
  static const String proxyListCacheKey = 'proxy_list';

  /// Local HTTP proxy inbound the proxy engine adds to the Xray config.
  /// Requests sent through 127.0.0.1:this port egress at the tunnel exit node
  /// — even from this app, which is otherwise excluded from the tunnel. Used
  /// by the dev IP check to verify the tunnel's egress IP/location.
  static const int localHttpProxyPort = 10809;
}
