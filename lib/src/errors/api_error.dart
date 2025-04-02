
import 'app_errors.dart';

class ApiError extends AppError {
  final int? statusCode;
  ApiError(super.message, this.statusCode);
}