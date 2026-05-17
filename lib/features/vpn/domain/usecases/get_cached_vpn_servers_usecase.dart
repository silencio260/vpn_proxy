import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/vpn_server_entity.dart';
import '../repositories/vpn_base_repo.dart';

class GetCachedVpnServersUseCase
    extends BaseUseCase<List<VpnServerEntity>, NoParams> {
  final VpnBaseRepo repo;

  GetCachedVpnServersUseCase({required this.repo});

  @override
  Future<Either<Failure, List<VpnServerEntity>>> call(NoParams params) =>
      repo.getCachedVpnServers();
}
