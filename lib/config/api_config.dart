/// API Configuration
/// 
/// Configuration for PHP API endpoints used by the Flutter app
/// Supports both localhost and production environments

class ApiConfig {
  // Base URL for PHP APIs
  static const String baseUrl = 'http://localhost/hotel/api/';
  
  // Alternative: Production URL (uncomment when deploying)
  // static const String baseUrl = 'https://tin.neuereatec.com/hotel/api/';
  
  // API Endpoints
  static const String guestsEndpoint = '${baseUrl}guests/';
  static const String roomsEndpoint = '${baseUrl}rooms/';
  static const String reservationsEndpoint = '${baseUrl}reservations/';
  static const String billingEndpoint = '${baseUrl}billing/';
  // POS endpoints are in /pos/api/ not /api/pos/api/
  static const String posEndpoint = 'http://localhost/hotel/pos/api/';
  static const String restaurantEndpoint = '${baseUrl}RestaurantBar/api/restaurant/';
  static const String authEndpoint = '${baseUrl}api/firebase_auth_verify.php';
  
  // Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}

