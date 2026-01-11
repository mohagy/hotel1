/// Category Service
/// 
/// Handles category-related operations using Firebase Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CategoryService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Get all categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').orderBy('name').get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return {
          'id': int.tryParse(doc.id) ?? 0,
          'name': data['name'] ?? '',
          'description': data['description'],
          'product_count': data['product_count'] ?? 0,
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Get category by ID
  Future<Map<String, dynamic>?> getCategoryById(int categoryId) async {
    try {
      final doc = await _firestore.collection('categories').doc(categoryId.toString()).get();
      
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return {
        'id': int.tryParse(doc.id) ?? 0,
        'name': data['name'] ?? '',
        'description': data['description'],
        'product_count': data['product_count'] ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  /// Create new category
  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> categoryData) async {
    try {
      String docId;
      if (categoryData['id'] != null && categoryData['id'] > 0) {
        docId = categoryData['id'].toString();
      } else {
        // Generate next ID
        final snapshot = await _firestore.collection('categories').orderBy('id', descending: true).limit(1).get();
        if (snapshot.docs.isNotEmpty) {
          final maxId = int.tryParse(snapshot.docs.first.id) ?? 0;
          docId = (maxId + 1).toString();
        } else {
          docId = '1';
        }
      }
      
      final data = Map<String, dynamic>.from(categoryData);
      data.remove('id');
      data['created_at'] = FieldValue.serverTimestamp();
      data['updated_at'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('categories').doc(docId).set(data);
      
      final createdDoc = await _firestore.collection('categories').doc(docId).get();
      final createdData = createdDoc.data() as Map<String, dynamic>? ?? {};
      return {
        'id': int.tryParse(docId) ?? 0,
        'name': createdData['name'] ?? '',
        'description': createdData['description'],
        'product_count': createdData['product_count'] ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  /// Update category
  Future<Map<String, dynamic>> updateCategory(int categoryId, Map<String, dynamic> categoryData) async {
    try {
      final data = Map<String, dynamic>.from(categoryData);
      data.remove('id');
      data['updated_at'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('categories').doc(categoryId.toString()).update(data);
      
      final updatedDoc = await _firestore.collection('categories').doc(categoryId.toString()).get();
      final updatedData = updatedDoc.data() as Map<String, dynamic>? ?? {};
      return {
        'id': categoryId,
        'name': updatedData['name'] ?? '',
        'description': updatedData['description'],
        'product_count': updatedData['product_count'] ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  /// Delete category
  Future<void> deleteCategory(int categoryId) async {
    try {
      await _firestore.collection('categories').doc(categoryId.toString()).delete();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }
}

