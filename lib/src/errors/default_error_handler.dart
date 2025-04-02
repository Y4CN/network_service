

import 'dart:io';

import 'package:dio/dio.dart';

import 'errors.dart';

class DefaultErrorHandler implements ErrorHandler {
  @override
  dynamic handleError(dynamic error, {String? endpoint}) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return NetworkError('اتصال به شبکه برقرار نشد.');

        case DioExceptionType.badResponse:
          final int? statusCode = error.response?.statusCode;
          if (statusCode == 401) return UnauthorizedError('ورود دوباره لازم است.');
          if (statusCode == 403) return ForbiddenError('دسترسی غیرمجاز.');
          if (statusCode == 404) return NotFoundError('آدرس یافت نشد: $endpoint');
          if (statusCode != null && statusCode >= 500) return ServerError('مشکل سرور.');

          final data = error.response?.data;
          String message = 'خطا رخ داده است';
          if (data is Map && data.containsKey('message')) {
            message = data['message'];
          }
          return ApiError(message, statusCode);

        case DioExceptionType.cancel:
          return RequestCancelledError('درخواست لغو شد.');

        default:
          return NetworkError('خطای نامشخص در اتصال شبکه.');
      }
    } else if (error is SocketException) {
      return NetworkError('خطای اتصال اینترنت');
    }
    return GenericError('خطای ناشناخته: ${error.toString()}');
  }
}