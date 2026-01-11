/// Reservation Service
/// 
/// Handles reservation-related operations with Firestore and offline support

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reservation_model.dart';
import 'api_service.dart';
import 'offline_storage_service.dart';
import '../config/api_config.dart';

class ReservationService extends ApiService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  Future<bool> _isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get all reservations (with offline support)
  Future<List<ReservationModel>> getReservations({Map<String, dynamic>? filters}) async {
    try {
      if (await _isOnline()) {
        try {
          final response = await get(
            '${ApiConfig.reservationsEndpoint}read.php',
            queryParameters: filters,
          );
          
          List<ReservationModel> reservations = [];
          if (response.data is List) {
            reservations = ReservationModel.fromJsonList(response.data as List);
          } else if (response.data is Map && response.data['data'] != null) {
            reservations = ReservationModel.fromJsonList(response.data['data'] as List);
          }
          
          if (reservations.isNotEmpty) {
            await OfflineStorageService.saveReservations(reservations);
            await OfflineStorageService.saveLastSync('reservations', DateTime.now());
          }
          
          return reservations;
        } catch (e) {
          debugPrint('API fetch failed, using local storage: $e');
        }
      }
      
      return OfflineStorageService.getReservations();
    } catch (e) {
      return OfflineStorageService.getReservations();
    }
  }

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

  Map<String, dynamic> _docToReservationJson(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final jsonData = <String, dynamic>{'reservation_id': int.tryParse(doc.id) ?? 0};
    
    data.forEach((key, value) {
      if (value is Timestamp) {
        jsonData[key] = value.toDate().toIso8601String().split('T')[0];
      } else {
        jsonData[key] = value;
      }
    });
    
    // Ensure balance_due is set (default to total_price if not set)
    if (!jsonData.containsKey('balance_due') && jsonData.containsKey('total_price')) {
      jsonData['balance_due'] = jsonData['total_price'];
    }
    
    return jsonData;
  }

  /// Get reservations for payment from Firestore (with offline support)
  Future<List<ReservationModel>> getReservationsForPayment() async {
    try {
      // Try Firestore first
      try {
        // Fetch reservations that are not cancelled and have balance due or total price > 0
        // Use orderBy only (no whereIn) to avoid composite index requirement, filter in memory
        final snapshot = await _firestore
            .collection('reservations')
            .orderBy('check_in_date', descending: true)
            .limit(100)
            .get();

        final reservations = <ReservationModel>[];
        
        // Filter by status in memory to avoid composite index
        final filteredDocs = snapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final status = data['status'] as String?;
          return status == 'reserved' || status == 'checked_in';
        }).toList();
        
        for (var doc in filteredDocs) {
          try {
            final resData = _docToReservationJson(doc);
            
            // Get guest data
            final guestId = resData['guest_id'];
            if (guestId != null) {
              final guestDoc = await _firestore.collection('guests').doc(guestId.toString()).get();
              if (guestDoc.exists) {
                final guestData = guestDoc.data() as Map<String, dynamic>? ?? {};
                resData['guest_name'] = '${guestData['first_name'] ?? ''} ${guestData['last_name'] ?? ''}'.trim();
                resData['guest_email'] = guestData['email'];
                resData['guest_phone'] = guestData['phone'];
              }
            }
            
            // Get room data
            final roomId = resData['room_id'];
            if (roomId != null) {
              final roomDoc = await _firestore.collection('rooms').doc(roomId.toString()).get();
              if (roomDoc.exists) {
                final roomData = roomDoc.data() as Map<String, dynamic>? ?? {};
                resData['room_number'] = roomData['room_number'];
                resData['room_type'] = roomData['room_type'];
              }
            }
            
            // Set balance_due to total_price if not set (no billing yet)
            if (!resData.containsKey('balance_due') || resData['balance_due'] == null) {
              resData['balance_due'] = resData['total_price'] ?? 0.0;
            }
            
            // Generate reservation_number if not present
            if (!resData.containsKey('reservation_number') && resData['reservation_id'] != null) {
              final resId = resData['reservation_id'].toString();
              resData['reservation_number'] = 'RES-${resId.padLeft(4, '0')}';
            }
            
            // Only include if balance due > 0
            final balanceDue = (resData['balance_due'] as num?)?.toDouble() ?? 0.0;
            final totalPrice = (resData['total_price'] as num?)?.toDouble() ?? 0.0;
            
            if (balanceDue > 0 || totalPrice > 0) {
              final reservation = ReservationModel.fromJson(resData);
              reservations.add(reservation);
            }
          } catch (e) {
            debugPrint('Error processing reservation ${doc.id}: $e');
          }
        }
        
        if (reservations.isNotEmpty) {
          await OfflineStorageService.saveReservations(reservations);
        }
        
        return reservations;
      } catch (e) {
        debugPrint('Firestore fetch failed, trying PHP API: $e');
        
        // Fallback to PHP API
        if (await _isOnline()) {
          try {
            final response = await get('${ApiConfig.reservationsEndpoint}get-for-payment.php');
            
            List<ReservationModel> reservations = [];
            if (response.data is Map && response.data['success'] == true) {
              if (response.data['reservations'] != null) {
                reservations = ReservationModel.fromJsonList(response.data['reservations'] as List);
              } else if (response.data['data'] != null) {
                reservations = ReservationModel.fromJsonList(response.data['data'] as List);
              }
            } else if (response.data is List) {
              reservations = ReservationModel.fromJsonList(response.data as List);
            }
            
            if (reservations.isNotEmpty) {
              await OfflineStorageService.saveReservations(reservations);
            }
            
            return reservations;
          } catch (e) {
            debugPrint('API fetch failed, using local storage: $e');
          }
        }
      }
      
      // Offline mode: filter reservations for payment (not cancelled, has balance or price)
      final allReservations = OfflineStorageService.getReservations();
      return allReservations.where((reservation) {
        return reservation.status != 'cancelled' &&
               (reservation.balanceDue != null && reservation.balanceDue! > 0 ||
                reservation.totalPrice != null && reservation.totalPrice! > 0);
      }).toList();
    } catch (e) {
      debugPrint('Error in getReservationsForPayment: $e');
      // Final fallback to local storage
      final allReservations = OfflineStorageService.getReservations();
      return allReservations.where((reservation) {
        return reservation.status != 'cancelled' &&
               (reservation.balanceDue != null && reservation.balanceDue! > 0 ||
                reservation.totalPrice != null && reservation.totalPrice! > 0);
      }).toList();
    }
  }

  /// Get reservation by ID (with offline support)
  Future<ReservationModel?> getReservationById(int reservationId) async {
    try {
      if (await _isOnline()) {
        try {
          final response = await get(
            '${ApiConfig.reservationsEndpoint}read.php',
            queryParameters: {'reservation_id': reservationId},
          );
          
          ReservationModel? reservation;
          if (response.data is List && (response.data as List).isNotEmpty) {
            reservation = ReservationModel.fromJson(response.data[0] as Map<String, dynamic>);
          } else if (response.data is Map && response.data['data'] != null) {
            reservation = ReservationModel.fromJson(response.data['data'] as Map<String, dynamic>);
          } else if (response.data is Map && response.data['reservation_id'] != null) {
            reservation = ReservationModel.fromJson(response.data as Map<String, dynamic>);
          }
          
          if (reservation != null) {
            await OfflineStorageService.saveReservation(reservation);
          }
          
          return reservation;
        } catch (e) {
          debugPrint('API fetch failed, using local storage: $e');
        }
      }
      
      // Try to find in local storage
      return OfflineStorageService.getReservationById(reservationId);
    } catch (e) {
      // Final fallback to local storage
      return OfflineStorageService.getReservationById(reservationId);
    }
  }

  /// Create new reservation (with offline support)
  Future<ReservationModel> createReservation(ReservationModel reservation) async {
    try {
      if (await _isOnline()) {
        try {
          final response = await post(
            '${ApiConfig.reservationsEndpoint}create.php',
            data: reservation.toJson(),
          );
          
          if (response.data is Map) {
            final createdReservation = ReservationModel.fromJson(response.data as Map<String, dynamic>);
            await OfflineStorageService.saveReservation(createdReservation);
            return createdReservation;
          }
          throw Exception('Invalid response format');
        } catch (e) {
          debugPrint('API create failed, adding to sync queue: $e');
        }
      }
      
      // Offline mode: save locally and queue
      final tempId = reservation.reservationId != null && reservation.reservationId! < 0 
          ? reservation.reservationId 
          : -(DateTime.now().millisecondsSinceEpoch);
      final tempReservation = reservation.copyWith(reservationId: tempId);
      
      await OfflineStorageService.saveReservation(tempReservation);
      await OfflineStorageService.addToSyncQueue(
        operation: 'create',
        entityType: 'reservation',
        data: tempReservation.toJson(),
        entityId: tempReservation.reservationId.toString(),
      );
      
      return tempReservation;
    } catch (e) {
      throw Exception('Failed to create reservation: $e');
    }
  }

  /// Create reservation from POS (with offline support)
  Future<ReservationModel> createReservationFromPos(Map<String, dynamic> data) async {
    try {
      if (await _isOnline()) {
        try {
          final response = await post(
            '${ApiConfig.reservationsEndpoint}create-from-pos.php',
            data: data,
          );
          
          if (response.data is Map && response.data['success'] == true) {
            ReservationModel createdReservation;
            if (response.data['reservation'] != null) {
              createdReservation = ReservationModel.fromJson(response.data['reservation'] as Map<String, dynamic>);
            } else if (response.data['data'] != null) {
              createdReservation = ReservationModel.fromJson(response.data['data'] as Map<String, dynamic>);
            } else {
              throw Exception('Invalid response format');
            }
            
            await OfflineStorageService.saveReservation(createdReservation);
            return createdReservation;
          }
          throw Exception(response.data['message'] ?? 'Invalid response format');
        } catch (e) {
          debugPrint('API create failed, adding to sync queue: $e');
        }
      }
      
      // Offline mode: construct reservation from POS data and save locally
      // POS data has: first_name, last_name, email, phone, room_id, check_in_date, check_out_date
      final tempId = -(DateTime.now().millisecondsSinceEpoch);
      
      // Try to find existing guest by email, or use temporary guest ID
      int tempGuestId = -(DateTime.now().millisecondsSinceEpoch ~/ 1000);
      try {
        final allGuests = OfflineStorageService.getGuests();
        final matchingGuests = allGuests.where((g) => g.email == data['email']).toList();
        if (matchingGuests.isNotEmpty && matchingGuests.first.guestId != null) {
          tempGuestId = matchingGuests.first.guestId!;
        }
      } catch (e) {
        // Use temp guest ID
      }
      
      // Construct reservation from POS data
      final reservation = ReservationModel(
        reservationId: tempId,
        guestId: tempGuestId,
        roomId: (data['room_id'] as num).toInt(),
        checkInDate: DateTime.parse(data['check_in_date'] as String),
        checkOutDate: DateTime.parse(data['check_out_date'] as String),
        status: 'reserved',
        totalPrice: data['custom_price'] != null 
            ? (data['custom_price'] as num).toDouble()
            : null,
        numberOfNights: null, // Will be calculated
        createdAt: DateTime.now(),
        guestName: '${data['first_name']} ${data['last_name']}',
        guestEmail: data['email'] as String?,
        guestPhone: data['phone'] as String?,
      );
      
      // Calculate nights if dates are valid
      final calculatedNights = reservation.checkOutDate.difference(reservation.checkInDate).inDays;
      final finalReservation = reservation.copyWith(numberOfNights: calculatedNights);
      
      await OfflineStorageService.saveReservation(finalReservation);
      
      // Store original POS data in sync queue (not the reservation JSON, as API expects POS format)
      await OfflineStorageService.addToSyncQueue(
        operation: 'create',
        entityType: 'reservation_pos',
        data: data, // Store original POS data format
        entityId: tempId.toString(),
      );
      
      return finalReservation;
    } catch (e) {
      throw Exception('Failed to create reservation from POS: $e');
    }
  }

  /// Update reservation (with offline support)
  Future<ReservationModel> updateReservation(ReservationModel reservation) async {
    try {
      if (await _isOnline()) {
        try {
          final response = await put(
            '${ApiConfig.reservationsEndpoint}update.php',
            data: reservation.toJson(),
          );
          
          if (response.data is Map) {
            final updatedReservation = ReservationModel.fromJson(response.data as Map<String, dynamic>);
            await OfflineStorageService.saveReservation(updatedReservation);
            return updatedReservation;
          }
          throw Exception('Invalid response format');
        } catch (e) {
          debugPrint('API update failed, adding to sync queue: $e');
        }
      }
      
      // Offline mode: update locally and queue
      await OfflineStorageService.saveReservation(reservation);
      await OfflineStorageService.addToSyncQueue(
        operation: 'update',
        entityType: 'reservation',
        data: reservation.toJson(),
        entityId: reservation.reservationId.toString(),
      );
      
      return reservation;
    } catch (e) {
      throw Exception('Failed to update reservation: $e');
    }
  }

  /// Process payment for reservation (with offline support)
  Future<bool> processPayment(int reservationId, Map<String, dynamic> paymentData) async {
    try {
      if (await _isOnline()) {
        try {
          final response = await post(
            '${ApiConfig.reservationsEndpoint}process-payment.php',
            data: {
              'reservation_id': reservationId,
              ...paymentData,
            },
          );
          
          final success = response.data['success'] == true || response.statusCode == 200;
          if (success) {
            // Refresh reservation from server if possible
            final updatedReservation = await getReservationById(reservationId);
            if (updatedReservation != null) {
              await OfflineStorageService.saveReservation(updatedReservation);
            }
          }
          return success;
        } catch (e) {
          debugPrint('API payment failed, adding to sync queue: $e');
        }
      }
      
      // Offline mode: queue payment operation
      final reservation = OfflineStorageService.getReservationById(reservationId);
      if (reservation != null) {
        await OfflineStorageService.addToSyncQueue(
          operation: 'update',
          entityType: 'reservation_payment',
          data: {
            'reservation_id': reservationId,
            ...paymentData,
          },
          entityId: reservationId.toString(),
        );
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  /// Check in reservation (with offline support)
  Future<bool> checkIn(int reservationId) async {
    try {
      if (await _isOnline()) {
        try {
          final response = await put(
            '${ApiConfig.reservationsEndpoint}check-in.php',
            data: {'reservation_id': reservationId},
          );
          
          final success = response.data['success'] == true || response.statusCode == 200;
          if (success) {
            // Update local reservation status
            final reservation = OfflineStorageService.getReservationById(reservationId);
            if (reservation != null) {
              final updatedReservation = reservation.copyWith(
                status: 'checked_in',
                updatedAt: DateTime.now(),
              );
              await OfflineStorageService.saveReservation(updatedReservation);
            }
          }
          return success;
        } catch (e) {
          debugPrint('API check-in failed, adding to sync queue: $e');
        }
      }
      
      // Offline mode: update locally and queue
      final reservation = OfflineStorageService.getReservationById(reservationId);
      if (reservation != null) {
        final updatedReservation = reservation.copyWith(
          status: 'checked_in',
          updatedAt: DateTime.now(),
        );
        await OfflineStorageService.saveReservation(updatedReservation);
        await OfflineStorageService.addToSyncQueue(
          operation: 'update',
          entityType: 'reservation',
          data: updatedReservation.toJson(),
          entityId: reservationId.toString(),
        );
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check in: $e');
    }
  }

  /// Check out reservation (with offline support)
  Future<bool> checkOut(int reservationId) async {
    try {
      if (await _isOnline()) {
        try {
          final response = await put(
            '${ApiConfig.reservationsEndpoint}check-out.php',
            data: {'reservation_id': reservationId},
          );
          
          final success = response.data['success'] == true || response.statusCode == 200;
          if (success && response.data['data'] != null) {
            // Update local reservation with server response
            final updatedReservation = ReservationModel.fromJson(response.data['data'] as Map<String, dynamic>);
            await OfflineStorageService.saveReservation(updatedReservation);
          } else if (success) {
            // Fallback: update local reservation status
            final reservation = OfflineStorageService.getReservationById(reservationId);
            if (reservation != null) {
              final updatedReservation = reservation.copyWith(
                status: 'checked_out',
                updatedAt: DateTime.now(),
              );
              await OfflineStorageService.saveReservation(updatedReservation);
            }
          }
          return success;
        } catch (e) {
          debugPrint('API check-out failed, adding to sync queue: $e');
        }
      }
      
      // Offline mode: update locally and queue
      final reservation = OfflineStorageService.getReservationById(reservationId);
      if (reservation != null) {
        final updatedReservation = reservation.copyWith(
          status: 'checked_out',
          updatedAt: DateTime.now(),
        );
        await OfflineStorageService.saveReservation(updatedReservation);
        await OfflineStorageService.addToSyncQueue(
          operation: 'update',
          entityType: 'reservation',
          data: updatedReservation.toJson(),
          entityId: reservationId.toString(),
        );
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check out: $e');
    }
  }
}

