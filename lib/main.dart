import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
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

      await StarterKit.initialize(supportEmail: _supportEmail);

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

      // Log the launch. Fire-and-forget — logging must never block startup.
      // (Firebase itself is initialised above; the kit's analytics repository
      // needs no separate init call.)
      StarterKit.analytics.logAppOpen();

      runApp(const MyApp());
    },
    (error, stack) {
      StarterKit.analytics.recordError(error, stack, fatal: true);
    },
  );
}
