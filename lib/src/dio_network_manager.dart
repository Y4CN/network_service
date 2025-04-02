import 'package:dio/dio.dart';
import 'package:network_service/src/http_request_type.dart';
import 'package:network_service/src/network_service.dart';
import 'package:network_service/src/token_manager.dart';

import 'errors/error_handler.dart';

class DioNetworkManager implements NetworkService {
  final Dio _dio;
  final ITokenManager _tokenManager;
  final ErrorHandler _errorHandler;
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
       _errorHandler = errorHandler,
       _publicEndpoints = publicEndpoints,
       _dio = dio ?? Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = Duration(milliseconds: connectTimeout);
    _dio.options.receiveTimeout = Duration(milliseconds: receiveTimeout);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async{
          if (!_isPublicEndpoint(options.path)) {
            final token = await _tokenManager.readToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer ${token.accessToken}';
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) => handler.next(response),
        onError: (error, handler) async{
          if (error.response?.statusCode == 401 &&
              !_isPublicEndpoint(error.requestOptions.path)) {
           await _tokenManager.clearStorage();
          }
          return handler.next(error);
        },
      ),
    );

    if (isDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  bool _isPublicEndpoint(String path) {
    return _publicEndpoints.any((endpoint) => path.contains(endpoint));
  }

  @override
  Future<dynamic> request({
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
        final formData = FormData();
        if (data != null && data is Map<String, dynamic>) {
          data.forEach((key, value) {
            formData.fields.add(MapEntry(key, value.toString()));
          });
        }
        for (var file in files) {
          formData.files.add(MapEntry('files', file));
        }
        requestData = formData;
        options.contentType = 'multipart/form-data';
      }

      late Response response;

      switch (type) {
        case HttpRequestType.get:
          response = await _dio.get(
            endpoint,
            queryParameters: queryParams,
            options: options,
            cancelToken: cancelToken,
            onReceiveProgress: onReceiveProgress,
          );
          break;
        case HttpRequestType.post:
          response = await _dio.post(
            endpoint,
            data: requestData,
            queryParameters: queryParams,
            options: options,
            cancelToken: cancelToken,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          );
          break;
        case HttpRequestType.put:
          response = await _dio.put(
            endpoint,
            data: requestData,
            queryParameters: queryParams,
            options: options,
            cancelToken: cancelToken,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          );
          break;
        case HttpRequestType.patch:
          response = await _dio.patch(
            endpoint,
            data: requestData,
            queryParameters: queryParams,
            options: options,
            cancelToken: cancelToken,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          );
          break;
        case HttpRequestType.delete:
          response = await _dio.delete(
            endpoint,
            data: requestData,
            queryParameters: queryParams,
            options: options,
            cancelToken: cancelToken,
          );
          break;
        case HttpRequestType.multipart:
          if (requestData is! FormData) {
            throw Exception(
              'برای ارسال فایل multipart باید از FormData استفاده شود',
            );
          }
          response = await _dio.post(
            endpoint,
            data: requestData,
            queryParameters: queryParams,
            options: options,
            cancelToken: cancelToken,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          );
          break;
      }

      return response.data;
    } catch (error) {
      throw _errorHandler.handleError(error, endpoint: endpoint);
    }
  }

  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) => request(
    type: HttpRequestType.get,
    endpoint: endpoint,
    queryParams: queryParams,
    headers: headers,
    cancelToken: cancelToken,
  );

  @override
  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
  }) => request(
    type: HttpRequestType.post,
    endpoint: endpoint,
    data: data,
    queryParams: queryParams,
    headers: headers,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
  );

  @override
  Future<dynamic> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) => request(
    type: HttpRequestType.put,
    endpoint: endpoint,
    data: data,
    queryParams: queryParams,
    headers: headers,
    cancelToken: cancelToken,
  );

  @override
  Future<dynamic> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) => request(
    type: HttpRequestType.patch,
    endpoint: endpoint,
    data: data,
    queryParams: queryParams,
    headers: headers,
    cancelToken: cancelToken,
  );

  @override
  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) => request(
    type: HttpRequestType.delete,
    endpoint: endpoint,
    queryParams: queryParams,
    headers: headers,
    cancelToken: cancelToken,
  );

  @override
  Future<dynamic> multipart(
    String endpoint, {
    required List<MultipartFile> files,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
  }) => request(
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
