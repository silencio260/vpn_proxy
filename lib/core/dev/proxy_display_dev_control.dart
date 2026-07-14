import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Developer-only runtime switch for what proxy cards reveal at the bottom.
///
/// Cards always show the exit node's state/region from the DB. When this is on,
/// debug builds also reveal the raw proxy server IP on a separate line. The
/// switch is surfaced in the debug-only Profile → Developer section.
///
/// Persisted so a chosen state survives restarts, and exposes a [listenable]
/// so the proxy cards rebuild live when the switch is flipped.
class ProxyDisplayDevControl {
  ProxyDisplayDevControl._();
  static final ProxyDisplayDevControl instance = ProxyDisplayDevControl._();

  static const _kShowIpKey = 'dev_proxy_show_ip';

  final ValueNotifier<bool> showProxyIp = ValueNotifier<bool>(false);

  /// A [Listenable] that fires when the flag changes — for cards that need to
  /// rebuild when the switch is toggled.
  Listenable get listenable => showProxyIp;

  /// Load the persisted flag. Call once at startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    showProxyIp.value = prefs.getBool(_kShowIpKey) ?? false;
  }

  Future<void> setShowProxyIp(bool value) async {
    showProxyIp.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowIpKey, value);
  }
}
