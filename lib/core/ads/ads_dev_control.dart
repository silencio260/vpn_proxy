import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Developer-only runtime switches for ads, surfaced in the Profile → Developer
/// section (debug builds only). Persisted so a chosen state survives restarts.
///
/// Two independent flags:
///  • [displayDisabled] — ads are still requested/preloaded but never shown.
///  • [requestsDisabled] — the ads SDK is not initialized at launch, so no ad
///    requests happen at all (implies nothing is shown).
///
/// Display is enforced by the only places the app shows an ad: the home banner
/// (an `AnimatedBuilder` on [listenable]) and the interstitial / app-open
/// triggers (which check [adsHidden] before requesting a show). Request
/// blocking is evaluated once at startup, so toggling it takes effect on the
/// next launch — the UI notes this.
class AdsDevControl {
  AdsDevControl._();
  static final AdsDevControl instance = AdsDevControl._();

  static const _kDisplayKey = 'dev_ads_display_disabled';
  static const _kRequestsKey = 'dev_ads_requests_disabled';

  final ValueNotifier<bool> displayDisabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> requestsDisabled = ValueNotifier<bool>(false);

  /// Something wants ads hidden — either the display flag, or requests are off
  /// (which also means nothing should show).
  bool get adsHidden => displayDisabled.value || requestsDisabled.value;

  /// Whether the ads SDK should be initialized / ad requests allowed at launch.
  bool get requestsAllowed => !requestsDisabled.value;

  /// A [Listenable] that fires when either flag changes — for widgets that
  /// need to rebuild (e.g. the home banner).
  Listenable get listenable =>
      Listenable.merge([displayDisabled, requestsDisabled]);

  /// Load persisted flags. Call once at startup before dispatching
  /// `AdsInitialize`.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    displayDisabled.value = prefs.getBool(_kDisplayKey) ?? false;
    requestsDisabled.value = prefs.getBool(_kRequestsKey) ?? false;
  }

  Future<void> setDisplayDisabled(bool value) async {
    displayDisabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDisplayKey, value);
  }

  Future<void> setRequestsDisabled(bool value) async {
    requestsDisabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRequestsKey, value);
  }
}
