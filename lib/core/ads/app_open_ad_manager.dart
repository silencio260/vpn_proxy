import 'package:flutter/material.dart';
import 'package:genrevibes_starter_kit/starter_kit.dart';

/// Shows an App Open ad when the app returns to the foreground.
///
/// Wraps the app root and observes lifecycle changes. On resume from background
/// it asks the [AdsBloc] to show the preloaded App Open ad — which is loaded by
/// `AdsInitialize` at startup and auto-reloaded after each show. The bloc gates
/// the show on premium status, suppression (no ad over a modal/another ad), and
/// the configured interval, so this only needs to trigger the attempt.
///
/// The first resume after cold start is intentionally skipped: at launch the
/// splash is on screen and the ad isn't loaded yet, and an App Open ad over a
/// cold start is jarring. It then serves on every subsequent foreground.
class AppOpenAdManager extends StatefulWidget {
  final Widget child;
  const AppOpenAdManager({super.key, required this.child});

  @override
  State<AppOpenAdManager> createState() => _AppOpenAdManagerState();
}

class _AppOpenAdManagerState extends State<AppOpenAdManager>
    with WidgetsBindingObserver {
  bool _isFirstResume = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_isFirstResume) {
      _isFirstResume = false;
      return;
    }
    StarterKit.adsBloc.add(const AdsShowAppOpen());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
