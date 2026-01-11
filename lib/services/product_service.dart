/// Product Service
/// 
/// Handles product-related operations using Firebase Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

class ProductService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Helper to convert Firestore Timestamp to DateTime
  DateTime? _timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    if (timestamp is DateTime) {
      return timestamp;
    }
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Convert Firestore document to ProductModel JSON
  Map<String, dynamic> _docToProductJson(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final jsonData = <String, dynamic>{'id': int.tryParse(doc.id) ?? 0};
    data.forEach((key, value) {
      if (value is Timestamp) {
        jsonData[key] = value.toDate().toIso8601String();
      } else if (key == 'image_url' || key == 'image') {
        // Handle both image_url and image fields
        jsonData['image_url'] = value;
        jsonData['image'] = value;
      } else if (key == 'stock' || key == 'stock_quantity') {
        // Handle both stock and stock_quantity fields
        jsonData['stock'] = value;
        jsonData['stock_quantity'] = value;
      } else if (key == 'upc' || key == 'barcode' || key == 'code') {
        // Handle barcode/upc/code fields
        jsonData['upc'] = value;
        jsonData['barcode'] = value;
        jsonData['code'] = value;
      } else {
        jsonData[key] = value;
      }
    });
    return jsonData;
  }

  /// Get all products
  Future<List<ProductModel>> getProducts({int? categoryId}) async {
    try {
      Query query = _firestore.collection('products');
      
      if (categoryId != null) {
        query = query.where('category_id', isEqualTo: categoryId);
      }
      
      query = query.orderBy('name');
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        return ProductModel.fromJson(_docToProductJson(doc));
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Get product by ID
  Future<ProductModel?> getProductById(int productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId.toString()).get();
      
      if (!doc.exists) {
        return null;
      }
      
      return ProductModel.fromJson(_docToProductJson(doc));
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  /// Create new product
  Future<ProductModel> createProduct(ProductModel product) async {
    try {
      String docId;
      if (product.id != null && product.id! > 0) {
        docId = product.id.toString();
      } else {
        // Generate next ID
        final snapshot = await _firestore.collection('products').orderBy('id', descending: true).limit(1).get();
        if (snapshot.docs.isNotEmpty) {
          final maxId = int.tryParse(snapshot.docs.first.id) ?? 0;
          docId = (maxId + 1).toString();
        } else {
          docId = '1';
        }
      }
      
      final data = product.toJson();
      data.remove('id');
      data['created_at'] = FieldValue.serverTimestamp();
      data['updated_at'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('products').doc(docId).set(data);
      
      final createdDoc = await _firestore.collection('products').doc(docId).get();
      return ProductModel.fromJson(_docToProductJson(createdDoc));
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  /// Update product
  Future<ProductModel> updateProduct(ProductModel product) async {
    try {
      if (product.id == null) {
        throw Exception('Product ID is required for update');
      }
      
      final data = product.toJson();
      data.remove('id');
      data['updated_at'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('products').doc(product.id.toString()).update(data);
      
      final updatedDoc = await _firestore.collection('products').doc(product.id.toString()).get();
      return ProductModel.fromJson(_docToProductJson(updatedDoc));
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// Delete product
  Future<void> deleteProduct(int productId) async {
    try {
      await _firestore.collection('products').doc(productId.toString()).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  /// Watch products in real-time
  Stream<List<ProductModel>> watchProducts({int? categoryId}) {
    Query query = _firestore.collection('products');
    
    if (categoryId != null) {
      query = query.where('category_id', isEqualTo: categoryId);
    }
    
    return query
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromJson(_docToProductJson(doc));
      }).toList();
    });
  }
}

