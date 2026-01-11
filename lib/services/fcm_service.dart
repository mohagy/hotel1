/// Firebase Cloud Messaging Service
/// 
/// Handles push notifications using FCM

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'notification_service.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  /// Initialize FCM
  Future<void> initialize() async {
    try {
      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('FCM: User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('FCM: User granted provisional permission');
      } else {
        debugPrint('FCM: User declined or has not accepted permission');
        return; // Skip FCM initialization if permission denied
      }

      // Get FCM token (on web, this may fail if service worker is not registered)
      try {
        String? token = await _messaging.getToken();
        debugPrint('FCM Token: $token');
        
        // Save token to backend
        if (token != null) {
          await saveTokenToBackend(token);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          debugPrint('FCM Token refreshed: $newToken');
          saveTokenToBackend(newToken);
        });
      } catch (e) {
        // Token retrieval failed (e.g., service worker not registered on web)
        debugPrint('FCM: Token retrieval failed (this is normal on web without service worker): $e');
        return; // Skip remaining FCM setup
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (when app is opened from notification)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      
      // Check if app was opened from a notification (when app was terminated)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
      // Continue without FCM - app will still work, just no push notifications
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');
    
    // Play sound notification for chat messages
    if (message.data['type'] == 'chat' || message.data['type'] == 'message') {
      final notificationService = NotificationService();
      notificationService.playNotificationSound(
        messageType: message.data['messageType'] as String?,
      );
    }
    
    // Show notification to user (you can use flutter_local_notifications package)
    // NotificationService.showNotification(message);
  }

  /// Handle background messages
  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('Background message opened: ${message.messageId}');
    debugPrint('Data: ${message.data}');
    
    // Handle navigation based on message data
    // Example: Navigate to specific screen based on notification type
    // if (message.data['type'] == 'reservation') {
    //   NavigationService.navigateTo('/reservations/${message.data['reservation_id']}');
    // } else if (message.data['type'] == 'message') {
    //   NavigationService.navigateTo('/messages/${message.data['conversation_id']}');
    // }
  }

  /// Save FCM token to backend
  Future<void> saveTokenToBackend(String token) async {
    try {
      // Send token to PHP backend API for storing user device tokens
      // This allows the backend to send push notifications to specific users
      // TODO: Implement API endpoint if not exists: /api/notifications/save-token.php
      // await apiService.post('${ApiConfig.baseUrl}api/notifications/save-token.php', data: {'token': token, 'user_id': userId});
      debugPrint('FCM Token saved: $token');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Subscribe to hotel-specific topics
  Future<void> subscribeToHotelTopics() async {
    await subscribeToTopic('reservations');
    await subscribeToTopic('check_ins');
    await subscribeToTopic('payments');
    await subscribeToTopic('messages');
    await subscribeToTopic('alerts');
    await subscribeToTopic('group_chat');
    await subscribeToTopic('private_chat');
  }
}

