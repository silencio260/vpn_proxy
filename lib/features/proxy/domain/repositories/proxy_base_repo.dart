import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/proxy_entity.dart';

abstract class ProxyBaseRepo {
  Future<Either<Failure, List<ProxyEntity>>> getProxies();
  Future<Either<Failure, List<ProxyEntity>>> getCachedProxies();
}
