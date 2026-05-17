import 'package:flutter/material.dart';

import '../features/vpn/presentation/screens/home_screen.dart';
import '../features/vpn/presentation/screens/location_screen.dart';
import '../features/vpn/presentation/screens/splash_screen.dart';

class Routes {
  static const String splash = '/';
  static const String home = '/home';
  static const String location = '/location';
}

class AppRouter {
  static Route<dynamic>? getRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case Routes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case Routes.location:
        return MaterialPageRoute(builder: (_) => const LocationScreen());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
