import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:genrevibes_starter_kit/starter_kit.dart';

import 'bloc_observer.dart';
import 'config/app_env.dart';
import 'container_injector.dart';
import 'core/ads/ads_dev_control.dart';
import 'core/ads/app_open_ad_manager.dart';
import 'core/dev/proxy_display_dev_control.dart';
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
      // Mixpanel. Firebase's app instance id is already persisted per install,
      // so we reuse it rather than minting our own. It is null only when
      // analytics collection is unavailable, in which case StarterKit.initialize
      // skips setUserId.
      final installId = await FirebaseAnalytics.instance.appInstanceId;

      // StarterKit.initialize drives the full retention pipeline on launch
      // (logs app_open, RetentionTracker.trackAppOpen with all D0–D30 and
      // first-five open/session milestones, and UserTargetingManager segment
      // logging + the resume-driven session observer). Do NOT log app_open
      // separately below — that would double-count opens.
      //
      // Mixpanel is initialized here from the env-provided token before any
      // startup events fire, so retention/segment events reach Mixpanel too.
      // With an empty token the kit's Mixpanel SDK stays a safe no-op and
      // events go to Firebase only. mixpanelDistinctId reuses the Firebase
      // install id so a user maps to the same id across providers.
      await StarterKit.initialize(
        supportEmail: _supportEmail,
        analyticsUserId: installId,
        mixpanelToken: AppEnv.mixpanelTokenOrNull,
        mixpanelDistinctId: installId,
        feedbackNestApiKey: AppEnv.feedbackNestApiKeyOrNull,
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

      // Load developer ad switches (debug-only Profile → Developer section)
      // before deciding whether to initialize ads. When "disable ad requests"
      // is on we skip AdsInitialize entirely, so the SDK makes no ad requests.
      await AdsDevControl.instance.load();

      // Load the developer proxy-display switch (debug-only Profile →
      // Developer). Controls whether proxy cards reveal the raw server IP.
      await ProxyDisplayDevControl.instance.load();

      // Initialize AdMob and preload ads. AdsInitialize sets up the SDK and
      // auto-preloads interstitial + app-open (and reloads them after each
      // show). Ad unit ids come from the env config; when a build has none
      // configured they are null and that ad type simply never loads. Ads are
      // suppressed automatically for premium users via AdSuppressionManager.
      // Interstitial/app-open frequency is capped so users aren't spammed.
      if (AdsDevControl.instance.requestsAllowed) {
        StarterKit.adsBloc.add(
          AdsInitialize(
            config: AdsConfig(
              bannerAdUnitId: AppEnv.bannerAdIdOrNull,
              interstitialAdUnitId: AppEnv.interstitialAdIdOrNull,
              rewardedAdUnitId: AppEnv.rewardedAdIdOrNull,
              nativeAdUnitId: AppEnv.nativeAdIdOrNull,
              appOpenAdUnitId: AppEnv.appOpenAdIdOrNull,
              minInterstitialInterval: 60,
              minAppOpenInterval: 60,
            ),
          ),
        );
      }

      // Note: app_open and the retention/session/segment events are already
      // logged by StarterKit.initialize above. No explicit logAppOpen call
      // here — doing so would emit a duplicate app_open per launch.

      // Mount the Mixpanel session-replay capture surface at the app root.
      // mixpanelWrapper mounts MixpanelSessionReplayWidget, which actually
      // records the UI for Mixpanel Session Replay (masking all text + images
      // by default). Mixpanel events were already initialized in
      // StarterKit.initialize above, so the wrapper's re-init is a no-op — its
      // purpose here is the replay capture surface. No-op with no token.
      //
      // AppOpenAdManager shows the preloaded App Open ad when the app returns
      // to the foreground (skips the cold-start resume behind the splash).
      runApp(
        StarterKit.mixpanelWrapper(
          token: AppEnv.mixpanelToken,
          distinctId: installId ?? '',
          child: const AppOpenAdManager(child: MyApp()),
        ),
      );
    },
    (error, stack) {
      StarterKit.analytics.recordError(error, stack, fatal: true);
    },
  );
}
