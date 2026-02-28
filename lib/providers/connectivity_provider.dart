import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

/// Provider that exposes connectivity state and sync status to the UI.
class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _connectivityService;
  final SyncService _syncService;

  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<SyncStatus>? _syncSub;

  bool _isOnline = true;
  SyncStatus _syncStatus = SyncStatus.synced;
  DateTime? _lastSync;

  bool get isOnline => _isOnline;
  SyncStatus get syncStatus => _syncStatus;
  DateTime? get lastSync => _lastSync;

  ConnectivityProvider(this._connectivityService, this._syncService) {
    _isOnline = _connectivityService.isOnline;

    _connectivitySub = _connectivityService.onlineStream.listen((online) {
      _isOnline = online;
      if (!online) {
        _syncStatus = SyncStatus.offline;
      }
      notifyListeners();
    });

    _syncSub = _syncService.statusStream.listen((status) {
      _syncStatus = status;
      if (status == SyncStatus.synced) {
        _lastSync = DateTime.now();
      }
      notifyListeners();
    });
  }

  /// Trigger a manual sync.
  Future<void> syncNow() async {
    await _syncService.syncNow();
    _lastSync = await _syncService.lastSyncTime();
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _syncSub?.cancel();
    super.dispose();
  }
}
