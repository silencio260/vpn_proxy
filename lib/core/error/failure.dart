import 'package:equatable/equatable.dart';

import '../api/response_message.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure() : super(ResponseMessage.internalServerError);
}

class BadRequestFailure extends Failure {
  const BadRequestFailure() : super(ResponseMessage.badRequest);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure() : super(ResponseMessage.notFound);
}

class NoInternetConnectionFailure extends Failure {
  const NoInternetConnectionFailure() : super(ResponseMessage.noInternetConnection);
}

class ConnectTimeOutFailure extends Failure {
  const ConnectTimeOutFailure() : super(ResponseMessage.connectTimeOut);
}

class CancelRequestFailure extends Failure {
  const CancelRequestFailure() : super(ResponseMessage.cancel);
}

class TooManyRequestsFailure extends Failure {
  const TooManyRequestsFailure() : super(ResponseMessage.tooManyRequests);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure() : super(ResponseMessage.unexpected);
}
