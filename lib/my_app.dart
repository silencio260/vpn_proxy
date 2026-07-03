import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:starter_kit/starter_kit.dart';

import 'config/routes_manager.dart';
import 'config/theme_cubit.dart';
import 'config/theme_manager.dart';
import 'container_injector.dart';
import 'core/analytics/analytics_route_observer.dart';
import 'features/proxy/presentation/bloc/proxy_bloc/proxy_bloc.dart';
import 'features/proxy/presentation/bloc/proxy_connection_bloc/proxy_connection_bloc.dart';
import 'features/settings/presentation/cubit/connection_settings_cubit.dart';
import 'features/vpn/presentation/bloc/vpn_connection_bloc/vpn_connection_bloc.dart';
import 'features/vpn/presentation/bloc/vpn_servers_bloc/vpn_servers_bloc.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Expose the starter kit's analytics bloc to the widget tree so
        // screens can read it via context if needed. `.value` because the kit
        // owns the bloc's lifecycle.
        BlocProvider<AnalyticsBloc>.value(value: StarterKit.analyticsBloc),
        BlocProvider(create: (_) => sl<VpnServersBloc>()),
        BlocProvider(create: (_) => sl<VpnConnectionBloc>()),
        BlocProvider(create: (_) => sl<ProxyBloc>()),
        BlocProvider(create: (_) => sl<ProxyConnectionBloc>()),
        // `.value` because GetIt owns this singleton's lifecycle (it is also
        // read by ProxyConnectionBloc outside the widget tree).
        BlocProvider<ConnectionSettingsCubit>.value(
          value: sl<ConnectionSettingsCubit>(),
        ),
        BlocProvider(create: (_) => ThemeCubit()..load()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) {
          return MaterialApp(
            title: 'VPN Proxy',
            debugShowCheckedModeBanner: false,
            theme: ThemeManager.lightTheme,
            darkTheme: ThemeManager.darkTheme,
            themeMode: mode,
            initialRoute: Routes.splash,
            onGenerateRoute: AppRouter.getRoute,
            navigatorObservers: [AnalyticsRouteObserver()],
          );
        },
      ),
    );
  }
}
