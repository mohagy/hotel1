/// Firebase Analytics Service
/// 
/// Tracks user behavior and events

import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Log screen view
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  /// Log custom event
  Future<void> logEvent(String name, Map<String, dynamic>? parameters) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  /// Log login event
  Future<void> logLogin({String? method}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// Log purchase event
  Future<void> logPurchase({
    required double value,
    required String currency,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logPurchase(
      value: value,
      currency: currency,
      parameters: parameters,
    );
  }

  /// Log POS transaction
  Future<void> logPOSTransaction({
    required String mode, // 'retail', 'restaurant', 'reservation'
    required double total,
    String? paymentMethod,
  }) async {
    await logEvent('pos_transaction', {
      'mode': mode,
      'total': total,
      if (paymentMethod != null) 'payment_method': paymentMethod,
    });
  }

  /// Log reservation created
  Future<void> logReservationCreated({
    required double totalPrice,
    required int numberOfNights,
  }) async {
    await logEvent('reservation_created', {
      'total_price': totalPrice,
      'number_of_nights': numberOfNights,
    });
  }

  /// Log check-in
  Future<void> logCheckIn(int reservationId) async {
    await logEvent('check_in', {'reservation_id': reservationId});
  }

  /// Log check-out
  Future<void> logCheckOut(int reservationId) async {
    await logEvent('check_out', {'reservation_id': reservationId});
  }

  /// Set user property
  Future<void> setUserProperty({required String name, required String value}) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  /// Set user ID
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }
}

