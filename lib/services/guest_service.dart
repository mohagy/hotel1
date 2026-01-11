/// Guest Service
/// 
/// Handles guest-related API operations with offline support

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/guest_model.dart';
import 'api_service.dart';
import 'offline_storage_service.dart';
import '../config/api_config.dart';

class GuestService extends ApiService {
  /// Check if device is online
  Future<bool> _isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get all guests (with offline support)
  Future<List<GuestModel>> getGuests({Map<String, dynamic>? filters}) async {
    try {
      // Try to fetch from API if online
      if (await _isOnline()) {
        try {
          final response = await get(
            '${ApiConfig.guestsEndpoint}read.php',
            queryParameters: filters,
          );
          
          List<GuestModel> guests = [];
          if (response.data is List) {
            guests = GuestModel.fromJsonList(response.data as List);
          } else if (response.data is Map && response.data['data'] != null) {
            guests = GuestModel.fromJsonList(response.data['data'] as List);
          }
          
          // Save to local storage
          if (guests.isNotEmpty) {
            await OfflineStorageService.saveGuests(guests);
            await OfflineStorageService.saveLastSync('guests', DateTime.now());
          }
          
          return guests;
        } catch (e) {
          // If API fails, fall back to local storage
          debugPrint('API fetch failed, using local storage: $e');
        }
      }
      
      // Use local storage (offline mode)
      return OfflineStorageService.getGuests();
    } catch (e) {
      // Final fallback to local storage
      return OfflineStorageService.getGuests();
    }
  }

  /// Get guest by ID (with offline support)
  Future<GuestModel?> getGuestById(int guestId) async {
    try {
      // Try to fetch from API if online
      if (await _isOnline()) {
        try {
          final response = await get(
            '${ApiConfig.guestsEndpoint}read.php',
            queryParameters: {'guest_id': guestId},
          );
          
          GuestModel? guest;
          if (response.data is Map && response.data['success'] == true && response.data['data'] != null) {
            guest = GuestModel.fromJson(response.data['data'] as Map<String, dynamic>);
          } else if (response.data is List && (response.data as List).isNotEmpty) {
            guest = GuestModel.fromJson(response.data[0] as Map<String, dynamic>);
          } else if (response.data is Map && response.data['guest_id'] != null) {
            guest = GuestModel.fromJson(response.data as Map<String, dynamic>);
          }
          
          // Save to local storage if found
          if (guest != null) {
            await OfflineStorageService.saveGuest(guest);
          }
          
          return guest;
        } catch (e) {
          // If API fails, fall back to local storage
          debugPrint('API fetch failed, using local storage: $e');
        }
      }
      
      // Use local storage (offline mode)
      return OfflineStorageService.getGuestById(guestId);
    } catch (e) {
      // Final fallback to local storage
      return OfflineStorageService.getGuestById(guestId);
    }
  }

  /// Create new guest (with offline support)
  Future<GuestModel> createGuest(GuestModel guest) async {
    try {
      // Try to create via API if online
      if (await _isOnline()) {
        try {
          final response = await post(
            '${ApiConfig.guestsEndpoint}create.php',
            data: guest.toJson(),
          );
          
          if (response.data is Map) {
            final createdGuest = GuestModel.fromJson(response.data as Map<String, dynamic>);
            // Save to local storage
            await OfflineStorageService.saveGuest(createdGuest);
            return createdGuest;
          }
          throw Exception('Invalid response format');
        } catch (e) {
          // If API fails, add to sync queue and save locally with temporary ID
          debugPrint('API create failed, adding to sync queue: $e');
        }
      }
      
      // Offline mode: save locally and add to sync queue
      // Generate temporary ID (negative to indicate temporary)
      final tempId = guest.guestId != null && guest.guestId! < 0
          ? guest.guestId
          : -(DateTime.now().millisecondsSinceEpoch);
      final tempGuest = guest.copyWith(guestId: tempId);
      
      // Save to local storage
      await OfflineStorageService.saveGuest(tempGuest);
      
      // Add to sync queue
      await OfflineStorageService.addToSyncQueue(
        operation: 'create',
        entityType: 'guest',
        data: tempGuest.toJson(),
        entityId: tempGuest.guestId.toString(),
      );
      
      return tempGuest;
    } catch (e) {
      throw Exception('Failed to create guest: $e');
    }
  }

