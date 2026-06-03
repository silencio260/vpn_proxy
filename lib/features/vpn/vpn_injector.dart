import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/network_info.dart';
import 'data/datasources/local/vpn_local_data_source.dart';
import 'data/datasources/remote/vpn_remote_data_source.dart';
import 'data/repositories/vpn_repo.dart';
import 'domain/repositories/vpn_base_repo.dart';
import 'domain/usecases/get_cached_vpn_servers_usecase.dart';
import 'domain/usecases/get_ip_details_usecase.dart';
import 'domain/usecases/get_vpn_servers_usecase.dart';
import 'domain/usecases/save_selected_vpn_usecase.dart';
import 'presentation/bloc/vpn_connection_bloc/vpn_connection_bloc.dart';
import 'presentation/bloc/vpn_servers_bloc/vpn_servers_bloc.dart';
import 'services/vpn_engine_service.dart';
import 'services/vpn_server_health_service.dart';

Future<void> initVpn(GetIt sl) async {
  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<http.Client>(() => http.Client());
  sl.registerLazySingleton<InternetConnectionChecker>(
    () => InternetConnectionChecker(),
  );

  // Core
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl<InternetConnectionChecker>()),
  );

  // Services
  sl.registerLazySingleton<VpnEngineService>(() => VpnEngineService());
  sl.registerLazySingleton<VpnServerHealthService>(
    () => VpnServerHealthService(vpnEngine: sl<VpnEngineService>()),
  );

  // Data sources
  sl.registerLazySingleton<VpnRemoteDataSource>(
    () => VpnRemoteDataSourceImpl(client: sl<http.Client>()),
  );
  sl.registerLazySingleton<VpnLocalDataSource>(
    () => VpnLocalDataSourceImpl(prefs: sl<SharedPreferences>()),
  );

  // Repository
  sl.registerLazySingleton<VpnBaseRepo>(
    () => VpnRepo(
      remoteDataSource: sl<VpnRemoteDataSource>(),
      localDataSource: sl<VpnLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetVpnServersUseCase(repo: sl<VpnBaseRepo>()));
  sl.registerLazySingleton(
    () => GetCachedVpnServersUseCase(repo: sl<VpnBaseRepo>()),
  );
  sl.registerLazySingleton(() => GetIpDetailsUseCase(repo: sl<VpnBaseRepo>()));
  sl.registerLazySingleton(
    () => SaveSelectedVpnUseCase(repo: sl<VpnBaseRepo>()),
  );

  // BLoCs
  sl.registerFactory(
    () => VpnServersBloc(
      getVpnServers: sl<GetVpnServersUseCase>(),
      getCachedVpnServers: sl<GetCachedVpnServersUseCase>(),
      saveSelectedVpn: sl<SaveSelectedVpnUseCase>(),
      localDataSource: sl<VpnLocalDataSource>(),
      healthService: sl<VpnServerHealthService>(),
    ),
  );
  sl.registerFactory(
    () => VpnConnectionBloc(
      vpnEngine: sl<VpnEngineService>(),
      getIpDetails: sl<GetIpDetailsUseCase>(),
    ),
  );
}
