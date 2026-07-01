import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/proxy_entity.dart';
import '../repositories/proxy_base_repo.dart';

class GetProxiesUseCase extends BaseUseCase<List<ProxyEntity>, NoParams> {
  final ProxyBaseRepo repo;

  GetProxiesUseCase({required this.repo});

  @override
  Future<Either<Failure, List<ProxyEntity>>> call(NoParams params) =>
      repo.getProxies();
}