  /// Update guest (with offline support)
  Future<GuestModel> updateGuest(GuestModel guest) async {
    try {
      // Try to update via API if online
      if (await _isOnline()) {
        try {
          final response = await put(
            '${ApiConfig.guestsEndpoint}update.php',
            data: guest.toJson(),
          );
          
          if (response.data is Map) {
            final updatedGuest = GuestModel.fromJson(response.data as Map<String, dynamic>);
            // Save to local storage
            await OfflineStorageService.saveGuest(updatedGuest);
            return updatedGuest;
          }
          throw Exception('Invalid response format');
        } catch (e) {
          // If API fails, add to sync queue and update locally
          debugPrint('API update failed, adding to sync queue: $e');
        }
      }
      
      // Offline mode: update locally and add to sync queue
      await OfflineStorageService.saveGuest(guest);
      
      // Add to sync queue
      await OfflineStorageService.addToSyncQueue(
        operation: 'update',
        entityType: 'guest',
        data: guest.toJson(),
        entityId: guest.guestId.toString(),
      );
      
      return guest;
    } catch (e) {
      throw Exception('Failed to update guest: $e');
    }
  }

  /// Delete guest (with offline support)
  Future<bool> deleteGuest(int guestId) async {
    try {
      // Try to delete via API if online
      if (await _isOnline()) {
        try {
          final response = await delete(
            '${ApiConfig.guestsEndpoint}delete.php',
            data: {'guest_id': guestId},
          );
          
          final success = response.data['success'] == true || response.statusCode == 200;
          if (success) {
            // Remove from local storage
            await OfflineStorageService.deleteGuest(guestId);
          }
          return success;
        } catch (e) {
          // If API fails, add to sync queue and delete locally
          debugPrint('API delete failed, adding to sync queue: $e');
        }
      }
      
      // Offline mode: delete locally and add to sync queue
      final guest = OfflineStorageService.getGuestById(guestId);
      if (guest != null) {
        // Delete from local storage
        await OfflineStorageService.deleteGuest(guestId);
        
        // Add to sync queue
        await OfflineStorageService.addToSyncQueue(
          operation: 'delete',
          entityType: 'guest',
          data: guest.toJson(),
          entityId: guestId.toString(),
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      throw Exception('Failed to delete guest: $e');
    }
  }

  /// Search guests (with offline support)
  Future<List<GuestModel>> searchGuests(String query) async {
    try {
      // Try to search via API if online
      if (await _isOnline()) {
        try {
          final response = await get(
            '${ApiConfig.guestsEndpoint}search.php',
            queryParameters: {'q': query},
          );
          
          List<GuestModel> guests = [];
          if (response.data is Map && response.data['success'] == true) {
            if (response.data['data'] != null) {
              if (response.data['data'] is List) {
                guests = GuestModel.fromJsonList(response.data['data'] as List);
              } else if (response.data['data'] is Map) {
                guests = [GuestModel.fromJson(response.data['data'] as Map<String, dynamic>)];
              }
            }
          } else if (response.data is List) {
            guests = GuestModel.fromJsonList(response.data as List);
          }
          
          return guests;
        } catch (e) {
          // If API fails, fall back to local search
          debugPrint('API search failed, using local storage: $e');
        }
      }
      
      // Offline mode: search locally
      final allGuests = OfflineStorageService.getGuests();
      final queryLower = query.toLowerCase();
      return allGuests.where((guest) {
        return guest.firstName.toLowerCase().contains(queryLower) ||
               guest.lastName.toLowerCase().contains(queryLower) ||
               (guest.email != null && guest.email!.toLowerCase().contains(queryLower)) ||
               guest.phone.toLowerCase().contains(queryLower);
      }).toList();
    } catch (e) {
      // Final fallback: return empty list or search locally
      try {
        final allGuests = OfflineStorageService.getGuests();
        final queryLower = query.toLowerCase();
        return allGuests.where((guest) {
          return guest.firstName.toLowerCase().contains(queryLower) ||
                 guest.lastName.toLowerCase().contains(queryLower) ||
                 (guest.email != null && guest.email!.toLowerCase().contains(queryLower)) ||
                 guest.phone.toLowerCase().contains(queryLower);
        }).toList();
      } catch (e2) {
        return [];
      }
    }
  }
}

