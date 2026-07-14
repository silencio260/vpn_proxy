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
  // v2: cache entries written before the deep geo fields (egressRegion/
  // egressCity) existed lack the state — bumping the key discards them so the
  // list is refetched with the full geo data.
  static const String proxyListCacheKey = 'proxy_list_v2';

  /// Local HTTP proxy inbound the proxy engine adds to the Xray config.
  /// Requests sent through 127.0.0.1:this port egress at the tunnel exit node
  /// — even from this app, which is otherwise excluded from the tunnel. Used
  /// by the dev IP check to verify the tunnel's egress IP/location.
  static const int localHttpProxyPort = 10809;
}
