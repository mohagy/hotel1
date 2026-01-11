/// Firestore Service
/// 
/// Handles real-time data synchronization with Firebase Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get Firestore instance
  FirebaseFirestore get firestore => _firestore;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Watch a collection in real-time
  Stream<QuerySnapshot> watchCollection(String collection) {
    return _firestore.collection(collection).snapshots();
  }

  /// Watch a document in real-time
  Stream<DocumentSnapshot> watchDocument(String collection, String documentId) {
    return _firestore.collection(collection).doc(documentId).snapshots();
  }

  /// Get documents from a collection
  Future<QuerySnapshot> getCollection(String collection, {Map<String, dynamic>? where}) async {
    Query query = _firestore.collection(collection);
    
    if (where != null) {
      where.forEach((field, value) {
        query = query.where(field, isEqualTo: value);
      });
    }
    
    return await query.get();
  }

  /// Get a document by ID
  Future<DocumentSnapshot> getDocument(String collection, String documentId) async {
    return await _firestore.collection(collection).doc(documentId).get();
  }

  /// Create a document
  Future<DocumentReference> createDocument(String collection, Map<String, dynamic> data) async {
    return await _firestore.collection(collection).add(data);
  }

  /// Create a document with custom ID
  Future<void> createDocumentWithId(String collection, String documentId, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(documentId).set(data);
  }

  /// Update a document
  Future<void> updateDocument(String collection, String documentId, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(documentId).update(data);
  }

  /// Delete a document
  Future<void> deleteDocument(String collection, String documentId) async {
    await _firestore.collection(collection).doc(documentId).delete();
  }

  /// Watch rooms in real-time
  Stream<QuerySnapshot> watchRooms() {
    return watchCollection('rooms');
  }

  /// Watch reservations in real-time
  Stream<QuerySnapshot> watchReservations() {
    return watchCollection('reservations');
  }

  /// Watch chat messages for a conversation
  Stream<QuerySnapshot> watchChatMessages(int conversationId) {
    return _firestore
        .collection('chat_messages')
        .where('conversation_id', isEqualTo: conversationId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Watch notifications for current user
  Stream<QuerySnapshot> watchNotifications() {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('notifications')
        .where('user_id', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Send a chat message
  Future<void> sendChatMessage({
    required int conversationId,
    required String message,
    String? attachmentUrl,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await _firestore.collection('chat_messages').add({
      'conversation_id': conversationId,
      'sender_id': currentUserId,
      'message': message,
      'message_type': attachmentUrl != null ? 'image' : 'text',
      'attachment_url': attachmentUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'is_read': false,
    });

    // Update conversation last activity
    await _firestore.collection('conversations').doc(conversationId.toString()).update({
      'last_activity': FieldValue.serverTimestamp(),
    });
  }
}

