/// Room Service
/// 
/// Handles room-related operations using Firebase Firestore
/// Migrated from PHP API + MySQL to Firestore for real-time updates

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/room_model.dart';

class RoomService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  /// Helper to convert Firestore Timestamp to DateTime string
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

  /// Convert Firestore document to RoomModel JSON
  Map<String, dynamic> _docToRoomJson(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final jsonData = <String, dynamic>{'room_id': int.tryParse(doc.id) ?? 0};
    data.forEach((key, value) {
      if (value is Timestamp) {
        jsonData[key] = value.toDate().toIso8601String();
      } else {
        jsonData[key] = value;
      }
    });
    return jsonData;
  }

  /// Get all rooms
  Future<List<RoomModel>> getRooms({Map<String, dynamic>? filters}) async {
    try {
      Query query = _firestore.collection('rooms');
      
      // Apply filters if provided
      if (filters != null) {
        if (filters['status'] != null) {
          query = query.where('status', isEqualTo: filters['status']);
        }
        if (filters['room_type'] != null) {
          query = query.where('room_type', isEqualTo: filters['room_type']);
        }
      }
      
      // Order by room number
      query = query.orderBy('room_number');
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        return RoomModel.fromJson(_docToRoomJson(doc));
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch rooms: $e');
    }
  }

  /// Get room by ID
  Future<RoomModel?> getRoomById(int roomId) async {
    try {
      final doc = await _firestore.collection('rooms').doc(roomId.toString()).get();
      
      if (!doc.exists) {
        return null;
      }
      
      return RoomModel.fromJson(_docToRoomJson(doc));
    } catch (e) {
      throw Exception('Failed to fetch room: $e');
    }
  }

  /// Get available rooms for date range
  Future<List<RoomModel>> getAvailableRooms({
    required DateTime checkIn,
    required DateTime checkOut,
    String? roomType,
  }) async {
    try {
      Query query = _firestore.collection('rooms').where('status', isEqualTo: 'available');
      
      if (roomType != null) {
        query = query.where('room_type', isEqualTo: roomType);
      }
      
      final snapshot = await query.get();
      final rooms = snapshot.docs.map((doc) {
        return RoomModel.fromJson(_docToRoomJson(doc));
      }).toList();
      
      // TODO: Filter by date range (check reservations collection for conflicts)
      // For now, return all available rooms of the specified type
      
      return rooms;
    } catch (e) {
      throw Exception('Failed to fetch available rooms: $e');
    }
  }

  /// Create new room
  Future<RoomModel> createRoom(RoomModel room) async {
    try {
      // Generate document ID
      String docId;
      if (room.roomId != null && room.roomId! > 0) {
        docId = room.roomId.toString();
      } else {
        // Get the next available ID (max + 1) or use timestamp
        final snapshot = await _firestore.collection('rooms').orderBy('room_id', descending: true).limit(1).get();
        if (snapshot.docs.isNotEmpty) {
          final maxId = int.tryParse(snapshot.docs.first.id) ?? 0;
          docId = (maxId + 1).toString();
        } else {
          docId = '1';
        }
      }
      
      final data = room.toJson();
      // Remove room_id from data as it's the document ID
      data.remove('room_id');
      
      // Add timestamps
      data['created_at'] = FieldValue.serverTimestamp();
      data['updated_at'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('rooms').doc(docId).set(data);
      
      // Fetch the created room to get server timestamps
      final createdDoc = await _firestore.collection('rooms').doc(docId).get();
      return RoomModel.fromJson(_docToRoomJson(createdDoc));
    } catch (e) {
      throw Exception('Failed to create room: $e');
    }
  }

  /// Update room
  Future<RoomModel> updateRoom(RoomModel room) async {
    try {
      if (room.roomId == null) {
        throw Exception('Room ID is required for update');
      }
      
      final data = room.toJson();
      // Remove room_id from data as it's the document ID
      data.remove('room_id');
      
      // Update timestamp
      data['updated_at'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('rooms').doc(room.roomId.toString()).update(data);
      
      // Fetch the updated room
      final updatedDoc = await _firestore.collection('rooms').doc(room.roomId.toString()).get();
      return RoomModel.fromJson(_docToRoomJson(updatedDoc));
    } catch (e) {
      throw Exception('Failed to update room: $e');
    }
  }

  /// Update room status
  Future<bool> updateRoomStatus(int roomId, String status) async {
    try {
      await _firestore.collection('rooms').doc(roomId.toString()).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      throw Exception('Failed to update room status: $e');
    }
  }

  /// Watch rooms in real-time
  Stream<List<RoomModel>> watchRooms() {
    return _firestore
        .collection('rooms')
        .orderBy('room_number')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RoomModel.fromJson(_docToRoomJson(doc));
      }).toList();
    });
  }

  /// Delete room
  Future<void> deleteRoom(int roomId) async {
    try {
      await _firestore.collection('rooms').doc(roomId.toString()).delete();
    } catch (e) {
      throw Exception('Failed to delete room: $e');
    }
  }
}

