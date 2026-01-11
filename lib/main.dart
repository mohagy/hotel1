/// Hotel Management System - Main Entry Point
/// 
/// Flutter application with Firebase integration
/// Supports: iOS, Android, Web, Windows, macOS, Linux

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'config/firebase_config.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/guest_provider.dart';
import 'providers/room_provider.dart';
import 'providers/reservation_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/permission_provider.dart';
import 'services/fcm_service.dart';
import 'services/offline_storage_service.dart';
import 'services/sync_service.dart';
import 'services/auth_sync_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message handler: ${message.messageId}');
  // Handle background message
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Offline Storage (Hive)
  try {
    await OfflineStorageService.initialize();
    debugPrint('Offline storage initialized successfully');
  } catch (e) {
    debugPrint('Error initializing offline storage: $e');
  }
  
  // Initialize Firebase
  try {
    await FirebaseConfig.initialize();
    debugPrint('Firebase initialized successfully');
    
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Initialize FCM
    try {
      final fcmService = FCMService();
      await fcmService.initialize();
      debugPrint('FCM initialized successfully');
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
    
    // Initialize Auth Sync Service to sync Firebase Auth users to Firestore
    try {
      final authSyncService = AuthSyncService();
      authSyncService.initialize();
      debugPrint('Auth sync service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing auth sync service: $e');
    }
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }
  
  // Attempt initial sync if online
  try {
    final syncService = SyncService();
    if (await syncService.isOnline()) {
      // Sync in background (don't wait)
      syncService.syncFromRemote().then((success) {
        if (success) {
          debugPrint('Initial sync completed successfully');
          // Also sync any pending queue operations
          syncService.syncQueueToRemote();
        } else {
          debugPrint('Initial sync failed: ${syncService.lastError}');
        }
      });
    }
  } catch (e) {
    debugPrint('Error during initial sync: $e');
  }
  
  runApp(const HotelManagementApp());
}

class HotelManagementApp extends StatelessWidget {
  const HotelManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PermissionProvider()),
        ChangeNotifierProvider(create: (_) => GuestProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: MaterialApp.router(
        title: 'Hotel Management System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
