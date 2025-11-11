import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final _connectivity = Connectivity();

  /// Retorna `true` se estiver online.
  static Future<bool> hasConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Escuta mudanças de conexão.
  static Stream<bool> get onConnectionChange async* {
    yield* _connectivity.onConnectivityChanged.map(
      (status) => status != ConnectivityResult.none,
    );
  }
}
