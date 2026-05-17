class AppConstants {
  static const String vpnGateUrl = 'http://www.vpngate.net/api/iphone/';
  static const String ipDetailsUrl = 'http://ip-api.com/json/';
  static const String vpnListKey = 'vpn_list';
  static const String selectedVpnKey = 'selected_vpn';
  static const int requestTimeout = 30;
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
