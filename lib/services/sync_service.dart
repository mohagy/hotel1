/// Sync Service
/// 
/// Handles synchronization between local storage and remote servers (MySQL/Firestore)

import 'dart:io';
import '../services/offline_storage_service.dart';
import '../services/guest_service.dart';
import '../services/room_service.dart';
import '../services/reservation_service.dart';
import '../services/billing_service.dart';
import '../services/pos_service.dart';
import '../services/firestore_service.dart';
import '../models/guest_model.dart';
import '../models/room_model.dart';
import '../models/reservation_model.dart';
import '../models/billing_model.dart';
import '../models/order_model.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

class SyncService {
  final GuestService _guestService = GuestService();
  final RoomService _roomService = RoomService();
  final ReservationService _reservationService = ReservationService();
  final BillingService _billingService = BillingService();
  final POSService _posService = POSService();
  final FirestoreService _firestoreService = FirestoreService();

  SyncStatus _status = SyncStatus.idle;
  String? _lastError;

  SyncStatus get status => _status;
  String? get lastError => _lastError;

  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Sync all data from remote to local
  Future<bool> syncFromRemote() async {
    if (!await isOnline()) {
      _lastError = 'Device is offline';
      return false;
    }

    _status = SyncStatus.syncing;

    try {
      // Sync Guests
      await _syncGuests();

      // Sync Rooms
      await _syncRooms();

      // Sync Reservations
      await _syncReservations();

      // Sync Billings
      await _syncBillings();

      _status = SyncStatus.success;
      return true;
    } catch (e) {
      _status = SyncStatus.error;
      _lastError = e.toString();
      return false;
    }
  }

  /// Sync pending queue operations to remote
  Future<bool> syncQueueToRemote() async {
    if (!await isOnline()) {
      _lastError = 'Device is offline';
      return false;
    }

    final queue = OfflineStorageService.getSyncQueue();
    if (queue.isEmpty) {
      return true;
    }

    _status = SyncStatus.syncing;

    try {
      int successCount = 0;
      int failCount = 0;

      for (var item in queue) {
        try {
          final success = await _processQueueItem(item);
          if (success) {
            await OfflineStorageService.removeFromSyncQueue(item['id'] as String);
            successCount++;
          } else {
            // Increment retry count
            final retryCount = (item['retryCount'] as int? ?? 0) + 1;
            if (retryCount < 3) {
              // Update retry count (would need to update the item in queue)
              item['retryCount'] = retryCount;
            } else {
              // Max retries reached, remove from queue
              await OfflineStorageService.removeFromSyncQueue(item['id'] as String);
              failCount++;
            }
          }
        } catch (e) {
          failCount++;
        }
      }

      _status = SyncStatus.success;
      return failCount == 0;
    } catch (e) {
      _status = SyncStatus.error;
      _lastError = e.toString();
      return false;
    }
  }

