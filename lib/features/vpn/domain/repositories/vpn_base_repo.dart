import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/ip_details_entity.dart';
import '../entities/vpn_server_entity.dart';

abstract class VpnBaseRepo {
  Future<Either<Failure, List<VpnServerEntity>>> getVpnServers();
  Future<Either<Failure, IpDetailsEntity>> getIpDetails();
  Future<Either<Failure, List<VpnServerEntity>>> getCachedVpnServers();
  Future<Either<Failure, VpnServerEntity>> getCachedSelectedVpn();
  Future<Either<Failure, Unit>> saveSelectedVpn(VpnServerEntity server);
}
