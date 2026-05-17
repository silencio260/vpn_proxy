import 'package:get_it/get_it.dart';

import 'features/vpn/vpn_injector.dart';

final sl = GetIt.instance;

Future<void> initAppDependencies() async {
  await initVpn(sl);
}
