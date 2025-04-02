import 'package:dio/dio.dart';
import 'http_request_type.dart';

abstract interface class NetworkService {
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
  });

  Future<dynamic> get(String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  });

  Future<dynamic> post(String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
  });

  Future<dynamic> put(String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  });

  Future<dynamic> patch(String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  });

  Future<dynamic> delete(String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  });

  Future<dynamic> multipart(String endpoint, {
    required List<MultipartFile> files,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
  });
}
