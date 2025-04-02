import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:network_service/src/dio_network_manager.dart';
import 'package:network_service/src/errors/errors.dart';
import 'package:network_service/src/token.dart';
import 'package:network_service/src/token_manager.dart';

import 'dio_network_manager_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<Dio>(),
  MockSpec<ITokenManager>(),
  MockSpec<ErrorHandler>(),
])
void main() {
  late MockDio mockDio;
  late MockITokenManager mockTokenManager;
  late MockErrorHandler mockErrorHandler;
  late DioNetworkManager networkManager;

  final List<String> publicEndpoints = ['/auth/login', '/auth/register'];
  final dummyToken = Token(
    accessToken: 'dummy_access_token',
    refreshToken: 'dummy_refresh_token',
    expirationTime: 3600,
  );

  setUp(() {
    mockDio = MockDio();
    mockTokenManager = MockITokenManager();
    mockErrorHandler = MockErrorHandler();

    final baseOptions = BaseOptions();
    when(mockDio.options).thenReturn(baseOptions);
    when(mockDio.interceptors).thenReturn(Interceptors());

    networkManager = DioNetworkManager(
      tokenManager: mockTokenManager,
      errorHandler: mockErrorHandler,
      publicEndpoints: publicEndpoints,
      dio: mockDio,
      isDebugMode: false,
    );
  });

  group('Initialization Test', () {
    test('should configure Dio correctly', () {
      final newMockDio = MockDio();
      final options = BaseOptions();

      when(newMockDio.options).thenReturn(options);
      when(newMockDio.interceptors).thenReturn(Interceptors());

      DioNetworkManager(
        tokenManager: mockTokenManager,
        errorHandler: mockErrorHandler,
        publicEndpoints: publicEndpoints,
        dio: newMockDio,
        baseUrl: 'https://api.test.com',
        connectTimeout: 15000,
        receiveTimeout: 15000,
      );

      expect(options.baseUrl, 'https://api.test.com');
      expect(options.connectTimeout, Duration(milliseconds: 15000));
      expect(options.receiveTimeout, Duration(milliseconds: 15000));
      expect(
        options.headers,
        containsPair('Content-Type', 'application/json'),
      );
    });
  });

  group('GET Method Test', () {
    test('should return response data for GET', () async {
      final endpoint = '/users';
      final queryParams = {'page': 1};
      final responseData = {'data': 'value'};

      when(mockTokenManager.readToken()).thenAnswer((_) async => dummyToken);
      when(mockDio.get(
        any,
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenAnswer(
            (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: endpoint),
        ),
      );

      final result = await networkManager.get(endpoint, queryParams: queryParams);

      expect(result, responseData);
    });
  });


  group('POST Method Test', () {
    test('should return response data for POST', () async {
      final endpoint = '/users';
      final data = {'name': 'Test'};
      final responseData = {'id': 1};

      when(mockTokenManager.readToken()).thenAnswer((_) async => dummyToken);
      when(mockDio.post(
        any,
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
        onSendProgress: anyNamed('onSendProgress'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenAnswer(
            (_) async => Response(
          data: responseData,
          statusCode: 201,
          requestOptions: RequestOptions(path: endpoint),
        ),
      );

      final result = await networkManager.post(endpoint, data: data);

      expect(result, responseData);
    });
  });

  group('Error Handling Test', () {
    test('should propagate handled error', () async {
      final endpoint = '/error';
      final dioError = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: endpoint),
        response: Response(statusCode: 404, requestOptions: RequestOptions(path: endpoint)),
      );
      final handledError = Exception('Handled Error');

      when(mockTokenManager.readToken()).thenAnswer((_) async => dummyToken);
      when(mockDio.get(
        any,
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenThrow(dioError);

      when(mockErrorHandler.handleError(dioError, endpoint: endpoint)).thenReturn(handledError);

      expect(() => networkManager.get(endpoint), throwsA(handledError));
    });
  });
}
