enum ApiErrorType {
  networkError('NETWORK_ERROR'),
  serverError('SERVER_ERROR'),
  unauthorized('UNAUTHORIZED'),
  forbidden('FORBIDDEN'),
  notFound('NOT_FOUND'),
  validationError('VALIDATION_ERROR'),
  timeoutError('TIMEOUT_ERROR'),
  cancelledError('CANCELLED_ERROR'),
  unknownError('UNKNOWN_ERROR');

  const ApiErrorType(this.value);
  final String value;

  static ApiErrorType fromStatusCode(int? statusCode) {
    switch (statusCode) {
      case 401:
        return ApiErrorType.unauthorized;
      case 403:
        return ApiErrorType.forbidden;
      case 404:
        return ApiErrorType.notFound;
      case 422:
        return ApiErrorType.validationError;
      case 500:
        return ApiErrorType.serverError;
      default:
        return ApiErrorType.unknownError;
    }
  }
}
