import 'package:flutter/material.dart';

import '../features/vpn/presentation/screens/ads_screen.dart';
import '../features/vpn/presentation/screens/home_screen.dart';
import '../features/vpn/presentation/screens/location_screen.dart';
import '../features/vpn/presentation/screens/main_shell.dart';
import '../features/vpn/presentation/screens/onboarding_screen.dart';
import '../features/vpn/presentation/screens/payment_success_screen.dart';
import '../features/vpn/presentation/screens/premium_screen.dart';
import '../features/vpn/presentation/screens/profile_screen.dart';
import '../features/vpn/presentation/screens/speed_test_screen.dart';
import '../features/vpn/presentation/screens/splash_screen.dart';

class Routes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String main = '/main';
  static const String home = '/home';
  static const String location = '/location';
  static const String premium = '/premium';
  static const String paymentSuccess = '/payment-success';
  static const String speedTest = '/speed-test';
  static const String ads = '/ads';
  static const String profile = '/profile';
}

class AppRouter {
  static Route<dynamic>? getRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case Routes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case Routes.main:
        return MaterialPageRoute(builder: (_) => const MainShell());
      case Routes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case Routes.location:
        return MaterialPageRoute(builder: (_) => const LocationScreen());
      case Routes.premium:
        return MaterialPageRoute(builder: (_) => const PremiumScreen());
      case Routes.paymentSuccess:
        return MaterialPageRoute(
          builder: (_) => const PaymentSuccessScreen(),
        );
      case Routes.speedTest:
        return MaterialPageRoute(builder: (_) => const SpeedTestScreen());
      case Routes.ads:
        return MaterialPageRoute(builder: (_) => const AdsScreen());
      case Routes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
