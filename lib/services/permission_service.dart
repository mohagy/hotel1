/// Permission Service
/// 
/// Handles permission-related operations using Firebase Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/permission_model.dart';

class PermissionService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Convert Firestore document to PermissionModel JSON
  Map<String, dynamic> _docToPermissionJson(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final jsonData = <String, dynamic>{'permission_id': int.tryParse(doc.id) ?? 0};
    data.forEach((key, value) {
      if (value is Timestamp) {
        jsonData[key] = value.toDate().toIso8601String();
      } else {
        jsonData[key] = value;
      }
    });
    return jsonData;
  }

  /// Get all permissions
  Future<List<PermissionModel>> getPermissions() async {
    try {
      // Fetch all permissions and sort in memory to avoid index requirement
      final snapshot = await _firestore.collection('permissions').get();
      final permissions = snapshot.docs.map((doc) {
        return PermissionModel.fromJson(_docToPermissionJson(doc));
      }).toList();
      
      // Sort by category, then by name
      permissions.sort((a, b) {
        final categoryCompare = a.category.compareTo(b.category);
        if (categoryCompare != 0) return categoryCompare;
        return a.name.compareTo(b.name);
      });
      
      return permissions;
    } catch (e) {
      throw Exception('Failed to fetch permissions: $e');
    }
  }

  /// Get permissions by category
  Future<Map<String, List<PermissionModel>>> getPermissionsByCategory() async {
    try {
      final permissions = await getPermissions();
      final Map<String, List<PermissionModel>> categorized = {};

      for (var permission in permissions) {
        if (!categorized.containsKey(permission.category)) {
          categorized[permission.category] = [];
        }
        categorized[permission.category]!.add(permission);
      }

      return categorized;
    } catch (e) {
      throw Exception('Failed to fetch permissions by category: $e');
    }
  }

  /// Get permission by ID
  Future<PermissionModel?> getPermissionById(int permissionId) async {
    try {
      final doc = await _firestore.collection('permissions').doc(permissionId.toString()).get();
      if (!doc.exists) return null;
      return PermissionModel.fromJson(_docToPermissionJson(doc));
    } catch (e) {
      throw Exception('Failed to fetch permission: $e');
    }
  }

  /// Create new permission
  Future<PermissionModel> createPermission(PermissionModel permission) async {
    try {
      final data = permission.toJson();
      data.remove('permission_id');
      data['created_at'] = FieldValue.serverTimestamp();
      data['updated_at'] = FieldValue.serverTimestamp();

      // Get next ID
      final snapshot = await _firestore.collection('permissions').orderBy('permission_id', descending: true).limit(1).get();
      int nextId = 1;
      if (snapshot.docs.isNotEmpty) {
        final lastId = snapshot.docs.first.data()['permission_id'] as int? ?? 0;
        nextId = lastId + 1;
      }

      final docRef = _firestore.collection('permissions').doc(nextId.toString());
      data['permission_id'] = nextId;
      await docRef.set(data);

      final createdDoc = await docRef.get();
      return PermissionModel.fromJson(_docToPermissionJson(createdDoc));
    } catch (e) {
      throw Exception('Failed to create permission: $e');
    }
  }

  /// Update permission
  Future<PermissionModel> updatePermission(PermissionModel permission) async {
    try {
      if (permission.permissionId == null) {
        throw Exception('Permission ID is required for update');
      }

      final data = permission.toJson();
      data.remove('permission_id');
      data['updated_at'] = FieldValue.serverTimestamp();

      await _firestore.collection('permissions').doc(permission.permissionId.toString()).update(data);

      final updatedDoc = await _firestore.collection('permissions').doc(permission.permissionId.toString()).get();
      return PermissionModel.fromJson(_docToPermissionJson(updatedDoc));
    } catch (e) {
      throw Exception('Failed to update permission: $e');
    }
  }

  /// Delete permission
  Future<void> deletePermission(int permissionId) async {
    try {
      await _firestore.collection('permissions').doc(permissionId.toString()).delete();
    } catch (e) {
      throw Exception('Failed to delete permission: $e');
    }
  }

  /// Watch permissions in real-time
  Stream<List<PermissionModel>> watchPermissions() {
    return _firestore.collection('permissions').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PermissionModel.fromJson(_docToPermissionJson(doc));
      }).toList();
    });
  }
}

