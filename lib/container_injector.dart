import 'package:get_it/get_it.dart';

import 'features/proxy/proxy_injector.dart';
import 'features/settings/settings_injector.dart';
import 'features/vpn/vpn_injector.dart';

final sl = GetIt.instance;

Future<void> initAppDependencies() async {
  await initVpn(sl);
  // Settings before proxy: ProxyConnectionBloc depends on the settings cubit.
  await initSettings(sl);
  await initProxy(sl);
}
