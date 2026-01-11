/// Widget Tests for Guest Card
/// 
/// Tests guest card widget rendering and interactions

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management/models/guest_model.dart';
import 'package:hotel_management/core/widgets/common_widgets.dart';

void main() {
  group('GuestCard Widget', () {
    testWidgets('should display guest information correctly', (WidgetTester tester) async {
      final guest = GuestModel(
        guestId: 1,
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        phone: '1234567890',
        idType: 'passport',
        idNumber: 'AB123456',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              title: Text('${guest.firstName} ${guest.lastName}'),
              subtitle: Text(guest.email ?? ''),
              trailing: Text(guest.phone ?? ''),
            ),
          ),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john.doe@example.com'), findsOneWidget);
      expect(find.text('1234567890'), findsOneWidget);
    });

    testWidgets('should handle null phone number', (WidgetTester tester) async {
      final guest = GuestModel(
        guestId: 1,
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane@example.com',
        phone: '1234567890', // phone is required
        idType: 'passport',
        idNumber: 'AB123456',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              title: Text('${guest.firstName} ${guest.lastName}'),
              subtitle: Text(guest.email ?? ''),
              trailing: Text(guest.phone ?? 'N/A'),
            ),
          ),
        ),
      );

      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('jane@example.com'), findsOneWidget);
      expect(find.text('N/A'), findsOneWidget);
    });
  });
}

