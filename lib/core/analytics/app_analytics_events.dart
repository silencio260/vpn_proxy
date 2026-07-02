/// Single source of truth for this app's analytics event names.
///
/// Keeping every event name as a `static const` here (instead of scattering
/// string literals through blocs and widgets) prevents dashboard-breaking typos
/// and gives one place to audit the Firebase/PostHog naming convention.
///
/// Standard/shared events (`app_open`, `screen_view`, `ad_impression`,
/// retention milestones, …) are owned by the starter kit's `AnalyticsService`
/// and are NOT duplicated here — this dictionary is app-specific only.
abstract class AppAnalyticsEvents {
  // --- Connection lifecycle (Xray proxy engine) ---
  static const String proxyConnectTapped = 'proxy_connect_tapped';
  static const String proxyConnected = 'proxy_connected';
  static const String proxyConnectFailed = 'proxy_connect_failed';
  static const String proxyDisconnected = 'proxy_disconnected';

  // --- Server / proxy selection ---
  static const String proxySelected = 'proxy_selected';
  static const String serverAutoSelected = 'server_auto_selected';

  // --- Tools ---
  static const String speedTestStarted = 'speed_test_started';
  static const String speedTestCompleted = 'speed_test_completed';
}
