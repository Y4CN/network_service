// lib/src/dio_network_manager.dart
import 'package:dio/dio.dart';
import 'package:network_service/src/errors/api_error_type.dart';
import 'package:network_service/src/http_request_type.dart';
import 'package:network_service/src/model/api_response.dart';
import 'package:network_service/src/network_service.dart';
import 'package:network_service/src/token_manager.dart';
import 'errors/error_handler.dart';

class DioNetworkManager implements NetworkService {
  final Dio _dio;
  final ITokenManager _tokenManager;
  final List<String> _publicEndpoints;
  final bool isDebugMode;

  DioNetworkManager({
    required ITokenManager tokenManager,
    required ErrorHandler errorHandler,
    required List<String> publicEndpoints,
    this.isDebugMode = true,
    Dio? dio,
    String baseUrl = 'https://api.example.com',
    int connectTimeout = 15000,
    int receiveTimeout = 15000,
  }) : _tokenManager = tokenManager,
       _publicEndpoints = publicEndpoints,
       _dio = dio ?? Dio() {
    _setupDio(baseUrl, connectTimeout, receiveTimeout);
    _setupInterceptors();
  }

  void _setupDio(String baseUrl, int connectTimeout, int receiveTimeout) {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = Duration(milliseconds: connectTimeout);
    _dio.options.receiveTimeout = Duration(milliseconds: receiveTimeout);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    if (isDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
        ),
      );
    }
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublicEndpoint(options.path)) {
      final token = await _tokenManager.readToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer ${token.accessToken}';
      }
    }
    handler.next(options);
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401 &&
        !_isPublicEndpoint(error.requestOptions.path)) {
      await _tokenManager.clearStorage();
    }
    handler.next(error);
  }

  bool _isPublicEndpoint(String path) {
    return _publicEndpoints.any((endpoint) => path.contains(endpoint));
  }

  ApiResponse<T> _handleSuccess<T>(Response response) {
    return ApiResponse.success(
      data: response.data,
      statusCode: response.statusCode,
      message: _getSuccessMessage(response.statusCode),
    );
  }

  String _getSuccessMessage(int? statusCode) {
    switch (statusCode) {
      case 200:
        return 'Request completed successfully';
      case 201:
        return 'Resource created successfully';
      case 202:
        return 'Request accepted';
      case 204:
        return 'Request completed successfully';
      default:
        return 'Operation successful';
    }
  }

  ApiResponse<T> _handleError<T>(dynamic error, String endpoint) {
    if (error is DioException) {
      final errorType = _getErrorType(error);
      final errorMessage = _getErrorMessage(error);
      final errorDetails = _getErrorDetails(error);

      return ApiResponse.error(
        message: errorMessage,
        statusCode: error.response?.statusCode,
        errorType: errorType.value,
        errorDetails: errorDetails,
      );
    }

    return ApiResponse.error(
      message: error.toString(),
      errorType: ApiErrorType.unknownError.value,
    );
  }

  ApiErrorType _getErrorType(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiErrorType.timeoutError;
      case DioExceptionType.cancel:
        return ApiErrorType.cancelledError;
      case DioExceptionType.badResponse:
        return ApiErrorType.fromStatusCode(error.response?.statusCode);
      case DioExceptionType.connectionError:
        return ApiErrorType.networkError;
      default:
        return ApiErrorType.unknownError;
    }
  }

  String _getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout occurred';
      case DioExceptionType.sendTimeout:
        return 'Send timeout occurred';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout occurred';
      case DioExceptionType.cancel:
        return 'Request was cancelled';
      case DioExceptionType.connectionError:
        return 'Connection error occurred';
      case DioExceptionType.badResponse:
        return _getResponseErrorMessage(error.response);
      default:
        return error.message ?? 'Unknown error occurred';
    }
  }

  String _getResponseErrorMessage(Response? response) {
    switch (response?.statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized access';
      case 403:
        return 'Access forbidden';
      case 404:
        return 'Resource not found';
      case 422:
        return 'Validation failed';
      case 429:
        return 'Too many requests';
      case 500:
        return 'Internal server error';
      case 502:
        return 'Bad gateway';
      case 503:
        return 'Service unavailable';
      default:
        return response?.data?['message'] ?? 'Server error occurred';
    }
  }

  Map<String, dynamic>? _getErrorDetails(DioException error) {
    final response = error.response;
    if (response?.data is Map<String, dynamic>) {
      return response!.data as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future<ApiResponse<T>> request<T>({
    required HttpRequestType type,
    required String endpoint,
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    List<MultipartFile>? files,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      Options options = Options(headers: headers);
      dynamic requestData = data;

      if (type == HttpRequestType.multipart && files != null) {
        requestData = _prepareFormData(data, files);
        options.contentType = 'multipart/form-data';
      }

      final response = await _performRequest(
        type: type,
        endpoint: endpoint,
        data: requestData,
        queryParams: queryParams,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return _handleSuccess<T>(response);
    } catch (error) {
      return _handleError<T>(error, endpoint);
    }
  }

  FormData _prepareFormData(dynamic data, List<MultipartFile> files) {
    final formData = FormData();

    if (data != null && data is Map<String, dynamic>) {
      data.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });
    }

    for (var file in files) {
      formData.files.add(MapEntry('files', file));
    }

    return formData;
  }

  Future<Response> _performRequest({
    required HttpRequestType type,
    required String endpoint,
    dynamic data,
    Map<String, dynamic>? queryParams,
    required Options options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    switch (type) {
      case HttpRequestType.get:
        return await _dio.get(
          endpoint,
          queryParameters: queryParams,
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
        );
      case HttpRequestType.post:
      case HttpRequestType.multipart:
        return await _dio.post(
          endpoint,
          data: data,
          queryParameters: queryParams,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
        );
      case HttpRequestType.put:
        return await _dio.put(
          endpoint,
          data: data,
          queryParameters: queryParams,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
        );
      case HttpRequestType.patch:
        return await _dio.patch(
          endpoint,
          data: data,
          queryParameters: queryParams,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
        );
      case HttpRequestType.delete:
        return await _dio.delete(
          endpoint,
          data: data,
          queryParameters: queryParams,
          options: options,
          cancelToken: cancelToken,
        );
    }
  }

  @override
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) => request<T>(
    type: HttpRequestType.get,
    endpoint: endpoint,
    queryParams: queryParams,
    headers: headers,
    cancelToken: cancelToken,
  );

  @override
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
  }) => request<T>(
    type: HttpRequestType.post,
    endpoint: endpoint,
    data: data,
    queryParams: queryParams,
    headers: headers,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
  );

  @override
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) => request<T>(
    type: HttpRequestType.put,
    endpoint: endpoint,
    data: data,
    queryParams: queryParams,
    headers: headers,
    cancelToken: cancelToken,
  );

  @override
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) => request<T>(
    type: HttpRequestType.patch,
    endpoint: endpoint,
    data: data,
    queryParams: queryParams,
    headers: headers,
    cancelToken: cancelToken,
  );

  @override
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) => request<T>(
    type: HttpRequestType.delete,
    endpoint: endpoint,
    queryParams: queryParams,
    headers: headers,
    cancelToken: cancelToken,
  );

  @override
  Future<ApiResponse<T>> multipart<T>(
    String endpoint, {
    required List<MultipartFile> files,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
  }) => request<T>(
    type: HttpRequestType.multipart,
    endpoint: endpoint,
    data: data,
    files: files,
    queryParams: queryParams,
    headers: headers,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
  );
}
