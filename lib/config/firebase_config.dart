/// Firebase Configuration and Initialization
/// 
/// This file handles Firebase initialization for the Hotel Management System
/// Uses existing Firebase project: flutter-hotel-8efbf

import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class FirebaseConfig {
  /// Initialize Firebase with platform-specific options
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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

