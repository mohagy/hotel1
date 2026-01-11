/// Unit Tests for Guest Model
/// 
/// Tests guest model serialization and deserialization

import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management/models/guest_model.dart';

void main() {
  group('GuestModel', () {
    test('should create GuestModel from JSON', () {
      final json = {
        'guest_id': 1,
        'first_name': 'John',
        'last_name': 'Doe',
        'email': 'john.doe@example.com',
        'phone': '1234567890',
        'country': 'USA',
        'guest_type': 'regular',
        'id_type': 'passport',
        'id_number': 'AB123456',
      };

      final guest = GuestModel.fromJson(json);

      expect(guest.guestId, equals(1));
      expect(guest.firstName, equals('John'));
      expect(guest.lastName, equals('Doe'));
      expect(guest.email, equals('john.doe@example.com'));
      expect(guest.phone, equals('1234567890'));
      expect(guest.idType, equals('passport'));
      expect(guest.idNumber, equals('AB123456'));
    });

    test('should convert GuestModel to JSON', () {
      final guest = GuestModel(
        guestId: 1,
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        phone: '1234567890',
        country: 'USA',
        guestType: 'regular',
        idType: 'passport',
        idNumber: 'AB123456',
      );

      final json = guest.toJson();

      expect(json['guest_id'], equals(1));
      expect(json['first_name'], equals('John'));
      expect(json['last_name'], equals('Doe'));
      expect(json['email'], equals('john.doe@example.com'));
      expect(json['phone'], equals('1234567890'));
      expect(json['id_type'], equals('passport'));
      expect(json['id_number'], equals('AB123456'));
    });

    test('should create GuestModel list from JSON list', () {
      final jsonList = [
        {
          'guest_id': 1,
          'first_name': 'John',
          'last_name': 'Doe',
          'email': 'john@example.com',
        },
        {
          'guest_id': 2,
          'first_name': 'Jane',
          'last_name': 'Smith',
          'email': 'jane@example.com',
        },
      ];

      final guests = GuestModel.fromJsonList(jsonList);

      expect(guests.length, equals(2));
      expect(guests[0].firstName, equals('John'));
      expect(guests[1].firstName, equals('Jane'));
    });

    test('should copy GuestModel with new values', () {
      final original = GuestModel(
        guestId: 1,
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        phone: '1234567890',
        idType: 'passport',
        idNumber: 'AB123456',
      );

      final copied = original.copyWith(firstName: 'Jane');

      expect(copied.guestId, equals(1));
      expect(copied.firstName, equals('Jane'));
      expect(copied.lastName, equals('Doe'));
      expect(copied.email, equals('john@example.com'));
      expect(copied.phone, equals('1234567890'));
    });
  });
}

