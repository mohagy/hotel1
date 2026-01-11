/// User Service
/// 
/// Handles user-related operations using Firebase Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Convert Firestore document to UserModel JSON
  Map<String, dynamic> _docToUserJson(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final jsonData = <String, dynamic>{'user_id': doc.id};
    data.forEach((key, value) {
      if (value is Timestamp) {
        jsonData[key] = value.toDate().toIso8601String();
      } else {
        jsonData[key] = value;
      }
    });
    return jsonData;
  }

  /// Get all users
  Future<List<UserModel>> getUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        return UserModel.fromJson(_docToUserJson(doc));
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Get user by ID (can be integer ID or Firebase UID string)
  Future<UserModel?> getUserById(dynamic userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId.toString()).get();
      if (!doc.exists) return null;
      final userData = _docToUserJson(doc);
      // Ensure user_id is set from doc ID if not present
      if (!userData.containsKey('user_id') || userData['user_id'] == null) {
        userData['user_id'] = doc.id;
      }
      return UserModel.fromJson(userData);
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  /// Create new user (creates in Firebase Auth if email and password provided, then syncs to Firestore)
  Future<UserModel> createUser(UserModel user, {String? password}) async {
    try {
      UserCredential? userCredential;
      String? firebaseAuthUid;

      // Create user in Firebase Auth if email and password are provided
      if (user.email != null && password != null && password.isNotEmpty) {
        try {
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: user.email!,
            password: password,
          );
          firebaseAuthUid = userCredential.user?.uid;
        } catch (e) {
          // If user already exists, we'll just use Firestore
          debugPrint('Note: Could not create user in Firebase Auth (may already exist): $e');
        }
      }

      // Store user data in Firestore
      // Use Firebase Auth UID if available, otherwise use username as doc ID
      final docId = firebaseAuthUid ?? user.username;
      final data = user.toJson();
      data.remove('user_id');
      if (firebaseAuthUid != null) {
        data['firebase_uid'] = firebaseAuthUid; // Store Firebase Auth UID
      }
      data['created_at'] = FieldValue.serverTimestamp();
      data['updated_at'] = FieldValue.serverTimestamp();

      // Use Firebase Auth UID or username as document ID
      final docRef = _firestore.collection('users').doc(docId);
      await docRef.set(data, SetOptions(merge: true));

      // Get the created document
      final createdDoc = await docRef.get();
      final userData = _docToUserJson(createdDoc);
      // Use doc ID as user_id if not present
      if (!userData.containsKey('user_id') || userData['user_id'] == null) {
        userData['user_id'] = docId;
      }
      return UserModel.fromJson(userData);
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Update user
  Future<UserModel> updateUser(UserModel user) async {
    try {
      if (user.userId == null) {
        throw Exception('User ID is required for update');
      }

      final data = user.toJson();
      data.remove('user_id');
      data['updated_at'] = FieldValue.serverTimestamp();

      final docId = user.userId.toString();
      await _firestore.collection('users').doc(docId).update(data);

      final updatedDoc = await _firestore.collection('users').doc(docId).get();
      return UserModel.fromJson(_docToUserJson(updatedDoc));
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Delete user (can be integer ID or Firebase UID string)
  Future<void> deleteUser(dynamic userId) async {
    try {
      await _firestore.collection('users').doc(userId.toString()).delete();
      // Note: To delete from Firebase Auth, you need Admin SDK on backend
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Watch users in real-time
  Stream<List<UserModel>> watchUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromJson(_docToUserJson(doc));
      }).toList();
    });
  }
}

