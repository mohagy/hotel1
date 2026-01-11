/// Permission Checker Service
/// 
/// Checks if a user has specific permissions based on their role

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class PermissionCheckerService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Cache for user permissions
  Map<String, Set<String>> _permissionsCache = {};
  Map<String, UserModel> _userCache = {};

  /// Get current user from Firestore (with caching)
  Future<UserModel?> getCurrentUser() async {
    if (currentUserId == null) return null;

    // Check cache first
    if (_userCache.containsKey(currentUserId)) {
      return _userCache[currentUserId];
    }

    try {
      // Try to get user by Firebase UID first
      final doc = await _firestore.collection('users').doc(currentUserId!).get();
      if (!doc.exists) {
        // Try to find by firebase_uid field
        final query = await _firestore
            .collection('users')
            .where('firebase_uid', isEqualTo: currentUserId!)
            .limit(1)
            .get();
        
        if (query.docs.isEmpty) {
          return null;
        }
        
        final userData = query.docs.first.data();
        final jsonData = <String, dynamic>{'user_id': query.docs.first.id};
        userData.forEach((key, value) {
          if (value is Timestamp) {
            jsonData[key] = value.toDate().toIso8601String();
          } else {
            jsonData[key] = value;
          }
        });
        
        final user = UserModel.fromJson(jsonData);
        _userCache[currentUserId!] = user;
        return user;
      }

      final userData = doc.data() as Map<String, dynamic>? ?? {};
      final jsonData = <String, dynamic>{'user_id': doc.id};
      userData.forEach((key, value) {
        if (value is Timestamp) {
          jsonData[key] = value.toDate().toIso8601String();
        } else {
          jsonData[key] = value;
        }
      });

      final user = UserModel.fromJson(jsonData);
      _userCache[currentUserId!] = user;
      return user;
    } catch (e) {
      debugPrint('Error fetching current user: $e');
      return null;
    }
  }

  /// Get user's permissions based on their role
  Future<Set<String>> getUserPermissions(String? userId) async {
    if (userId == null) return {};

    // Check cache first
    if (_permissionsCache.containsKey(userId)) {
      return _permissionsCache[userId]!;
    }

    try {
      final user = await getCurrentUser();
      if (user == null) return {};

      // Get role name from user
      final roleName = user.role;
      if (roleName.isEmpty) return {};

      // Capitalize role name to match role names in Firestore (e.g., 'staff' -> 'Staff', 'admin' -> 'Admin')
      final capitalizedRoleName = roleName.isNotEmpty
          ? roleName[0].toUpperCase() + roleName.substring(1).toLowerCase()
          : roleName;

      // Find role by name (case-sensitive, so we capitalize it)
      final roleQuery = await _firestore
          .collection('roles')
          .where('name', isEqualTo: capitalizedRoleName)
          .limit(1)
          .get();

      if (roleQuery.docs.isEmpty) {
        debugPrint('Role not found: $roleName');
        return {};
      }

      final roleDoc = roleQuery.docs.first;
      final roleData = roleDoc.data();
      final roleId = roleData['role_id'] ?? int.tryParse(roleDoc.id) ?? 0;

      // Get role permissions - role_permissions collection uses role_id (int) and permission_id (int)
      final permissionsQuery = await _firestore
          .collection('role_permissions')
          .where('role_id', isEqualTo: roleId)
          .get();

      final permissionKeys = <String>{};

      // Get permission keys
      for (var rolePermDoc in permissionsQuery.docs) {
        final rolePermData = rolePermDoc.data();
        final permissionId = rolePermData['permission_id'];
        
        if (permissionId != null) {
          // Find permission by ID (permissions collection uses permission_id or doc ID)
          final permQuery = await _firestore
              .collection('permissions')
              .where('permission_id', isEqualTo: permissionId)
              .limit(1)
              .get();
          
          if (permQuery.docs.isEmpty) {
            // Try by doc ID
            final permDoc = await _firestore
                .collection('permissions')
                .doc(permissionId.toString())
                .get();
            
            if (permDoc.exists) {
              final permData = permDoc.data() as Map<String, dynamic>? ?? {};
              final key = permData['key'] as String?;
              if (key != null) {
                permissionKeys.add(key);
              }
            }
          } else {
            final permData = permQuery.docs.first.data();
            final key = permData['key'] as String?;
            if (key != null) {
              permissionKeys.add(key);
            }
          }
        }
      }

      // Cache permissions
      _permissionsCache[userId] = permissionKeys;
      return permissionKeys;
    } catch (e) {
      debugPrint('Error fetching user permissions: $e');
      return {};
    }
  }

  /// Check if current user has a specific permission
  Future<bool> hasPermission(String permissionKey) async {
    if (currentUserId == null) return false;

    final permissions = await getUserPermissions(currentUserId);
    return permissions.contains(permissionKey);
  }

  /// Check if current user has any of the specified permissions
  Future<bool> hasAnyPermission(List<String> permissionKeys) async {
    if (currentUserId == null) return false;

    final permissions = await getUserPermissions(currentUserId);
    return permissionKeys.any((key) => permissions.contains(key));
  }

  /// Check if current user has all of the specified permissions
  Future<bool> hasAllPermissions(List<String> permissionKeys) async {
    if (currentUserId == null) return false;

    final permissions = await getUserPermissions(currentUserId);
    return permissionKeys.every((key) => permissions.contains(key));
  }

  /// Clear cache (useful when user permissions are updated)
  void clearCache() {
    _permissionsCache.clear();
    _userCache.clear();
  }

  /// Clear cache for specific user
  void clearUserCache(String userId) {
    _permissionsCache.remove(userId);
    _userCache.remove(userId);
  }
}

