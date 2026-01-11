/// Authentication Provider
/// 
/// Manages authentication state using Firebase Auth and Provider pattern

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _loadUserFromStorage();
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    _saveUserToStorage();
    notifyListeners();
  }

  Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConfig.userIdKey);
      
      if (userId != null && _auth.currentUser != null) {
        _user = _auth.currentUser;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user from storage: $e');
    }
  }

  Future<void> _saveUserToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_user != null) {
        await prefs.setString(AppConfig.userIdKey, _user!.uid);
      } else {
        await prefs.remove(AppConfig.userIdKey);
      }
    } catch (e) {
      debugPrint('Error saving user to storage: $e');
    }
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;
      _isLoading = false;
      notifyListeners();
      
      // Note: Permission loading is handled by PermissionProvider via auth state changes
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Authentication failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signOut();
      _user = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error signing out: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check authentication status
  Future<bool> checkAuthStatus() async {
    try {
      _user = _auth.currentUser;
      if (_user != null) {
        // Optionally verify token with PHP backend
        // This can be implemented later if needed
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      return false;
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Failed to send password reset email';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

