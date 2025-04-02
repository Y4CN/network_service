import 'package:network_service/src/errors/api_error.dart';

class NotFoundError extends ApiError {
  NotFoundError(String message) : super(message, 404);
}