import 'package:dartz/dartz.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/proxy_entity.dart';
import '../../domain/repositories/proxy_base_repo.dart';
import '../datasources/local/proxy_local_data_source.dart';
import '../datasources/remote/proxy_remote_data_source.dart';
import '../mappers.dart';
import '../models/proxy_model.dart';

class ProxyRepo implements ProxyBaseRepo {
  final ProxyRemoteDataSource remoteDataSource;
  final ProxyLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ProxyRepo({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ProxyEntity>>> getProxies() async {
    if (!await networkInfo.isConnected) {
      return Left(NoInternetConnectionFailure());
    }
    try {
      final snapshot = await remoteDataSource.getProxySnapshot();
      final merged = _merge(snapshot);
      await localDataSource.cacheProxies(merged);
      return Right(merged.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<Failure, List<ProxyEntity>>> getCachedProxies() async {
    try {
      final proxies = await localDataSource.getCachedProxies();
      return Right(proxies.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  List<ProxyModel> _merge(ProxySnapshot snapshot) {
    return snapshot.proxies
        .where((p) => snapshot.enabled[p.id] != false)
        .map(
          (p) => p.copyWith(
            health: snapshot.health[p.id],
            deep: snapshot.deep[p.id],
          ),
        )
        .toList();
  }
}
