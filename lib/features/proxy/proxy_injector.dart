import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/network_info.dart';
import 'data/datasources/local/proxy_local_data_source.dart';
import 'data/datasources/remote/proxy_remote_data_source.dart';
import 'data/repositories/proxy_repo.dart';
import 'domain/repositories/proxy_base_repo.dart';
import 'domain/usecases/get_cached_proxies_usecase.dart';
import 'domain/usecases/get_proxies_usecase.dart';
import 'presentation/bloc/proxy_bloc/proxy_bloc.dart';
import 'presentation/bloc/proxy_connection_bloc/proxy_connection_bloc.dart';
import 'services/proxy_engine_service.dart';

/// Registers the proxy feature's dependencies. Must run after `initVpn(sl)`
/// since it reuses the `http.Client`/`NetworkInfo`/`SharedPreferences`
/// singletons registered there instead of creating new instances.
Future<void> initProxy(GetIt sl) async {
  // Services (Xray-core engine that dials the proxy share links)
  sl.registerLazySingleton<ProxyEngineService>(() => ProxyEngineService());

  // Data sources
  sl.registerLazySingleton<ProxyRemoteDataSource>(
    () => ProxyRemoteDataSourceImpl(client: sl<http.Client>()),
  );
  sl.registerLazySingleton<ProxyLocalDataSource>(
    () => ProxyLocalDataSourceImpl(prefs: sl<SharedPreferences>()),
  );

  // Repository
  sl.registerLazySingleton<ProxyBaseRepo>(
    () => ProxyRepo(
      remoteDataSource: sl<ProxyRemoteDataSource>(),
      localDataSource: sl<ProxyLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(
    () => GetProxiesUseCase(repo: sl<ProxyBaseRepo>()),
  );
  sl.registerLazySingleton(
    () => GetCachedProxiesUseCase(repo: sl<ProxyBaseRepo>()),
  );

  // BLoCs
  sl.registerFactory(
    () => ProxyBloc(
      getProxies: sl<GetProxiesUseCase>(),
      getCachedProxies: sl<GetCachedProxiesUseCase>(),
    ),
  );
  sl.registerFactory(
    () => ProxyConnectionBloc(engine: sl<ProxyEngineService>()),
  );
}
