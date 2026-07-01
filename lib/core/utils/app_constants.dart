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
}
