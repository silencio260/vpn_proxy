import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/ip_details_entity.dart';
import '../repositories/vpn_base_repo.dart';

class GetIpDetailsUseCase extends BaseUseCase<IpDetailsEntity, NoParams> {
  final VpnBaseRepo repo;

  GetIpDetailsUseCase({required this.repo});

  @override
  Future<Either<Failure, IpDetailsEntity>> call(NoParams params) =>
      repo.getIpDetails();
}
