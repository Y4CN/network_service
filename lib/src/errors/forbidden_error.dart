import 'package:network_service/src/errors/api_error.dart';

class ForbiddenError extends ApiError {
  ForbiddenError(String message) : super(message, 403);
}