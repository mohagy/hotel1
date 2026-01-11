/// Unit Tests for Guest Service
/// 
/// Tests guest service functionality including offline support

import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management/models/guest_model.dart';
import 'package:hotel_management/services/guest_service.dart';
import 'package:hotel_management/services/offline_storage_service.dart';
import 'package:hotel_management/services/sync_service.dart';

void main() {
  group('GuestService', () {
    late GuestService guestService;
    late SyncService syncService;

    setUp(() async {
      // Initialize offline storage for testing
      await OfflineStorageService.initialize();
      syncService = SyncService();
      guestService = GuestService();
    });

    tearDown(() async {
      // Clean up test data
      await OfflineStorageService.clearAll();
    });

    test('should initialize GuestService', () {
      expect(guestService, isNotNull);
    });

    group('Offline Storage Integration', () {
      test('should save and retrieve guest from local storage', () async {
        final guest = GuestModel(
          guestId: 1,
          firstName: 'John',
          lastName: 'Doe',
          email: 'john.doe@example.com',
          phone: '1234567890',
          idType: 'passport',
          idNumber: 'AB123456',
        );

        await OfflineStorageService.saveGuest(guest);
        final retrievedGuest = OfflineStorageService.getGuestById(1);

        expect(retrievedGuest, isNotNull);
        expect(retrievedGuest?.guestId, equals(1));
        expect(retrievedGuest?.firstName, equals('John'));
        expect(retrievedGuest?.lastName, equals('Doe'));
        expect(retrievedGuest?.email, equals('john.doe@example.com'));
      });

      test('should retrieve all guests from local storage', () async {
        final guests = [
          GuestModel(guestId: 1, firstName: 'John', lastName: 'Doe', email: 'john@example.com', phone: '123', idType: 'passport', idNumber: 'AB1'),
          GuestModel(guestId: 2, firstName: 'Jane', lastName: 'Smith', email: 'jane@example.com', phone: '456', idType: 'passport', idNumber: 'AB2'),
        ];

        await OfflineStorageService.saveGuests(guests);
        final retrievedGuests = OfflineStorageService.getGuests();

        expect(retrievedGuests.length, equals(2));
        expect(retrievedGuests[0].firstName, equals('John'));
        expect(retrievedGuests[1].firstName, equals('Jane'));
      });

      test('should delete guest from local storage', () async {
        final guest = GuestModel(
          guestId: 1,
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          phone: '123',
          idType: 'passport',
          idNumber: 'AB123',
        );

        await OfflineStorageService.saveGuest(guest);
        await OfflineStorageService.deleteGuest(1);
        final retrievedGuest = OfflineStorageService.getGuestById(1);

        expect(retrievedGuest, isNull);
      });
    });

    group('Sync Queue', () {
      test('should add operation to sync queue', () async {
        final guest = GuestModel(
          guestId: 1,
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          phone: '123',
          idType: 'passport',
          idNumber: 'AB123',
        );

        await OfflineStorageService.addToSyncQueue(
          operation: 'create',
          entityType: 'guest',
          data: guest.toJson(),
          entityId: '1',
        );

        final queue = OfflineStorageService.getSyncQueue();
        expect(queue.length, equals(1));
        expect(queue[0]['operation'], equals('create'));
        expect(queue[0]['entityType'], equals('guest'));
      });

      test('should remove operation from sync queue', () async {
        final guest = GuestModel(
          guestId: 1,
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          phone: '123',
          idType: 'passport',
          idNumber: 'AB123',
        );

        await OfflineStorageService.addToSyncQueue(
          operation: 'create',
          entityType: 'guest',
          data: guest.toJson(),
          entityId: '1',
        );

        final queue = OfflineStorageService.getSyncQueue();
        expect(queue.length, equals(1));

        await OfflineStorageService.removeFromSyncQueue(queue[0]['id'] as String);
        final updatedQueue = OfflineStorageService.getSyncQueue();
        expect(updatedQueue.length, equals(0));
      });
    });
  });
}