  /// Process a single queue item
  Future<bool> _processQueueItem(Map<String, dynamic> item) async {
    final operation = item['operation'] as String;
    final entityType = item['entityType'] as String;
    final data = item['data'] as Map<String, dynamic>;

    try {
      switch (entityType) {
        case 'guest':
          return await _syncGuestOperation(operation, data);
        case 'room':
          return await _syncRoomOperation(operation, data);
        case 'reservation':
          return await _syncReservationOperation(operation, data);
        case 'billing':
          return await _syncBillingOperation(operation, data);
        case 'order':
          return await _syncOrderOperation(operation, data);
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // Guest Sync Operations
  // ============================================================================

  Future<void> _syncGuests() async {
    try {
      final guests = await _guestService.getGuests();
      await OfflineStorageService.saveGuests(guests);
      await OfflineStorageService.saveLastSync('guests', DateTime.now());
    } catch (e) {
      // Continue with other syncs even if one fails
    }
  }

  Future<bool> _syncGuestOperation(String operation, Map<String, dynamic> data) async {
    try {
      switch (operation) {
        case 'create':
          final guest = GuestModel.fromJson(data);
          await _guestService.createGuest(guest);
          return true;
        case 'update':
          final guest = GuestModel.fromJson(data);
          await _guestService.updateGuest(guest);
          return true;
        case 'delete':
          final guestId = data['guest_id'] as int? ?? data['guestId'] as int?;
          if (guestId != null) {
            await _guestService.deleteGuest(guestId);
            return true;
          }
          return false;
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // Room Sync Operations
  // ============================================================================

  Future<void> _syncRooms() async {
    try {
      final rooms = await _roomService.getRooms();
      await OfflineStorageService.saveRooms(rooms);
      await OfflineStorageService.saveLastSync('rooms', DateTime.now());
    } catch (e) {
      // Continue with other syncs even if one fails
    }
  }

  Future<bool> _syncRoomOperation(String operation, Map<String, dynamic> data) async {
    try {
      switch (operation) {
        case 'create':
          final room = RoomModel.fromJson(data);
          await _roomService.createRoom(room);
          return true;
        case 'update':
          final room = RoomModel.fromJson(data);
          await _roomService.updateRoom(room);
          return true;
        case 'delete':
          // Rooms are not deleted, just status updated
          // Skip delete operation for rooms
          return false;
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // Reservation Sync Operations
  // ============================================================================

  Future<void> _syncReservations() async {
    try {
      final reservations = await _reservationService.getReservations();
      await OfflineStorageService.saveReservations(reservations);
      await OfflineStorageService.saveLastSync('reservations', DateTime.now());
    } catch (e) {
      // Continue with other syncs even if one fails
    }
  }

  Future<bool> _syncReservationOperation(String operation, Map<String, dynamic> data) async {
    try {
      switch (operation) {
        case 'create':
          final reservation = ReservationModel.fromJson(data);
          await _reservationService.createReservation(reservation);
          return true;
        case 'update':
          final reservation = ReservationModel.fromJson(data);
          await _reservationService.updateReservation(reservation);
          return true;
        case 'delete':
          // Reservations are cancelled, not deleted
          // Update status to cancelled instead
          final reservationId = data['reservation_id'] as int? ?? data['reservationId'] as int?;
          if (reservationId != null) {
            try {
              // Get reservation and update status
              final reservation = await _reservationService.getReservationById(reservationId);
              if (reservation != null) {
                final cancelledReservation = reservation.copyWith(status: 'cancelled');
                await _reservationService.updateReservation(cancelledReservation);
                return true;
              }
            } catch (e) {
              return false;
            }
          }
          return false;
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // Billing Sync Operations
  // ============================================================================

  Future<void> _syncBillings() async {
    try {
      final billings = await _billingService.getInvoices();
      await OfflineStorageService.saveBillings(billings);
      await OfflineStorageService.saveLastSync('billings', DateTime.now());
    } catch (e) {
      // Continue with other syncs even if one fails
    }
  }

  Future<bool> _syncBillingOperation(String operation, Map<String, dynamic> data) async {
    try {
      switch (operation) {
        case 'create':
          final billing = BillingModel.fromJson(data);
          await _billingService.createInvoice(billing);
          return true;
        case 'update':
          final billing = BillingModel.fromJson(data);
          await _billingService.updateInvoice(billing);
          return true;
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // Order Sync Operations
  // ============================================================================

  Future<bool> _syncOrderOperation(String operation, Map<String, dynamic> data) async {
    try {
      if (operation == 'create') {
        final order = OrderModel.fromJson(data);
        await _posService.saveOrder(order);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // Manual Sync Methods
  // ============================================================================

  /// Sync a specific entity type
  Future<bool> syncEntityType(String entityType) async {
    if (!await isOnline()) {
      _lastError = 'Device is offline';
      return false;
    }

    try {
      switch (entityType) {
        case 'guests':
          await _syncGuests();
          break;
        case 'rooms':
          await _syncRooms();
          break;
        case 'reservations':
          await _syncReservations();
          break;
        case 'billings':
          await _syncBillings();
          break;
        default:
          return false;
      }
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    final queue = OfflineStorageService.getSyncQueue();
    return {
      'pendingOperations': queue.length,
      'lastSync': {
        'guests': OfflineStorageService.getLastSync('guests'),
        'rooms': OfflineStorageService.getLastSync('rooms'),
        'reservations': OfflineStorageService.getLastSync('reservations'),
        'billings': OfflineStorageService.getLastSync('billings'),
      },
      'status': _status.toString(),
      'lastError': _lastError,
    };
  }
}

