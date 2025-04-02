
# Flutter Network Service Module

A powerful, flexible, and production-ready network service implementation for Flutter applications built on top of the Dio HTTP client. This module provides a complete solution for handling API requests with support for authentication, error handling, request cancellation, and file uploads.

## Features

-   🔄 Complete HTTP methods (GET, POST, PUT, PATCH, DELETE, Multipart)
-   🔑 Built-in token authentication management
-   🚫 Customizable error handling with localized error messages
-   🔍 Debug logging with request/response details
-   📊 Progress tracking for uploads and downloads
-   🛑 Request cancellation support
-   📁 File upload with multipart support
-   🌐 Public endpoints configuration
-   💉 Easy dependency injection with GetIt

## Getting Started

### Setup

Initialize the network module in your application's startup:
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Define your public endpoints that don't require authentication
  final publicEndpoints = ['/auth/login', '/auth/register', '/public/data'];
  
  // Initialize the network module
  await setupNetworkModule(
    tokenManager: YourTokenManagerImplementation(),
    publicEndpoints: publicEndpoints,
  );
  
  runApp(MyApp());
}
```
### Making API Requests

After setting up the module, you can make API requests from anywhere in your application:
```dart
import 'package:get_it/get_it.dart';
import 'package:network_service/network_service.dart';

final networkService = GetIt.instance<NetworkService>();

// Example function to fetch user profile
Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
  try {
    final response = await networkService.get(
      '/users/$userId',
      queryParams: {'include': 'details,preferences'},
    );
    return response;
  } catch (e) {
    // Handle error based on error type
    if (e is UnauthorizedError) {
      // Redirect to login
    } else if (e is NetworkError) {
      // Show network error message
    }
    rethrow;
  }
}
```
## Implementation Guide

### Token Management

Implement your own token storage strategy by creating a class that implements `ITokenManager`:
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:network_service/src/token_manager.dart';
import 'dart:convert';

class SecureStorageTokenManager implements ITokenManager {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  
  @override
  Future<bool> isTokenStored() async {
    final tokenStr = await _storage.read(key: _tokenKey);
    return tokenStr != null;
  }
  
  @override
  Future<void> saveToken(Token token) async {
    await _storage.write(
      key: _tokenKey,
      value: jsonEncode(token.toJson()),
    );
  }
  
  @override
  Future<void> clearStorage() async {
    await _storage.delete(key: _tokenKey);
  }
  
  @override
  Future<Token?> readToken() async {
    try {
      final tokenStr = await _storage.read(key: _tokenKey);
      if (tokenStr == null) return null;
      
      final tokenMap = jsonDecode(tokenStr) as Map<String, dynamic>;
      return Token.fromJson(tokenMap);
    } catch (e) {
      await clearStorage();
      return null;
    }
  }
}
```
### Custom Error Handling

The module includes a default error handler with common error types, but you can customize it to fit your application needs:
```dart
class MyAppErrorHandler implements ErrorHandler {
  @override
  dynamic handleError(dynamic error, {String? endpoint}) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return NetworkError('Connection timeout. Please check your internet.');
          
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          
          // Handle specific API errors based on your backend
          if (statusCode == 400) {
            final data = error.response?.data;
            if (data is Map && data.containsKey('validationErrors')) {
              return ValidationError(
                'Please check your input',
                data['validationErrors'],
              );
            }
          }
          
          // Default error handling from base implementation
          return super.handleError(error, endpoint: endpoint);
          
        // Other cases...
      }
    }
    
    return GenericError('Unknown error occurred: ${error.toString()}');
  }
}

// Register your custom error handler
void setupCustomErrorHandler() {
  GetIt.instance.registerSingleton<ErrorHandler>(MyAppErrorHandler());
}
```
## Usage Examples

