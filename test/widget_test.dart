// Basic Flutter widget test for Hotel Management System
//
// This file contains smoke tests to ensure the app can be built and rendered

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hotel_management/main.dart';

void main() {
  testWidgets('App should render without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const HotelManagementApp());

    // Verify that the app renders without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
