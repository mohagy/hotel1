/// Auth Sync Service
/// 
/// Syncs Firebase Auth users to Firestore automatically

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'user_service.dart';

class AuthSyncService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  /// Initialize auth state listener to sync users to Firestore
  void initialize() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _syncUserToFirestore(user);
      }
    });
  }

  /// Sync a Firebase Auth user to Firestore
  Future<void> _syncUserToFirestore(User user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      final userData = <String, dynamic>{
        'firebase_uid': user.uid,
        'email': user.email,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // If user doesn't exist in Firestore, set default values
      if (!doc.exists) {
        // Extract username from email (before @)
        final username = user.email?.split('@').first ?? user.uid.substring(0, 8);
        final displayName = user.displayName ?? username;
        
        userData['username'] = username;
        userData['full_name'] = displayName;
        userData['role'] = 'staff'; // Default role
        userData['status'] = 'active'; // Default status
        userData['created_at'] = FieldValue.serverTimestamp();
      } else {
        // Update existing user with current email if changed
        final existingData = doc.data() as Map<String, dynamic>?;
        if (existingData != null) {
          userData['username'] = existingData['username'];
          userData['full_name'] = existingData['full_name'] ?? user.displayName;
          userData['role'] = existingData['role'] ?? 'staff';
          userData['status'] = existingData['status'] ?? 'active';
        }
      }

      await docRef.set(userData, SetOptions(merge: true));
    } catch (e) {
      // Silently fail - user sync shouldn't break the app
      debugPrint('Error syncing user to Firestore: $e');
    }
  }
}

