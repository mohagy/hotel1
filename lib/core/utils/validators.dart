/// Form Validators
/// 
/// Common validation functions for form inputs

class Validators {
  /// Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Required field validation
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Phone number validation
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Number validation
  static String? number(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return 'Number is required';
    }
    final num = double.tryParse(value);
    if (num == null) {
      return 'Please enter a valid number';
    }
    if (min != null && num < min) {
      return 'Value must be at least $min';
    }
    if (max != null && num > max) {
      return 'Value must be at most $max';
    }
    return null;
  }

  /// Date validation
  static String? date(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(value)) {
      return 'Please enter a valid date (YYYY-MM-DD)';
    }
    return null;
  }
}

