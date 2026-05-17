import 'dart:io';

import 'package:dio/dio.dart';

import '../api/response_code.dart';
import 'failure.dart';

class ErrorHandler {
  static Failure handle(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is SocketException) {
      return const NoInternetConnectionFailure();
    }
    return const UnexpectedFailure();
  }

  static Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ConnectTimeOutFailure();
      case DioExceptionType.cancel:
        return const CancelRequestFailure();
      case DioExceptionType.connectionError:
        return const NoInternetConnectionFailure();
      case DioExceptionType.badResponse:
        return _handleStatusCode(error.response?.statusCode);
      default:
        return const UnexpectedFailure();
    }
  }

  static Failure _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case ResponseCode.badRequest:
        return const BadRequestFailure();
      case ResponseCode.notFound:
        return const NotFoundFailure();
      case ResponseCode.tooManyRequests:
        return const TooManyRequestsFailure();
      case ResponseCode.internalServerError:
        return const ServerFailure();
      default:
        return const UnexpectedFailure();
    }
  }
}
