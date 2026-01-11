/// Formatters
/// 
/// Common formatting functions for displaying data

import 'package:intl/intl.dart';

class Formatters {
  /// Format currency
  static String currency(double amount, {String symbol = '\$'}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return formatter.format(amount);
  }

  /// Format date
  static String date(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format date time
  static String dateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  /// Format time
  static String time(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Format phone number
  static String phone(String phone) {
    // Remove all non-digit characters
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length == 11 && digits.startsWith('1')) {
      return '+1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }
    return phone;
  }

  /// Format number with commas
  static String number(double number, {int decimals = 0}) {
    final formatter = NumberFormat('#,##0.${'0' * decimals}');
    return formatter.format(number);
  }

  /// Format percentage
  static String percentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  /// Format duration (e.g., "3 nights")
  static String duration(DateTime start, DateTime end) {
    final days = end.difference(start).inDays;
    if (days == 1) {
      return '1 night';
    }
    return '$days nights';
  }
}

