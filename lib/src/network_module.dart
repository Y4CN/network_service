import 'package:get_it/get_it.dart';
import 'package:network_service/src/dio_network_manager.dart';
import 'package:network_service/src/network_service.dart';
import 'package:network_service/src/token_manager.dart';

import 'errors/errors.dart';

final getIt = GetIt.instance;

Future<void> setupNetworkModule({
  required ITokenManager tokenManager,
  List<String> publicEndpoints = const [],
}) async {
  if (!getIt.isRegistered<ITokenManager>()) {
    getIt.registerSingleton<ITokenManager>(tokenManager);
  }

  if (!getIt.isRegistered<ErrorHandler>()) {
    getIt.registerSingleton<ErrorHandler>(DefaultErrorHandler());
  }

  if (!getIt.isRegistered<NetworkService>()) {
    getIt.registerSingleton<NetworkService>(
      DioNetworkManager(
        tokenManager: getIt<ITokenManager>(),
        errorHandler: getIt<ErrorHandler>(),
        publicEndpoints: publicEndpoints,
      ),
    );
  }
}
