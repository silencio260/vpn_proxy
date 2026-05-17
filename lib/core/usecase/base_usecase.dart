import 'package:dartz/dartz.dart';

import '../error/failure.dart';

abstract class BaseUseCase<Output, Input> {
  Future<Either<Failure, Output>> call(Input params);
}

class NoParams {
  static final NoParams instance = NoParams._();
  NoParams._();
}
