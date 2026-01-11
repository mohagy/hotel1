/// Guest Provider
/// 
/// Manages guest state using Provider pattern

import 'package:flutter/foundation.dart';
import '../models/guest_model.dart';
import '../services/guest_service.dart';

class GuestProvider extends ChangeNotifier {
  final GuestService _guestService = GuestService();
  List<GuestModel> _guests = [];
  bool _isLoading = false;
  String? _error;

  List<GuestModel> get guests => _guests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all guests
  Future<void> loadGuests({Map<String, dynamic>? filters}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _guests = await _guestService.getGuests(filters: filters);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create new guest
  Future<GuestModel?> createGuest(GuestModel guest) async {
    try {
      final createdGuest = await _guestService.createGuest(guest);
      _guests.insert(0, createdGuest);
      notifyListeners();
      return createdGuest;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update guest
  Future<bool> updateGuest(GuestModel guest) async {
    try {
      final updatedGuest = await _guestService.updateGuest(guest);
      final index = _guests.indexWhere((g) => g.guestId == guest.guestId);
      if (index >= 0) {
        _guests[index] = updatedGuest;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete guest
  Future<bool> deleteGuest(int guestId) async {
    try {
      final success = await _guestService.deleteGuest(guestId);
      if (success) {
        _guests.removeWhere((g) => g.guestId == guestId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Search guests
  Future<void> searchGuests(String query) async {
    if (query.isEmpty) {
      await loadGuests();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _guests = await _guestService.searchGuests(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}

