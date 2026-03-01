import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/logger_service.dart';

/// Monitors network connectivity and exposes the current state
/// as a [ValueNotifier]-style stream.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  /// Stream that emits whenever connectivity changes.
  final StreamController<bool> _onlineController =
      StreamController<bool>.broadcast();
  Stream<bool> get onlineStream => _onlineController.stream;

  /// Must be called once during app startup.
  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = _evaluateResults(results);

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = _evaluateResults(results);
      if (wasOnline != _isOnline) {
        _onlineController.add(_isOnline);
        AppLogger.info('Online: $_isOnline', tag: 'ConnectivityService');
      }
    });
  }

  bool _evaluateResults(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet,);
  }

  void dispose() {
    _subscription?.cancel();
    _onlineController.close();
  }
}
