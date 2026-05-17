import 'package:dartz/dartz.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/ip_details_entity.dart';
import '../../domain/entities/vpn_server_entity.dart';
import '../../domain/repositories/vpn_base_repo.dart';
import '../datasources/local/vpn_local_data_source.dart';
import '../datasources/remote/vpn_remote_data_source.dart';
import '../mappers.dart';

class VpnRepo implements VpnBaseRepo {
  final VpnRemoteDataSource remoteDataSource;
  final VpnLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  VpnRepo({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<VpnServerEntity>>> getVpnServers() async {
    if (!await networkInfo.isConnected) {
      return Left(NoInternetConnectionFailure());
    }
    try {
      final servers = await remoteDataSource.getVpnServers();
      await localDataSource.cacheVpnServers(servers);
      return Right(servers.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<Failure, List<VpnServerEntity>>> getCachedVpnServers() async {
    try {
      final servers = await localDataSource.getCachedVpnServers();
      return Right(servers.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<Failure, IpDetailsEntity>> getIpDetails() async {
    if (!await networkInfo.isConnected) {
      return Left(NoInternetConnectionFailure());
    }
    try {
      final details = await remoteDataSource.getIpDetails();
      return Right(details.toDomain());
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<Failure, VpnServerEntity>> getCachedSelectedVpn() async {
    try {
      final server = await localDataSource.getCachedSelectedVpn();
      if (server == null) return Right(VpnServerEntity.empty);
      return Right(server.toDomain());
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveSelectedVpn(VpnServerEntity server) async {
    try {
      final model = server.toModel();
      await localDataSource.cacheSelectedVpn(model);
      return const Right(unit);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }
}
