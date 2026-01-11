/// Role Service
/// 
/// Handles role-related operations using Firebase Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/role_model.dart';
import '../models/permission_model.dart';

class RoleService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Convert Firestore document to RoleModel JSON
  Map<String, dynamic> _docToRoleJson(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final jsonData = <String, dynamic>{'role_id': int.tryParse(doc.id) ?? 0};
    data.forEach((key, value) {
      if (value is Timestamp) {
        jsonData[key] = value.toDate().toIso8601String();
      } else {
        jsonData[key] = value;
      }
    });
    return jsonData;
  }

  /// Get all roles
  Future<List<RoleModel>> getRoles() async {
    try {
      final snapshot = await _firestore.collection('roles').get();
      return snapshot.docs.map((doc) {
        return RoleModel.fromJson(_docToRoleJson(doc));
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch roles: $e');
    }
  }

  /// Get role by ID
  Future<RoleModel?> getRoleById(int roleId) async {
    try {
      final doc = await _firestore.collection('roles').doc(roleId.toString()).get();
      if (!doc.exists) return null;
      return RoleModel.fromJson(_docToRoleJson(doc));
    } catch (e) {
      throw Exception('Failed to fetch role: $e');
    }
  }

  /// Create new role
  Future<RoleModel> createRole(RoleModel role) async {
    try {
      final data = role.toJson();
      data.remove('role_id');
      data['created_at'] = FieldValue.serverTimestamp();
      data['updated_at'] = FieldValue.serverTimestamp();

      // Get next ID
      final snapshot = await _firestore.collection('roles').orderBy('role_id', descending: true).limit(1).get();
      int nextId = 1;
      if (snapshot.docs.isNotEmpty) {
        final lastId = snapshot.docs.first.data()['role_id'] as int? ?? 0;
        nextId = lastId + 1;
      }

      final docRef = _firestore.collection('roles').doc(nextId.toString());
      data['role_id'] = nextId;
      await docRef.set(data);

      final createdDoc = await docRef.get();
      return RoleModel.fromJson(_docToRoleJson(createdDoc));
    } catch (e) {
      throw Exception('Failed to create role: $e');
    }
  }

  /// Update role
  Future<RoleModel> updateRole(RoleModel role) async {
    try {
      if (role.roleId == null) {
        throw Exception('Role ID is required for update');
      }

      final data = role.toJson();
      data.remove('role_id');
      data['updated_at'] = FieldValue.serverTimestamp();

      await _firestore.collection('roles').doc(role.roleId.toString()).update(data);

      final updatedDoc = await _firestore.collection('roles').doc(role.roleId.toString()).get();
      return RoleModel.fromJson(_docToRoleJson(updatedDoc));
    } catch (e) {
      throw Exception('Failed to update role: $e');
    }
  }

  /// Delete role
  Future<void> deleteRole(int roleId) async {
    try {
      await _firestore.collection('roles').doc(roleId.toString()).delete();
    } catch (e) {
      throw Exception('Failed to delete role: $e');
    }
  }

  /// Get permissions for a role
  Future<List<int>> getRolePermissions(int roleId) async {
    try {
      final snapshot = await _firestore
          .collection('role_permissions')
          .where('role_id', isEqualTo: roleId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return data['permission_id'] as int;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch role permissions: $e');
    }
  }

  /// Update role permissions
  Future<void> updateRolePermissions(int roleId, List<int> permissionIds) async {
    try {
      // Delete existing permissions
      final existingSnapshot = await _firestore
          .collection('role_permissions')
          .where('role_id', isEqualTo: roleId)
          .get();

      final batch = _firestore.batch();
      for (var doc in existingSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Add new permissions
      for (var permissionId in permissionIds) {
        final docRef = _firestore.collection('role_permissions').doc();
        batch.set(docRef, {
          'role_id': roleId,
          'permission_id': permissionId,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update role permissions: $e');
    }
  }

  /// Watch roles in real-time
  Stream<List<RoleModel>> watchRoles() {
    return _firestore.collection('roles').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return RoleModel.fromJson(_docToRoleJson(doc));
      }).toList();
    });
  }
}

