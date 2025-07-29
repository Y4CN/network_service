import 'package:network_service/src/token.dart';

abstract class ITokenManager {
  Future<bool> isTokenStored();
  Future<void> saveToken(Token token);
  Future<void> clearStorage();
  Future<Token?> readToken();
}
