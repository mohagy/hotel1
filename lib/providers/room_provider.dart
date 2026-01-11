/// Room Provider
/// 
/// Manages room state using Provider pattern

import 'package:flutter/foundation.dart';
import '../models/room_model.dart';
import '../services/room_service.dart';

class RoomProvider extends ChangeNotifier {
  final RoomService _roomService = RoomService();
  List<RoomModel> _rooms = [];
  bool _isLoading = false;
  String? _error;

  List<RoomModel> get rooms => _rooms;
  List<RoomModel> get availableRooms => _rooms.where((r) => r.isAvailable).toList();
  List<RoomModel> get occupiedRooms => _rooms.where((r) => r.isOccupied).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all rooms
  Future<void> loadRooms({Map<String, dynamic>? filters}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rooms = await _roomService.getRooms(filters: filters);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get available rooms for date range
  Future<List<RoomModel>> getAvailableRooms({
    required DateTime checkIn,
    required DateTime checkOut,
    String? roomType,
  }) async {
    try {
      return await _roomService.getAvailableRooms(
        checkIn: checkIn,
        checkOut: checkOut,
        roomType: roomType,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Update room status
  Future<bool> updateRoomStatus(int roomId, String status) async {
    try {
      final success = await _roomService.updateRoomStatus(roomId, status);
      if (success) {
        final index = _rooms.indexWhere((r) => r.roomId == roomId);
        if (index >= 0) {
          _rooms[index] = _rooms[index].copyWith(status: status);
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

