import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/base_usecase.dart';
import '../entities/vpn_server_entity.dart';
import '../repositories/vpn_base_repo.dart';

class SaveSelectedVpnUseCase extends BaseUseCase<Unit, VpnServerEntity> {
  final VpnBaseRepo repo;

  SaveSelectedVpnUseCase({required this.repo});

  @override
  Future<Either<Failure, Unit>> call(VpnServerEntity params) =>
      repo.saveSelectedVpn(params);
}
