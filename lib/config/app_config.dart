/// Application Constants
/// 
/// Global constants used throughout the application

class AppConfig {
  // App Information
  static const String appName = 'Hotel Management System';
  static const String appVersion = '1.0.0';
  
  // Firebase Project Information
  static const String firebaseProjectId = 'flutter-hotel-8efbf';
  // API key will be in firebase_options.dart
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String displayDateTimeFormat = 'MMM dd, yyyy HH:mm';
  
  // Currency
  static const String defaultCurrency = 'USD';
  static const String currencySymbol = '\$';
  
  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String posModeKey = 'pos_mode';
  static const String viewTypeKey = 'view_type';
  
  // App Themes
  static const String lightTheme = 'light';
  static const String darkTheme = 'dark';
  
  // POS Modes
  static const String posModeRetail = 'retail';
  static const String posModeRestaurant = 'restaurant';
  static const String posModeReservation = 'reservation';
  
  // View Types for Reservations
  static const String viewTypeGrid = 'grid';
  static const String viewTypeList = 'list';
  static const String viewTypeCompact = 'compact';
  static const String viewTypeSummary = 'summary';
}

