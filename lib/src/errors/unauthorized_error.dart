import 'package:network_service/src/errors/api_error.dart';

class UnauthorizedError extends ApiError {
  UnauthorizedError(String message) : super(message, 401);
}