### Basic CRUD Operations
```dart
// Create (POST)
Future<void> createPost(String title, String content) async {
  await networkService.post(
    '/posts',
    data: {
      'title': title,
      'content': content,
      'published': true,
    },
  );
}

// Read (GET)
Future<List<dynamic>> getPosts() async {
  return await networkService.get('/posts');
}

// Read single (GET)
Future<Map<String, dynamic>> getPost(String id) async {
  return await networkService.get('/posts/$id');
}

// Update (PUT)
Future<void> updatePost(String id, String title, String content) async {
  await networkService.put(
    '/posts/$id',
    data: {
      'title': title,
      'content': content,
    },
  );
}

// Delete (DELETE)
Future<void> deletePost(String id) async {
  await networkService.delete('/posts/$id');
}
```
### File Upload with Progress Tracking
```dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:network_service/network_service.dart';

Future<void> uploadProfileImage(File imageFile, Function(double) onProgress) async {
  try {
    // Create a multipart file
    final fileName = imageFile.path.split('/').last;
    final multipartFile = await MultipartFile.fromFile(
      imageFile.path,
      filename: fileName,
    );
    
    // Upload with progress tracking
    await networkService.multipart(
      '/users/profile-image',
      files: [multipartFile],
      data: {'type': 'profile'},
      onSendProgress: (sent, total) {
        final progress = sent / total;
        onProgress(progress);
      },
    );
  } catch (e) {
    // Handle specific upload errors
    if (e is NetworkError) {
      print('Network error during upload: ${e.message}');
    } else if (e is ServerError) {
      print('Server error during upload: ${e.message}');
    } else {
      print('Error during upload: $e');
    }
    rethrow;
  }
}
```
### Handling Request Cancellation
```dart
import 'package:dio/dio.dart';

class SearchService {
  CancelToken? _cancelToken;
  
  // Cancel any ongoing search request
  void cancelSearch() {
    _cancelToken?.cancel('User cancelled the search');
    _cancelToken = null;
  }
  
  Future<List<dynamic>> search(String query) async {
    // Cancel previous search if any
    cancelSearch();
    
    // Create new cancel token
    _cancelToken = CancelToken();
    
    try {
      final results = await networkService.get(
        '/search',
        queryParams: {'q': query, 'limit': 20},
        cancelToken: _cancelToken,
      );
      return results['items'];
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        // Request was cancelled, just ignore
        return [];
      }
      rethrow;
    }
  }
  
  void dispose() {
    cancelSearch();
  }
}
```
### Implementing Authentication Flow
```dart
class AuthService {
  final NetworkService _networkService;
  final ITokenManager _tokenManager;
  
  AuthService({
    required NetworkService networkService,
    required ITokenManager tokenManager,
  }) : _networkService = networkService,
       _tokenManager = tokenManager;
  
  Future<bool> login(String username, String password) async {
    try {
      final response = await _networkService.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      
      // Save the authentication token
      final token = Token(
        accessToken: response['accessToken'],
        refreshToken: response['refreshToken'],
        expirationTime: response['expiresIn'],
      );
      
      await _tokenManager.saveToken(token);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> logout() async {
    try {
      // Call logout endpoint
      await _networkService.post('/auth/logout');
    } catch (e) {
      // Ignore errors during logout
    } finally {
      // Always clear token storage on logout
      await _tokenManager.clearStorage();
    }
  }
  
  Future<bool> isLoggedIn() async {
    return await _tokenManager.isTokenStored();
  }
}
```
## Error Handling Structure

The module provides a comprehensive error handling system with specific error types:

-   `NetworkError`: For connection and timeout issues
-   `ApiError`: Generic API errors with status code
-   `UnauthorizedError`: Authentication failures (401)
-   `ForbiddenError`: Permission issues (403)
-   `NotFoundError`: Resource not found (404)
-   `ServerError`: Server-side errors (5xx)
-   `ValidationError`: Input validation failures
-   `RequestCancelledError`: When a request is cancelled
-   `GenericError`: For unclassified errors

Example of handling different error types:
```dart
try {
  final result = await networkService.get('/protected-resource');
  // Process successful result
} catch (e) {
  if (e is UnauthorizedError) {
    // Navigate to login screen
    navigator.pushNamed('/login');
  } else if (e is NetworkError) {
    // Show network error UI
    showDialog(
      context: context,
      builder: (context) => NetworkErrorDialog(message: e.message),
    );
  } else if (e is ServerError) {
    // Show server error UI
    showDialog(
      context: context,
      builder: (context) => ServerErrorDialog(message: e.message),
    );
  } else {
    // Generic error handling
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred: ${e.toString()}')),
    );
  }
}
```
## Advanced Configuration

### Customizing Dio Instance

You can provide a pre-configured Dio instance to the network manager:
```dart
Dio createCustomDio() {
  final dio = Dio();
  
  // Add a custom interceptor
  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) {
        // Add device info to all requests
        options.headers['X-Device-ID'] = deviceId;
        options.headers['X-App-Version'] = appVersion;
        return handler.next(options);
      },
    ),
  );
  
  // Configure cache
  dio.interceptors.add(DioCacheInterceptor(
    options: CacheOptions(
      store: MemCacheStore(),
      policy: CachePolicy.request,
      hitCacheOnErrorExcept: [401, 403],
      maxStale: const Duration(days: 1),
    ),
  ));
  
  return dio;
}

// Use custom Dio in setup
await setupNetworkModule(
  tokenManager: YourTokenManagerImplementation(),
  publicEndpoints: publicEndpoints,
  dio: createCustomDio(),
  baseUrl: 'https://api.yourservice.com/v2',
);
```
### Best Practices

1.  **Repository Pattern**: Wrap the network service inside repositories for each domain model:
```dart
class UserRepository {
  final NetworkService _networkService;
  
  UserRepository(this._networkService);
  
  Future<User> getUserById(String id) async {
    final data = await _networkService.get('/users/$id');
    return User.fromJson(data);
  }
  
  Future<List<User>> searchUsers(String query) async {
    final List data = await _networkService.get(
      '/users/search',
      queryParams: {'q': query},
    );
    return data.map((json) => User.fromJson(json)).toList();
  }
  
  Future<void> updateUserProfile(String id, UserProfileDto dto) async {
    await _networkService.put('/users/$id', data: dto.toJson());
  }
}
```
2. **Error Mapping**: Consider mapping API errors to user-friendly messages in your UI layer:
```dart
String mapErrorToUserMessage(dynamic error) {
  if (error is NetworkError) {
    return 'Please check your internet connection and try again.';
  } else if (error is UnauthorizedError) {
    return 'Your session has expired. Please log in again.';
  } else if (error is ValidationError) {
    return 'Please check your input data: ${error.validationMessages.join(', ')}';
  } else if (error is ServerError) {
    return 'Our servers are having issues. Please try again later.';
  }
  return 'An unexpected error occurred. Please try again.';
}
```
