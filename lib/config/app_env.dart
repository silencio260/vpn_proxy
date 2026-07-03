/// Compile-time environment configuration.
///
/// Values are injected at build time via `--dart-define-from-file=env/<env>.json`
/// (see `.run/` and `.vscode/launch.json`). Reading them through
/// `String.fromEnvironment` / `bool.fromEnvironment` keeps secrets out of the
/// source tree — the `env/` folder is gitignored; only `env.example.json` is
/// committed as a key reference.
///
/// Every environment key used by the app is surfaced here so consumers read a
/// single typed source of truth instead of scattering `fromEnvironment` calls.
class AppEnv {
  const AppEnv._();

  // --- Build flags ---
  static const bool foundersVersion =
      bool.fromEnvironment('founders_version', defaultValue: false);
  static const bool specialVersionMode =
      bool.fromEnvironment('special_version_mode', defaultValue: false);
  static const bool developmentMode =
      bool.fromEnvironment('development_mode', defaultValue: false);

  // --- Firebase ---
  static const String firebaseApiKeyAndroid =
      String.fromEnvironment('firebase_api_key_android');
  static const String firebaseApiKeyIos =
      String.fromEnvironment('firebase_api_key_ios');

  // --- Backend ---
  static const String cloudFunctionsBaseUrl =
      String.fromEnvironment('cloud_functions_base_url');

  // --- AdMob ad unit IDs ---
  static const String bannerAdId = String.fromEnvironment('banner_ad_id');
  static const String interstitialAdId =
      String.fromEnvironment('interstitial_ad_id');
  static const String appOpenAdId = String.fromEnvironment('app_open_ad_id');
  static const String rewardedAdId = String.fromEnvironment('rewarded_ad_id');
  static const String nativeAdId = String.fromEnvironment('native_ad_id');

  // --- Push / IAP ---
  static const String oneSignalAppId =
      String.fromEnvironment('one_signal_app_id');
  static const String revenueCatApiKeyAndroid =
      String.fromEnvironment('revenue_cat_api_key_android');

  // --- Analytics ---
  static const String posthogApiKey =
      String.fromEnvironment('posthog_api_key');
  static const String posthogHost = String.fromEnvironment(
    'posthog_host',
    defaultValue: 'https://app.posthog.com',
  );
  static const String mixpanelToken =
      String.fromEnvironment('mixpanel_token');

  // --- Feedback ---
  static const String feedbackNestApiKey =
      String.fromEnvironment('feed_back_nest_api_key');

  /// Convenience: returns [value] or `null` when blank, so optional config can
  /// be passed straight to APIs that treat `null` as "not configured".
  static String? _orNull(String value) => value.isEmpty ? null : value;

  static String? get mixpanelTokenOrNull => _orNull(mixpanelToken);
  static String? get feedbackNestApiKeyOrNull => _orNull(feedbackNestApiKey);
}
