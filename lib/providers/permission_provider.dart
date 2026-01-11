/// Permission Provider
/// 
/// Manages user permissions state

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/permission_checker_service.dart';
import '../models/user_model.dart';

class PermissionProvider extends ChangeNotifier {
  final PermissionCheckerService _permissionChecker = PermissionCheckerService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  UserModel? _currentUser;
  Set<String> _permissions = {};
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  Set<String> get permissions => _permissions;
  bool get isLoading => _isLoading;

  PermissionProvider() {
    // Listen to auth state changes to reload permissions
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        loadPermissions();
      } else {
        clearPermissions();
      }
    });
  }

  /// Load current user and permissions
  Future<void> loadPermissions() async {
    try {
      _isLoading = true;
      notifyListeners();

      _currentUser = await _permissionChecker.getCurrentUser();
      if (_currentUser != null) {
        final userId = _currentUser!.userId?.toString() ?? _auth.currentUser?.uid;
        _permissions = await _permissionChecker.getUserPermissions(userId);
      } else {
        _permissions = {};
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading permissions: $e');
      _isLoading = false;
      _permissions = {};
      notifyListeners();
    }
  }

  /// Check if user has a specific permission
  bool hasPermission(String permissionKey) {
    return _permissions.contains(permissionKey);
  }

  /// Check if user has any of the specified permissions
  bool hasAnyPermission(List<String> permissionKeys) {
    return permissionKeys.any((key) => _permissions.contains(key));
  }

  /// Check if user has all of the specified permissions
  bool hasAllPermissions(List<String> permissionKeys) {
    return permissionKeys.every((key) => _permissions.contains(key));
  }

  /// Clear permissions (call on logout)
  void clearPermissions() {
    _currentUser = null;
    _permissions = {};
    _permissionChecker.clearCache();
    notifyListeners();
  }
}

