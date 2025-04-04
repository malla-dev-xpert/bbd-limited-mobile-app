import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  NetworkService() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _controller.add(result != ConnectivityResult.none);
    });
  }

  Stream<bool> get onNetworkChange => _controller.stream;

  Future<bool> isConnected() async {
    var result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
