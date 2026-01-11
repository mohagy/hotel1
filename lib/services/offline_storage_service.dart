/// Offline Storage Service
/// 
/// Handles local data storage using Hive for offline support

import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import '../models/guest_model.dart';
import '../models/room_model.dart';
import '../models/reservation_model.dart';
import '../models/billing_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';

class OfflineStorageService {
  static const String _guestsBoxName = 'guests';
  static const String _roomsBoxName = 'rooms';
  static const String _reservationsBoxName = 'reservations';
  static const String _billingsBoxName = 'billings';
  static const String _ordersBoxName = 'orders';
  static const String _productsBoxName = 'products';
  static const String _categoriesBoxName = 'categories';
  static const String _syncQueueBoxName = 'sync_queue';
  static const String _lastSyncBoxName = 'last_sync';

  static bool _initialized = false;

  /// Initialize Hive and open all boxes
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();

      // Open boxes (Hive will create them if they don't exist)
      await Hive.openBox(_guestsBoxName);
      await Hive.openBox(_roomsBoxName);
      await Hive.openBox(_reservationsBoxName);
      await Hive.openBox(_billingsBoxName);
      await Hive.openBox(_ordersBoxName);
      await Hive.openBox(_productsBoxName);
      await Hive.openBox(_categoriesBoxName);
      await Hive.openBox(_syncQueueBoxName);
      await Hive.openBox(_lastSyncBoxName);

      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize offline storage: $e');
    }
  }

  /// Check if storage is initialized
  static bool get isInitialized => _initialized;

  // ============================================================================
  // Guests Storage
  // ============================================================================

  /// Save guests to local storage
  static Future<void> saveGuests(List<GuestModel> guests) async {
    final box = Hive.box(_guestsBoxName);
    final Map<String, dynamic> guestsMap = {};
    for (var guest in guests) {
      guestsMap[guest.guestId.toString()] = guest.toJson();
    }
    await box.putAll(guestsMap);
  }

  /// Get all guests from local storage
  static List<GuestModel> getGuests() {
    final box = Hive.box(_guestsBoxName);
    final List<GuestModel> guests = [];
    for (var key in box.keys) {
      try {
        final guestData = box.get(key) as Map<String, dynamic>?;
        if (guestData != null) {
          guests.add(GuestModel.fromJson(guestData));
        }
      } catch (e) {
        // Skip invalid entries
      }
    }
    return guests;
  }

  /// Get guest by ID from local storage
  static GuestModel? getGuestById(int guestId) {
    final box = Hive.box(_guestsBoxName);
    final guestData = box.get(guestId.toString()) as Map<String, dynamic>?;
    return guestData != null ? GuestModel.fromJson(guestData) : null;
  }

  /// Save single guest to local storage
  static Future<void> saveGuest(GuestModel guest) async {
    final box = Hive.box(_guestsBoxName);
    await box.put(guest.guestId.toString(), guest.toJson());
  }

  /// Delete guest from local storage
  static Future<void> deleteGuest(int guestId) async {
    final box = Hive.box(_guestsBoxName);
    await box.delete(guestId.toString());
  }

  // ============================================================================
  // Rooms Storage
  // ============================================================================

  static Future<void> saveRooms(List<RoomModel> rooms) async {
    final box = Hive.box(_roomsBoxName);
    final Map<String, dynamic> roomsMap = {};
    for (var room in rooms) {
      roomsMap[room.roomId.toString()] = room.toJson();
    }
    await box.putAll(roomsMap);
  }

  static List<RoomModel> getRooms() {
    final box = Hive.box(_roomsBoxName);
    final List<RoomModel> rooms = [];
    for (var key in box.keys) {
      try {
        final roomData = box.get(key) as Map<String, dynamic>?;
        if (roomData != null) {
          rooms.add(RoomModel.fromJson(roomData));
        }
      } catch (e) {
        // Skip invalid entries
      }
    }
    return rooms;
  }

  static RoomModel? getRoomById(int roomId) {
    final box = Hive.box(_roomsBoxName);
    final roomData = box.get(roomId.toString()) as Map<String, dynamic>?;
    return roomData != null ? RoomModel.fromJson(roomData) : null;
  }

  static Future<void> saveRoom(RoomModel room) async {
    final box = Hive.box(_roomsBoxName);
    await box.put(room.roomId.toString(), room.toJson());
  }

  static Future<void> deleteRoom(int roomId) async {
    final box = Hive.box(_roomsBoxName);
    await box.delete(roomId.toString());
  }

  // ============================================================================
  // Reservations Storage
  // ============================================================================

  static Future<void> saveReservations(List<ReservationModel> reservations) async {
    final box = Hive.box(_reservationsBoxName);
    final Map<String, dynamic> reservationsMap = {};
    for (var reservation in reservations) {
      reservationsMap[reservation.reservationId.toString()] = reservation.toJson();
    }
    await box.putAll(reservationsMap);
  }

  static List<ReservationModel> getReservations() {
    final box = Hive.box(_reservationsBoxName);
    final List<ReservationModel> reservations = [];
    for (var key in box.keys) {
      try {
        final reservationData = box.get(key) as Map<String, dynamic>?;
        if (reservationData != null) {
          reservations.add(ReservationModel.fromJson(reservationData));
        }
      } catch (e) {
        // Skip invalid entries
      }
    }
    return reservations;
  }

  static ReservationModel? getReservationById(int reservationId) {
    final box = Hive.box(_reservationsBoxName);
    final reservationData = box.get(reservationId.toString()) as Map<String, dynamic>?;
    return reservationData != null ? ReservationModel.fromJson(reservationData) : null;
  }

  static Future<void> saveReservation(ReservationModel reservation) async {
    final box = Hive.box(_reservationsBoxName);
    await box.put(reservation.reservationId.toString(), reservation.toJson());
  }

  static Future<void> deleteReservation(int reservationId) async {
    final box = Hive.box(_reservationsBoxName);
    await box.delete(reservationId.toString());
  }

  // ============================================================================
  // Billing Storage
  // ============================================================================

  static Future<void> saveBillings(List<BillingModel> billings) async {
    final box = Hive.box(_billingsBoxName);
    final Map<String, dynamic> billingsMap = {};
    for (var billing in billings) {
      if (billing.billingId != null) {
        billingsMap[billing.billingId.toString()] = billing.toJson();
      }
    }
    await box.putAll(billingsMap);
  }

  static List<BillingModel> getBillings() {
    final box = Hive.box(_billingsBoxName);
    final List<BillingModel> billings = [];
    for (var key in box.keys) {
      try {
        final billingData = box.get(key) as Map<String, dynamic>?;
        if (billingData != null) {
          billings.add(BillingModel.fromJson(billingData));
        }
      } catch (e) {
        // Skip invalid entries
      }
    }
    return billings;
  }

  static Future<void> saveBilling(BillingModel billing) async {
    if (billing.billingId == null) return;
    final box = Hive.box(_billingsBoxName);
    await box.put(billing.billingId.toString(), billing.toJson());
  }

  // ============================================================================
  // Orders Storage
  // ============================================================================

  static Future<void> saveOrders(List<OrderModel> orders) async {
    final box = Hive.box(_ordersBoxName);
    final Map<String, dynamic> ordersMap = {};
    for (var order in orders) {
      if (order.id != null) {
        ordersMap[order.id.toString()] = order.toJson();
      }
    }
    await box.putAll(ordersMap);
  }

  static List<OrderModel> getOrders() {
    final box = Hive.box(_ordersBoxName);
    final List<OrderModel> orders = [];
    for (var key in box.keys) {
      try {
        final orderData = box.get(key) as Map<String, dynamic>?;
        if (orderData != null) {
          orders.add(OrderModel.fromJson(orderData));
        }
      } catch (e) {
        // Skip invalid entries
      }
    }
    return orders;
  }

  static Future<void> saveOrder(OrderModel order) async {
    if (order.id == null) return;
    final box = Hive.box(_ordersBoxName);
    await box.put(order.id.toString(), order.toJson());
  }

  // ============================================================================
  // Products Storage
  // ============================================================================

  static Future<void> saveProducts(List<ProductModel> products) async {
    final box = Hive.box(_productsBoxName);
    final Map<String, dynamic> productsMap = {};
    for (var product in products) {
      final key = product.id?.toString() ?? '';
      if (key.isNotEmpty) {
        productsMap[key] = product.toJson();
      }
    }
    await box.putAll(productsMap);
  }

  static List<ProductModel> getProducts() {
    final box = Hive.box(_productsBoxName);
    final List<ProductModel> products = [];
    for (var key in box.keys) {
      try {
        final productData = box.get(key) as Map<String, dynamic>?;
        if (productData != null) {
          products.add(ProductModel.fromJson(productData));
        }
      } catch (e) {
        // Skip invalid entries
      }
    }
    return products;
  }

  // ============================================================================
  // Categories Storage
  // ============================================================================

  static Future<void> saveCategories(List<Map<String, dynamic>> categories, {String? mode}) async {
    final box = Hive.box(_categoriesBoxName);
    final key = mode ?? 'all';
    await box.put(key, jsonEncode(categories));
  }

  static List<Map<String, dynamic>> getCategories({String? mode}) {
    final box = Hive.box(_categoriesBoxName);
    final key = mode ?? 'all';
    try {
      final categoriesJson = box.get(key) as String?;
      if (categoriesJson != null) {
        final decoded = jsonDecode(categoriesJson) as List;
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // Return empty list on error
    }
    return [];
  }

  // ============================================================================
  // Orders Helpers
  // ============================================================================

  static OrderModel? getOrderById(int orderId) {
    final box = Hive.box(_ordersBoxName);
    final orderData = box.get(orderId.toString()) as Map<String, dynamic>?;
    return orderData != null ? OrderModel.fromJson(orderData) : null;
  }

  static List<OrderModel> getHoldBills() {
    final allOrders = getOrders();
    // Filter orders with status 'hold' or similar
    return allOrders.where((order) {
      return order.status?.toLowerCase() == 'hold' || 
             order.status?.toLowerCase() == 'on_hold' ||
             (order.id != null && order.id! < 0); // Temporary orders are also considered held
    }).toList();
  }

  // ============================================================================
  // Sync Queue Management
  // ============================================================================

  /// Add operation to sync queue
  static Future<void> addToSyncQueue({
    required String operation, // 'create', 'update', 'delete'
    required String entityType, // 'guest', 'room', 'reservation', etc.
    required Map<String, dynamic> data,
    String? entityId,
  }) async {
    final box = Hive.box(_syncQueueBoxName);
    final queueItem = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'operation': operation,
      'entityType': entityType,
      'data': data,
      'entityId': entityId,
      'createdAt': DateTime.now().toIso8601String(),
      'retryCount': 0,
    };
    await box.add(jsonEncode(queueItem));
  }

  /// Get all queued sync operations
  static List<Map<String, dynamic>> getSyncQueue() {
    final box = Hive.box(_syncQueueBoxName);
    final List<Map<String, dynamic>> queue = [];
    for (var key in box.keys) {
      try {
        final itemJson = box.get(key) as String?;
        if (itemJson != null) {
          queue.add(jsonDecode(itemJson) as Map<String, dynamic>);
        }
      } catch (e) {
        // Skip invalid entries
      }
    }
    // Sort by creation time (oldest first)
    queue.sort((a, b) {
      final aTime = DateTime.parse(a['createdAt'] as String);
      final bTime = DateTime.parse(b['createdAt'] as String);
      return aTime.compareTo(bTime);
    });
    return queue;
  }

  /// Remove item from sync queue
  static Future<void> removeFromSyncQueue(String queueId) async {
    final box = Hive.box(_syncQueueBoxName);
    // Find and delete the item
    for (var key in box.keys) {
      try {
        final itemJson = box.get(key) as String?;
        if (itemJson != null) {
          final item = jsonDecode(itemJson) as Map<String, dynamic>;
          if (item['id'] == queueId) {
            await box.delete(key);
            break;
          }
        }
      } catch (e) {
        // Skip invalid entries
      }
    }
  }

  /// Clear sync queue
  static Future<void> clearSyncQueue() async {
    final box = Hive.box(_syncQueueBoxName);
    await box.clear();
  }

  // ============================================================================
  // Last Sync Timestamps
  // ============================================================================

  /// Save last sync timestamp for an entity type
  static Future<void> saveLastSync(String entityType, DateTime timestamp) async {
    final box = Hive.box(_lastSyncBoxName);
    await box.put(entityType, timestamp.toIso8601String());
  }

  /// Get last sync timestamp for an entity type
  static DateTime? getLastSync(String entityType) {
    final box = Hive.box(_lastSyncBoxName);
    final timestampStr = box.get(entityType) as String?;
    if (timestampStr != null) {
      try {
        return DateTime.parse(timestampStr);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // ============================================================================
  // Clear All Data
  // ============================================================================

  /// Clear all local data (use with caution)
  static Future<void> clearAll() async {
    final boxes = [
      _guestsBoxName,
      _roomsBoxName,
      _reservationsBoxName,
      _billingsBoxName,
      _ordersBoxName,
      _productsBoxName,
      _categoriesBoxName,
      _syncQueueBoxName,
      _lastSyncBoxName,
    ];
    for (var boxName in boxes) {
      final box = Hive.box(boxName);
      await box.clear();
    }
  }

  /// Close all boxes (typically called on app shutdown)
  static Future<void> close() async {
    await Hive.close();
    _initialized = false;
  }
}

