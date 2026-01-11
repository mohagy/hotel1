/// Chat Service
/// 
/// Handles group chat and private chat operations using Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Group chat ID (all staff chatroom)
  static const String groupChatId = 'group_chat_all_staff';

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get current user email/name
  String get currentUserName => _auth.currentUser?.email ?? 'User';

  /// Get or create group chat conversation
  Future<String> getOrCreateGroupChat() async {
    try {
      final doc = await _firestore.collection('conversations').doc(groupChatId).get();
      
      if (!doc.exists) {
        // Create group chat conversation
        await _firestore.collection('conversations').doc(groupChatId).set({
          'type': 'group',
          'title': 'All Staff Chat',
          'participants': [], // Empty means all staff
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
      }
      
      return groupChatId;
    } catch (e) {
      throw Exception('Error getting group chat: $e');
    }
  }

  /// Send message to group chat
  Future<void> sendGroupMessage({
    required String message,
    String? messageType, // 'announcement', 'task', 'emergency', 'alert', 'normal'
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final conversationId = await getOrCreateGroupChat();
      
      // Add message
      await _firestore.collection('messages').add({
        'conversationId': conversationId,
        'senderId': currentUserId,
        'senderName': currentUserName,
        'text': message.trim(),
        'messageType': messageType ?? 'normal',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'group',
      });

      // Update conversation
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': message.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': currentUserId,
        'lastSenderName': currentUserName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error sending group message: $e');
    }
  }

  /// Get or create private conversation
  Future<String> getOrCreatePrivateConversation(String otherUserId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Create sorted list for participants to check
      final participants = [currentUserId!, otherUserId]..sort();
      final conversationKey = 'private_${participants[0]}_${participants[1]}';

      // Check if conversation already exists
      final existing = await _firestore
          .collection('conversations')
          .where('type', isEqualTo: 'private')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var doc in existing.docs) {
        final data = doc.data();
        final convParticipants = List<String>.from(data['participants'] ?? []);
        convParticipants.sort();
        
        if (convParticipants.length == 2 &&
            convParticipants[0] == participants[0] &&
            convParticipants[1] == participants[1]) {
          return doc.id;
        }
      }

      // Create new conversation
      final conversationRef = await _firestore.collection('conversations').add({
        'type': 'private',
        'participants': [currentUserId, otherUserId],
        'otherParticipantName_$currentUserId': '', // Will be fetched from users collection
        'otherParticipantName_$otherUserId': currentUserName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      return conversationRef.id;
    } catch (e) {
      throw Exception('Error creating private conversation: $e');
    }
  }

  /// Send private message
  Future<void> sendPrivateMessage({
    required String conversationId,
    required String message,
    String? messageType,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get conversation to find other participant
      final conversation = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();
      
      if (!conversation.exists) {
        throw Exception('Conversation not found');
      }

      final data = conversation.data()!;
      final participants = List<String>.from(data['participants'] ?? []);
      final otherUserId = participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );

      // Add message
      await _firestore.collection('messages').add({
        'conversationId': conversationId,
        'senderId': currentUserId,
        'senderName': currentUserName,
        'text': message.trim(),
        'messageType': messageType ?? 'normal',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'private',
      });

      // Update conversation
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': message.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': currentUserId,
        'lastSenderName': currentUserName,
        'unreadCount_$otherUserId': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error sending private message: $e');
    }
  }

  /// Watch group chat messages
  Stream<QuerySnapshot> watchGroupMessages() {
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: groupChatId)
        .where('type', isEqualTo: 'group')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  /// Watch private conversation messages
  Stream<QuerySnapshot> watchPrivateMessages(String conversationId) {
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .where('type', isEqualTo: 'private')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  /// Watch all conversations (group + private)
  Stream<QuerySnapshot> watchConversations() {
    if (currentUserId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Watch group chat conversation
  Stream<DocumentSnapshot> watchGroupChat() {
    return _firestore
        .collection('conversations')
        .doc(groupChatId)
        .snapshots();
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    if (currentUserId == null) return;

    try {
      // Reset unread count for current user
      await _firestore.collection('conversations').doc(conversationId).update({
        'unreadCount_$currentUserId': 0,
      });

      // Mark messages as read
      final messages = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .where('senderId', isNotEqualTo: currentUserId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      // Error marking messages as read - continue
    }
  }

  /// Get all users for private chat selection
  /// Tries Firestore users collection first, falls back to Firebase Auth users
  Stream<QuerySnapshot> watchUsers() {
    // Try to get users from Firestore users collection
    // If that doesn't work, we'll need to get users from Firebase Auth (requires admin SDK on backend)
    return _firestore
        .collection('users')
        .snapshots();
  }

  /// Get users list (for user selection)
  /// This returns a stream that includes all authenticated users
  /// Note: In production, you might want to sync Firebase Auth users to Firestore
  Future<List<Map<String, dynamic>>> getUsersList() async {
    try {
      // Get users from Firestore
      final usersSnapshot = await _firestore.collection('users').get();
      final users = <Map<String, dynamic>>[];
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        users.add({
          'id': doc.id,
          'email': data['email'] ?? data['emailAddress'] ?? '',
          'name': data['name'] ?? data['displayName'] ?? data['fullName'] ?? '',
          'role': data['role'] ?? 'staff',
          ...data,
        });
      }
      
      return users;
    } catch (e) {
      // If Firestore users collection doesn't exist or is empty,
      // return empty list (users should be synced from Firebase Auth)
      return [];
    }
  }
}
