/// Firebase Configuration and Initialization
/// 
/// This file handles Firebase initialization for the Hotel Management System
/// Uses existing Firebase project: flutter-hotel-8efbf

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseConfig {
  /// Initialize Firebase with platform-specific options
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Configure Firestore for better performance
    // Enable persistence for offline support and caching
    // Note: Persistence is enabled by default on mobile, but we configure it explicitly
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Set cache size to 100MB (default is 40MB) for better offline support
      // This allows more data to be cached locally, reducing network requests
      if (!kIsWeb) {
        // On mobile platforms, persistence is enabled by default
        // We can configure cache size if needed
        // Note: Web doesn't support persistence in the same way
        firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // Use unlimited cache for better performance
        );
      } else {
        // For web, we use memory cache
        firestore.settings = const Settings(
          persistenceEnabled: false, // Web doesn't support disk persistence
        );
      }
      
      debugPrint('Firestore settings configured for ${kIsWeb ? "web" : "mobile"}');
    } catch (e) {
      debugPrint('Error configuring Firestore settings: $e');
      // Continue even if settings fail
    }
  }

  /// Check if Firebase is already initialized
  static bool get isInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

