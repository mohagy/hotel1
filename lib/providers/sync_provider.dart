/// Sync Provider
/// 
/// Manages sync state and connectivity status

import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/sync_service.dart';
import '../services/offline_storage_service.dart';

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService = SyncService();
  final Connectivity _connectivity = Connectivity();
  
  bool _isOnline = true;
  bool _isSyncing = false;
  int _pendingOperations = 0;
  String? _lastSyncError;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingOperations => _pendingOperations;
  String? get lastSyncError => _lastSyncError;

  SyncProvider() {
    _initConnectivityListener();
    _updatePendingOperations();
  }

  /// Initialize connectivity listener
  void _initConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (wasOffline && _isOnline) {
        // Device came online - trigger sync
        syncAll();
      }
      
      notifyListeners();
    });

    // Check initial connectivity
    _checkConnectivity();
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;
      
      // Also verify actual internet connection
      if (_isOnline) {
        _isOnline = await _syncService.isOnline();
      }
      
      notifyListeners();
    } catch (e) {
      _isOnline = false;
      notifyListeners();
    }
  }

  /// Update pending operations count
  void _updatePendingOperations() {
    final queue = OfflineStorageService.getSyncQueue();
    _pendingOperations = queue.length;
    notifyListeners();
  }

  /// Sync all data from remote
  Future<bool> syncFromRemote() async {
    if (!_isOnline) {
      _lastSyncError = 'Device is offline';
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      final success = await _syncService.syncFromRemote();
      _isSyncing = false;
      _lastSyncError = success ? null : _syncService.lastError;
      notifyListeners();
      return success;
    } catch (e) {
      _isSyncing = false;
      _lastSyncError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sync pending queue operations
  Future<bool> syncQueue() async {
    if (!_isOnline) {
      _lastSyncError = 'Device is offline';
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      final success = await _syncService.syncQueueToRemote();
      _isSyncing = false;
      _lastSyncError = success ? null : _syncService.lastError;
      _updatePendingOperations();
      notifyListeners();
      return success;
    } catch (e) {
      _isSyncing = false;
      _lastSyncError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sync all (from remote + queue)
  Future<bool> syncAll() async {
    if (!_isOnline) {
      _lastSyncError = 'Device is offline';
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      // First sync from remote to get latest data
      final syncFromRemoteSuccess = await _syncService.syncFromRemote();
      
      // Then sync pending queue operations
      final syncQueueSuccess = await _syncService.syncQueueToRemote();
      
      _isSyncing = false;
      final allSuccess = syncFromRemoteSuccess && syncQueueSuccess;
      _lastSyncError = allSuccess ? null : _syncService.lastError;
      _updatePendingOperations();
      notifyListeners();
      
      return allSuccess;
    } catch (e) {
      _isSyncing = false;
      _lastSyncError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sync a specific entity type
  Future<bool> syncEntityType(String entityType) async {
    if (!_isOnline) {
      _lastSyncError = 'Device is offline';
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      final success = await _syncService.syncEntityType(entityType);
      _isSyncing = false;
      _lastSyncError = success ? null : _syncService.lastError;
      notifyListeners();
      return success;
    } catch (e) {
      _isSyncing = false;
      _lastSyncError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    final stats = _syncService.getSyncStats();
    stats['isOnline'] = _isOnline;
    stats['isSyncing'] = _isSyncing;
    return stats;
  }

  /// Refresh connectivity status
  Future<void> refreshConnectivity() async {
    await _checkConnectivity();
  }

  /// Refresh pending operations count
  void refreshPendingOperations() {
    _updatePendingOperations();
  }
}


