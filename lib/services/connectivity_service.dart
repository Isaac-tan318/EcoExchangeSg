import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  late final StreamSubscription _sub;

  ConnectivityService() {
    _sub = Connectivity().onConnectivityChanged.listen((result) {
      final offline = result.contains(ConnectivityResult.none);
      _controller.add(!offline);
    });
    // Prime current state
    Connectivity().checkConnectivity().then((result) {
      final offline = result.contains(ConnectivityResult.none);
      _controller.add(!offline);
    });
  }

  Stream<bool> get isOnline$ => _controller.stream;

  void dispose() {
    _sub.cancel();
    _controller.close();
  }
}
