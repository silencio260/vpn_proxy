import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/routes_manager.dart';
import 'config/theme_cubit.dart';
import 'config/theme_manager.dart';
import 'container_injector.dart';
import 'features/vpn/presentation/bloc/vpn_connection_bloc/vpn_connection_bloc.dart';
import 'features/vpn/presentation/bloc/vpn_servers_bloc/vpn_servers_bloc.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<VpnServersBloc>()),
        BlocProvider(create: (_) => sl<VpnConnectionBloc>()),
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
          );
        },
      ),
    );
  }
}
