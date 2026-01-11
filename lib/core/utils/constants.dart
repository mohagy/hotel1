/// Constants
/// 
/// Application-wide constants

class Constants {
  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration apiRetryDelay = Duration(seconds: 2);
  static const int maxRetries = 3;

  // Pagination
  static const int itemsPerPage = 20;
  static const int maxItemsPerPage = 100;

  // Debounce delays
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const Duration refreshDebounce = Duration(seconds: 1);

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Cache durations
  static const Duration shortCache = Duration(minutes: 5);
  static const Duration mediumCache = Duration(hours: 1);
  static const Duration longCache = Duration(hours: 24);

  // File size limits (in bytes)
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxDocumentSize = 10 * 1024 * 1024; // 10MB

  // POS Constants
  static const double defaultTaxRate = 0.0; // Can be configured
  static const double defaultServiceCharge = 0.0; // Can be configured
}

