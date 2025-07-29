class ApiResponse<T> {
  final T? data;
  final bool success;
  final String? message;
  final int? statusCode;
  final String? errorType;
  final Map<String, dynamic>? errorDetails;

  const ApiResponse._({
    this.data,
    required this.success,
    this.message,
    this.statusCode,
    this.errorType,
    this.errorDetails,
  });

  factory ApiResponse.success({
    T? data,
    String? message,
    int? statusCode = 200,
  }) {
    return ApiResponse._(
      data: data,
      success: true,
      message: message ?? 'success',
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error({
    String? message,
    int? statusCode,
    String? errorType,
    Map<String, dynamic>? errorDetails,
  }) {
    return ApiResponse._(
      success: false,
      message: message ?? 'Unknown Error',
      statusCode: statusCode,
      errorType: errorType,
      errorDetails: errorDetails,
    );
  }

  bool get isSuccess => success;
  bool get isError => !success;

  String get errorMessage => message ?? 'Unknown Error';

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, statusCode: $statusCode)';
  }
}
