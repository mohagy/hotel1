/// Notification Service
/// 
/// Handles sound notifications for incoming messages

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _soundEnabled = true;
  bool get soundEnabled => _soundEnabled;

  /// Enable/disable sound notifications
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  /// Play notification sound
  Future<void> playNotificationSound({String? messageType}) async {
    if (!_soundEnabled) return;

    try {
      // For web, use HTML5 Audio API via JavaScript interop
      if (kIsWeb) {
        _playWebSound(messageType);
        return;
      }

      // For mobile/desktop platforms, use system sounds
      // Different sounds for different message types
      switch (messageType) {
        case 'emergency':
          // Emergency sound (more urgent) - play multiple times
          SystemSound.play(SystemSoundType.alert);
          await Future.delayed(const Duration(milliseconds: 200));
          SystemSound.play(SystemSoundType.alert);
          break;
        case 'alert':
          // Alert sound
          SystemSound.play(SystemSoundType.alert);
          break;
        case 'announcement':
          // Announcement sound
          SystemSound.play(SystemSoundType.alert);
          break;
        case 'task':
          // Task sound
          SystemSound.play(SystemSoundType.click);
          break;
        default:
          // Normal message sound
          SystemSound.play(SystemSoundType.click);
          break;
      }
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
    }
  }

  /// Play sound on web using HTML5 Audio API
  void _playWebSound(String? messageType) {
    try {
      // For web, we can use HTML5 Audio API
      // Note: This is a simple beep sound. For production, you might want to use actual sound files
      // You can add sound files to assets and use them here
      debugPrint('Notification sound requested (web): $messageType');
      
      // Optionally, you can add sound files to assets/audio/ and play them:
      // For example: _audioPlayer.play(AssetSource('sounds/notification.mp3'));
      
      // For now, web notifications will rely on visual indicators
      // Sound files can be added later if needed
    } catch (e) {
      debugPrint('Error playing web sound: $e');
    }
  }

  /// Show in-app notification
  void showInAppNotification({
    required String title,
    required String body,
    String? messageType,
  }) {
    // Play sound for notification
    playNotificationSound(messageType: messageType);
    debugPrint('Notification: $title - $body (Type: $messageType)');
  }
}
