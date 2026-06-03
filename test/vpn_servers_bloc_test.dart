import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vpn_proxy/core/error/failure.dart';
import 'package:vpn_proxy/features/vpn/data/datasources/local/vpn_local_data_source.dart';
import 'package:vpn_proxy/features/vpn/domain/entities/ip_details_entity.dart';
import 'package:vpn_proxy/features/vpn/domain/entities/vpn_server_entity.dart';
import 'package:vpn_proxy/features/vpn/domain/entities/vpn_server_health_entity.dart';
import 'package:vpn_proxy/features/vpn/domain/repositories/vpn_base_repo.dart';
import 'package:vpn_proxy/features/vpn/domain/usecases/get_cached_vpn_servers_usecase.dart';
import 'package:vpn_proxy/features/vpn/domain/usecases/get_vpn_servers_usecase.dart';
import 'package:vpn_proxy/features/vpn/domain/usecases/save_selected_vpn_usecase.dart';
import 'package:vpn_proxy/features/vpn/presentation/bloc/vpn_servers_bloc/vpn_servers_bloc.dart';
import 'package:vpn_proxy/features/vpn/services/vpn_server_health_service.dart';

VpnServerEntity _server(String ip, String country) => VpnServerEntity(
  hostname: '$country.example.com',
  ip: ip,
  ping: '120',
  speed: 50000000,
  countryLong: country,
  countryShort: country.substring(0, 2).toUpperCase(),
  numVpnSessions: 1,
  openVpnConfigBase64: 'config-$ip',
);

class _FakeRepo implements VpnBaseRepo {
  final List<VpnServerEntity> servers;

  _FakeRepo(this.servers);

  @override
  Future<Either<Failure, List<VpnServerEntity>>> getCachedVpnServers() async {
    return Right(servers);
  }

  @override
  Future<Either<Failure, List<VpnServerEntity>>> getVpnServers() async {
    return Right(servers);
  }

  @override
  Future<Either<Failure, IpDetailsEntity>> getIpDetails() async {
    return const Right(
      IpDetailsEntity(
        country: '',
        regionName: '',
        city: '',
        timezone: '',
        isp: '',
        query: '',
      ),
    );
  }

  @override
  Future<Either<Failure, VpnServerEntity>> getCachedSelectedVpn() async {
    return Right(servers.first);
  }

  @override
  Future<Either<Failure, Unit>> saveSelectedVpn(VpnServerEntity server) async {
    return const Right(unit);
  }
}

class _FakeHealthService extends VpnServerHealthService {
  _FakeHealthService();

  @override
  Future<bool> get isVpnBusy async => false;

  @override
  Future<VpnServerHealthEntity> checkServer(VpnServerEntity server) async {
    return VpnServerHealthEntity(
      serverKey: VpnServerHealthService.keyForServer(server),
      status: VpnServerHealthStatus.online,
      latencyMs: 33,
      checkedAt: DateTime.now(),
    );
  }
}

void main() {
  test(
    'loads cached health first then updates missing health in background',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final local = VpnLocalDataSourceImpl(prefs: prefs);
      final servers = [
        _server('10.0.0.1', 'Alpha'),
        _server('10.0.0.2', 'Beta'),
      ];

      await local.cacheServerHealth(
        VpnServerHealthEntity(
          serverKey: '10.0.0.1',
          status: VpnServerHealthStatus.online,
          latencyMs: 70,
          checkedAt: DateTime.now(),
        ),
      );

      final repo = _FakeRepo(servers);
      final bloc = VpnServersBloc(
        getVpnServers: GetVpnServersUseCase(repo: repo),
        getCachedVpnServers: GetCachedVpnServersUseCase(repo: repo),
        saveSelectedVpn: SaveSelectedVpnUseCase(repo: repo),
        localDataSource: local,
        healthService: _FakeHealthService(),
      );
      final states = <VpnServersState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const LoadCachedVpnServersEvent());
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final loadedStates = states.whereType<VpnServersLoaded>().toList();
      expect(loadedStates.first.healthByServerKey['10.0.0.1']?.latencyMs, 70);
      expect(
        loadedStates.last.healthByServerKey['10.0.0.2']?.status,
        VpnServerHealthStatus.online,
      );
      expect(loadedStates.last.isHealthChecking, isFalse);

      await subscription.cancel();
      await bloc.close();
    },
  );
}
