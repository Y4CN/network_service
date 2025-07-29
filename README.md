# 🌐 Network Service Package

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Dio](https://img.shields.io/badge/Dio-FF6B6B?style=for-the-badge)
![GetIt](https://img.shields.io/badge/GetIt-4ECDC4?style=for-the-badge)

**یک پکیج قدرتمند و انعطاف‌پذیر برای مدیریت Network Requests در Flutter**

## 📑 فهرست مطالب

- [ویژگی‌ها](#-ویژگیها)
- [نصب](#-نصب)
- [شروع سریع](#-شروع-سریع)
- [Token Management](#-token-management)
- [HTTP Methods](#-http-methods)
- [File Upload](#-file-upload)
- [Error Handling](#-error-handling)
- [Dependency Injection](#-dependency-injection)
- [مثال‌های پیشرفته](#-مثالهای-پیشرفته)
- [نکات مهم](#-نکات-مهم)

## ✨ ویژگی‌ها

- 🔐 **مدیریت خودکار Token** - Authentication هوشمند
- 🚦 **Error Handling پیشرفته** - مدیریت جامع خطاها
- 🎯 **Dependency Injection** - استفاده از GetIt
- 📤 **Upload فایل** - پشتیبانی از Multipart
- ⚡ **Performance بالا** - Lazy Loading
- 🛡️ **Type Safe** - Abstract interfaces
- 📱 **Cross Platform** - iOS & Android

## 🔧 نصب

در فایل `pubspec.yaml` پکیج‌های زیر را اضافه کنید:

```yaml
dependencies:
  network_service: ^1.0.0
  dio: ^5.4.0
  get_it: ^7.6.4
  shared_preferences: ^2.2.2
```

سپس دستور زیر را اجرا کنید:

```bash
flutter pub get
```

## 🚀 شروع سریع

### مرحله 1: Token Manager پیاده‌سازی کنید

```dart
import 'package:network_service/network_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyTokenManager implements ITokenManager {
  final SharedPreferences _prefs;
  
  MyTokenManager(this._prefs);

  @override
  Future<bool> isTokenStored() async {
return _prefs.containsKey('access_token');
  }

  @override
  Future<void> saveToken(Token token) async {
await _prefs.setString('access_token', token.accessToken);
if (token.refreshToken != null) {
await _prefs.setString('refresh_token', token.refreshToken!);
}
  }

  @override
  Future<void> clearStorage() async {
await _prefs.remove('access_token');
await _prefs.remove('refresh_token');
  }

  @override
  Future<Token?> readToken() async {
final accessToken = _prefs.getString('access_token');
if (accessToken == null) return null;
    
return Token(
accessToken: accessToken,
refreshToken: _prefs.getString('refresh_token'),
);
  }
}
```

### مرحله 2: Network Module راه‌اندازی کنید

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:network_service/network_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // SharedPreferences راه‌اندازی
  final prefs = await SharedPreferences.getInstance();
  final tokenManager = MyTokenManager(prefs);
  
  // Network Module راه‌اندازی
  await setupNetworkModule(
tokenManager: tokenManager,
publicEndpoints: ['/login', '/register', '/forgot-password'],
  );
  
  runApp(MyApp());
}
```

### مرحله 3: استفاده در Service Layer

```dart
import 'package:network_service/network_service.dart';

class UserService {
  final NetworkService _networkService = getIt<NetworkService>();

  Future<Map<String, dynamic>> getProfile() async {
try {
final response = await _networkService.get('/user/profile');
return response.data;
} catch (e) {
throw Exception('خطا در دریافت پروفایل: $e');
}
  }

  Future<void> updateProfile(Map<String, dynamic> userData) async {
await _networkService.put('/user/profile', data: userData);
  }

  Future<List<dynamic>> searchUsers(String query) async {
final response = await _networkService.get(
'/users/search',
queryParams: {'q': query, 'limit': 20},
);
return response.data;
  }
}
```

## 🔐 Token Management

### مدیریت خودکار Authentication

```dart
class AuthService {
  final NetworkService _networkService = getIt<NetworkService>();
  final ITokenManager _tokenManager = getIt<ITokenManager>();

  Future<void> login(String email, String password) async {
final response = await _networkService.post('/auth/login', data: {
'email': email,
'password': password,
});

final token = Token(
accessToken: response.data['access_token'],
refreshToken: response.data['refresh_token'],
expiresAt: DateTime.now().add(Duration(hours: 24)),
);

await _tokenManager.saveToken(token);
  }

  Future<void> logout() async {
await _networkService.post('/auth/logout');
await _tokenManager.clearStorage();
  }

  Future<bool> isLoggedIn() async {
return await _tokenManager.isTokenStored();
  }
}
```

### Token امن با Secure Storage

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenManager implements ITokenManager {
  static const String _tokenKey = 'secure_token';
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  
  @override
  Future<void> saveToken(Token token) async {
final tokenJson = jsonEncode(token.toJson());
await _storage.write(key: _tokenKey, value: tokenJson);
  }

  @override
  Future<Token?> readToken() async {
final tokenJson = await _storage.read(key: _tokenKey);
if (tokenJson == null) return null;
    
final tokenMap = jsonDecode(tokenJson);
return Token.fromJson(tokenMap);
  }

  @override
  Future<bool> isTokenStored() async {
final token = await readToken();
return token != null;
  }

  @override
  Future<void> clearStorage() async {
await _storage.delete(key: _tokenKey);
  }
}
```

## 🌐 HTTP Methods

### GET Request

```dart
// درخواست ساده
final users = await _networkService.get('/users');

// با Query Parameters
final filteredUsers = await _networkService.get('/users', queryParams: {
  'page': 1,
  'limit': 10,
  'status': 'active',
});

// با Custom Headers
final response = await _networkService.get('/protected-endpoint', headers: {
  'X-API-Version': '2.0',
  'Accept-Language': 'fa-IR',
});
```

### POST Request

```dart
// ایجاد کاربر جدید
final newUser = await _networkService.post('/users', data: {
  'name': 'علی احمدی',
  'email': 'ali@example.com',
  'phone': '09123456789',
});

// با Progress Tracking
await _networkService.post('/upload-data', 
  data: largeData,
  onSendProgress: (sent, total) {
print('آپلود: ${(sent / total * 100).toStringAsFixed(1)}%');
  },
);
```

### PUT و PATCH

```dart
// بروزرسانی کامل
await _networkService.put('/users/123', data: updatedUserData);

// بروزرسانی جزئی
await _networkService.patch('/users/123', data: {'status': 'inactive'});
```

### DELETE

```dart
await _networkService.delete('/users/123');

// با تایید
await _networkService.delete('/users/123', queryParams: {
  'confirm': 'true',
  'reason': 'اکانت غیرفعال شده',
});
```

## 📤 File Upload

### آپلود تک فایل

```dart
import 'package:dio/dio.dart';
import 'dart:io';

Future<void> uploadProfilePicture(File imageFile) async {
  final multipartFile = await MultipartFile.fromFile(
imageFile.path,
filename: 'profile.jpg',
  );

  await _networkService.multipart('/user/avatar', 
files: [multipartFile],
onSendProgress: (sent, total) {
final progress = (sent / total * 100).toStringAsFixed(1);
print('آپلود تصویر: $progress%');
},
  );
}
```

### آپلود چند فایل

```dart
Future<void> uploadDocuments(List<File> documents) async {
  final multipartFiles = <MultipartFile>[];
  
  for (int i = 0; i < documents.length; i++) {
final file = await MultipartFile.fromFile(
documents[i].path,
filename: 'document_$i.pdf',
);
multipartFiles.add(file);
  }

  await _networkService.multipart('/documents/upload',
files: multipartFiles,
data: {
'category': 'official',
'description': 'مدارک رسمی کاربر',
},
  );
}
```

## 🚦 Error Handling

### Custom Error Handler

```dart
import 'package:network_service/network_service.dart';

class MyErrorHandler implements ErrorHandler {
  @override
  void handleError(Object error, StackTrace stackTrace) {
if (error is NetworkError) {
switch (error.statusCode) {
case 401:
_handleUnauthorized();
break;
case 403:
_showAccessDeniedDialog();
break;
case 404:
_showNotFoundMessage();
break;
case 500:
_showServerErrorDialog();
break;
default:
_showGenericError(error.message);
}
}
  }

  void _handleUnauthorized() {
// پاک کردن توکن و انتقال به صفحه لاگین
getIt<ITokenManager>().clearStorage();
// Navigator.pushReplacementNamed(context, '/login');
  }

  void _showAccessDeniedDialog() {
print('دسترسی مجاز نیست');
  }

  void _showNotFoundMessage() {
print('صفحه مورد نظر یافت نشد');
  }

  void _showServerErrorDialog() {
print('خطای سرور');
  }

  void _showGenericError(String message) {
print('خطا: $message');
  }
}
```

### استفاده از Error Handler

```dart
await setupNetworkModule(
  tokenManager: tokenManager,
  errorHandler: MyErrorHandler(), // Custom Error Handler
  publicEndpoints: ['/login', '/register'],
);
```

## 🎯 Dependency Injection

### تنظیمات پیشرفته

```dart
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:network_service/network_service.dart';

Future<void> setupDI() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Token Manager
  getIt.registerLazySingleton<ITokenManager>(
() => SecureTokenManager(),
  );

  // Custom Error Handler
  getIt.registerLazySingleton<ErrorHandler>(
() => MyErrorHandler(),
  );

  // Network Module
  await setupNetworkModule(
tokenManager: getIt<ITokenManager>(),
publicEndpoints: [
'/auth/login',
'/auth/register',
'/auth/forgot-password',
'/public/config',
],
  );

  // Services
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<UserService>(() => UserService());
}
```

### استفاده در Widget

```dart
class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = getIt<UserService>();
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
super.initState();
_loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
try {
final user = await _userService.getProfile();
setState(() {
_user = user;
_loading = false;
});
} catch (e) {
setState(() => _loading = false);
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('خطا در بارگذاری پروفایل')),
);
}
  }

  @override
  Widget build(BuildContext context) {
if (_loading) {
return Scaffold(
body: Center(child: CircularProgressIndicator()),
);
}

return Scaffold(
appBar: AppBar(title: Text('پروفایل کاربری')),
body: _user != null 
? Column(
children: [
Text('نام: ${_user!['name']}'),
Text('ایمیل: ${_user!['email']}'),
],
)
: Center(child: Text('پروفایل یافت نشد')),
);
  }
}
```

## 💡 مثال‌های پیشرفته

### Retry Mechanism

```dart
class RetryableNetworkService {
  final NetworkService _networkService = getIt<NetworkService>();
  
  Future<T> withRetry<T>(
Future<T> Function() operation, {
int maxRetries = 3,
Duration delay = const Duration(seconds: 2),
  }) async {
int attempts = 0;
    
while (attempts < maxRetries) {
try {
return await operation();
} catch (e) {
attempts++;
if (attempts >= maxRetries) rethrow;
        
print('تلاش $attempts ناموفق، تلاش مجدد در ${delay.inSeconds} ثانیه...');
await Future.delayed(delay);
}
}
    
throw Exception('عملیات پس از $maxRetries تلاش ناموفق ماند');
  }
}

// استفاده
final retryService = RetryableNetworkService();
final data = await retryService.withRetry(() => 
  _networkService.get('/unstable-endpoint')
);
```

### Progress Tracking

```dart
class ProgressTracker {
  final ValueNotifier<double> uploadProgress = ValueNotifier(0.0);
  final ValueNotifier<double> downloadProgress = ValueNotifier(0.0);
  final NetworkService _networkService = getIt<NetworkService>();

  Future<void> uploadWithProgress(String endpoint, dynamic data) async {
await _networkService.post(
endpoint,
data: data,
onSendProgress: (sent, total) {
uploadProgress.value = sent / total;
},
);
  }
}

// در Widget
ValueListenableBuilder<double>(
  valueListenable: progressTracker.uploadProgress,
  builder: (context, progress, child) {
return LinearProgressIndicator(value: progress);
  },
)
```

### Cancel Token

```dart
import 'package:dio/dio.dart';

class CancellableRequest {
  CancelToken? _cancelToken;

  Future<dynamic> getData() async {
_cancelToken = CancelToken();
    
try {
return await getIt<NetworkService>().get(
'/long-running-request',
cancelToken: _cancelToken,
);
} catch (e) {
if (CancelToken.isCancel(e)) {
print('درخواست لغو شد');
}
rethrow;
}
  }

  void cancelRequest() {
_cancelToken?.cancel('درخواست توسط کاربر لغو شد');
  }
}
```

## 🚨 نکات مهم

### ✅ بهترین روش‌ها

**Dependency Injection:**
```dart
// ✅ درست - Lazy Singleton
getIt.registerLazySingleton<UserService>(() => UserService());

// ❌ اشتباه - Register Singleton برای همه چیز
getIt.registerSingleton<UserService>(UserService());
```

**Token Storage:**
```dart
// ✅ درست - Secure Storage
await FlutterSecureStorage().write(key: 'token', value: token);

// ❌ اشتباه - SharedPreferences برای Token
prefs.setString('token', token);
```

**Error Handling:**
```dart
// ✅ درست - Try-Catch با مدیریت خطا
try {
  final result = await _networkService.get('/endpoint');
  return result;
} catch (e) {
  // مدیریت خطا
  throw CustomException('خطا در دریافت داده');
}

// ❌ اشتباه - بدون مدیریت خطا
final result = await _networkService.get('/endpoint');
return result;
```

### ⚠️ اشتباهات رایج

1. **عدم استفاده از Cancel Token** برای درخواست‌های طولانی
2. **ذخیره Token به صورت ناامن** در SharedPreferences
3. **عدم مدیریت Loading State** در UI
4. **استفاده از registerSingleton** بجای registerLazySingleton
5. **عدم مدیریت خطاهای Network**

### 📋 Checklist پیش از Production

- [ ] Token در Secure Storage ذخیره می‌شود
- [ ] Error Handler مناسب پیاده‌سازی شده
- [ ] Loading States مدیریت می‌شوند
- [ ] Cancel Token برای درخواست‌های طولانی استفاده شده
- [ ] Public Endpoints به درستی مشخص شده‌اند
- [ ] Base URL برای Production تنظیم شده
- [ ] Timeout مناسب تنظیم شده
- [ ] Retry Mechanism برای درخواست‌های مهم

## 🧪 Testing

```dart
import 'package:mockito/mockito.dart';
import 'package:network_service/network_service.dart';

class MockNetworkService extends Mock implements NetworkService {}

void main() {
  late MockNetworkService mockNetworkService;
  late UserService userService;

  setUp(() {
mockNetworkService = MockNetworkService();
GetIt.instance.registerSingleton<NetworkService>(mockNetworkService);
userService = UserService();
  });

  test('should return user profile', () async {
// Arrange
when(mockNetworkService.get('/user/profile'))
.thenAnswer((_) async => {'data': {'id': 1, 'name': 'Test User'}});

// Act
final result = await userService.getProfile();

// Assert
expect(result['data']['name'], 'Test User');
verify(mockNetworkService.get('/user/profile')).called(1);
  });
}
```

## 📄 مجوز

این پروژه تحت مجوز MIT منتشر شده است.

---

**ساخته شده با ❤️ برای جامعه Flutter**

اگر این پکیج برای شما مفید بود، لطفاً ⭐ ستاره دهید!