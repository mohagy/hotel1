/// Reservation Provider
/// 
/// Manages reservation state using Provider pattern

import 'package:flutter/foundation.dart';
import '../models/reservation_model.dart';
import '../services/reservation_service.dart';

class ReservationProvider extends ChangeNotifier {
  final ReservationService _reservationService = ReservationService();
  List<ReservationModel> _reservations = [];
  List<ReservationModel> _reservationsForPayment = [];
  bool _isLoading = false;
  String? _error;

  List<ReservationModel> get reservations => _reservations;
  List<ReservationModel> get reservationsForPayment => _reservationsForPayment;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all reservations
  Future<void> loadReservations({Map<String, dynamic>? filters}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reservations = await _reservationService.getReservations(filters: filters);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load reservations for payment
  Future<void> loadReservationsForPayment() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reservationsForPayment = await _reservationService.getReservationsForPayment();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create reservation
  Future<ReservationModel?> createReservation(ReservationModel reservation) async {
    try {
      final createdReservation = await _reservationService.createReservation(reservation);
      _reservations.insert(0, createdReservation);
      notifyListeners();
      return createdReservation;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Create reservation from POS
  Future<ReservationModel?> createReservationFromPos(Map<String, dynamic> data) async {
    try {
      final reservation = await _reservationService.createReservationFromPos(data);
      _reservations.insert(0, reservation);
      _reservationsForPayment.insert(0, reservation);
      notifyListeners();
      return reservation;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Process payment
  Future<bool> processPayment(int reservationId, Map<String, dynamic> paymentData) async {
    try {
      final success = await _reservationService.processPayment(reservationId, paymentData);
      if (success) {
        await loadReservationsForPayment();
        await loadReservations();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Check in
  Future<bool> checkIn(int reservationId) async {
    try {
      final success = await _reservationService.checkIn(reservationId);
      if (success) {
        await loadReservations();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Check out
  Future<bool> checkOut(int reservationId) async {
    try {
      final success = await _reservationService.checkOut(reservationId);
      if (success) {
        await loadReservations();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

