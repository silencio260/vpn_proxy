import 'package:flutter/widgets.dart';

import 'app_analytics_service.dart';

/// Logs a `screen_view` whenever a named route becomes the top of the stack.
///
/// Attach to `MaterialApp.navigatorObservers` so every push/pop/replace between
/// the app's named routes is reported automatically — no per-screen wiring.
/// Anonymous routes (dialogs, sheets with no `settings.name`) are skipped.
class AnalyticsRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  void _log(Route<dynamic>? route) {
    if (route is! PageRoute) return;
    final name = route.settings.name;
    if (name == null || name.isEmpty) return;
    AppAnalyticsService.instance.logScreenView(
      name,
      debugLog: AppAnalyticsService.debugLogging,
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _log(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _log(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // Returning to the screen underneath counts as viewing it again.
    _log(previousRoute);
  }
}
