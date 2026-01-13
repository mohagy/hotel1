/// Print Helper Stub Implementation
/// 
/// Non-web platform stub (mobile/desktop)

import 'package:flutter/foundation.dart';
import '../models/order_model.dart';

void printDocument() {
  // Print not available on non-web platforms
  // Could implement native printing using packages like printing package
  debugPrint('Print functionality is only available on web');
}

void printThermalReceipt({
  required OrderModel order,
  required String customerName,
  double? amountPaid,
  String? reservationNumber,
  String? storeName,
  String? storeAddress,
  String? storePhone,
}) {
  // Print not available on non-web platforms
  debugPrint('Thermal receipt printing is only available on web');
}

