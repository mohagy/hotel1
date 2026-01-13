/// Print Helper
/// 
/// Provides cross-platform print functionality
/// Uses conditional imports for web vs mobile platforms

// Conditional imports - different implementations for web and non-web
export 'print_helper_stub.dart'
    if (dart.library.html) 'print_helper_web.dart';

// Export order model for print function
export '../models/order_model.dart';

