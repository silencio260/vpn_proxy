import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:starter_kit/starter_kit.dart';

import 'bloc_observer.dart';
import 'container_injector.dart';
import 'firebase_options.dart';
import 'my_app.dart';

/// Support address surfaced by the starter kit (feedback, GDPR, etc.).
/// TODO: replace with the real GenRevibes VPN Proxy support inbox.
const String _supportEmail = 'support@genrevibes.com';

Future<void> main() async {
  // runZonedGuarded catches async errors outside the Flutter framework and
  // forwards them to Crashlytics via the starter kit analytics service.
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Firebase must be ready before StarterKit.initialize() wires up
      // Analytics, Crashlytics and Remote Config.
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Stable, non-PII per-install id so retention and segmentation events
      // are attributable to a consistent user across Firebase, Crashlytics and
      // (once a Mixpanel token is configured) Mixpanel/PostHog. Firebase's app
      // instance id is already persisted per install, so we reuse it rather
      // than minting our own. It is null only when analytics collection is
      // unavailable, in which case StarterKit.initialize skips setUserId.
      final installId = await FirebaseAnalytics.instance.appInstanceId;

      // StarterKit.initialize drives the full retention pipeline on launch
      // (logs app_open, RetentionTracker.trackAppOpen with all D0–D30 and
      // first-five open/session milestones, and UserTargetingManager segment
      // logging + the resume-driven session observer). Do NOT log app_open
      // separately below — that would double-count opens.
      await StarterKit.initialize(
        supportEmail: _supportEmail,
        analyticsUserId: installId,
      );

      // Route framework errors to Crashlytics (and DebugView while developing).
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        StarterKit.analytics.recordFlutterError(
          details.exception,
          details.stack,
          fatal: true,
        );
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        StarterKit.analytics.recordError(error, stack, fatal: true);
        return true;
      };

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      // Edge-to-edge with a transparent system nav bar so the app background
      // runs all the way to the bottom instead of showing a dark strip.
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ),
      );

      Bloc.observer = AppBlocObserver();
      await initAppDependencies();

      // Note: app_open and the retention/session/segment events are already
      // logged by StarterKit.initialize above. No explicit logAppOpen call
      // here — doing so would emit a duplicate app_open per launch.

      runApp(const MyApp());
    },
    (error, stack) {
      StarterKit.analytics.recordError(error, stack, fatal: true);
    },
  );
}
