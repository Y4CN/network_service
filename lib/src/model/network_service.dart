import 'package:dio/dio.dart';
import 'package:network_service/src/model/api_response.dart';
import 'http_request_type.dart';

abstract interface class NetworkService {
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
  });

  Future<ApiResponse<T>> get<T>(String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  });

  Future<ApiResponse<T>> post<T>(String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
  });

  Future<ApiResponse<T>> put<T>(String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  });

  Future<ApiResponse<T>> patch<T>(String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  });

  Future<ApiResponse<T>> delete<T>(String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  });

  Future<ApiResponse<T>> multipart<T>(String endpoint, {
    required List<MultipartFile> files,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
  });
}
