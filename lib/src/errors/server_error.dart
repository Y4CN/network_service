import 'package:network_service/src/errors/api_error.dart';

class ServerError extends ApiError {
  ServerError(String message) : super(message, 500);
}
