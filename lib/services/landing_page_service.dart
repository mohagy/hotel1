/// Landing Page Service
/// 
/// Handles landing page content management including media/images and room statistics

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'api_service.dart';
import 'room_service.dart';
import 'reservation_service.dart';
import '../config/api_config.dart';

class LandingPageService extends ApiService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final RoomService _roomService = RoomService();
  final ReservationService _reservationService = ReservationService();

  Future<bool> _isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get landing page content
  Future<Map<String, dynamic>> getLandingPageContent() async {
    try {
      if (await _isOnline()) {
        try {
          final doc = await _firestore.collection('landing_page').doc('content').get();
          if (doc.exists) {
            return doc.data() as Map<String, dynamic>;
          }
        } catch (e) {
          debugPrint('Firestore fetch failed: $e');
        }
      }
      
      // Return default content
      return _getDefaultContent();
    } catch (e) {
      return _getDefaultContent();
    }
  }

  /// Update landing page content
  Future<bool> updateLandingPageContent(Map<String, dynamic> content) async {
    try {
      if (await _isOnline()) {
        try {
          await _firestore.collection('landing_page').doc('content').set(
            {
              ...content,
              'updated_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
          return true;
        } catch (e) {
          debugPrint('Firestore update failed: $e');
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get room statistics (available and booked)
  Future<Map<String, int>> getRoomStatistics() async {
    try {
      final rooms = await _roomService.getRooms();
      final reservations = await _reservationService.getReservations();
      
      final totalRooms = rooms.length;
      final availableRooms = rooms.where((r) => r.status == 'available').length;
      final occupiedRooms = rooms.where((r) => r.status == 'occupied').length;
      final bookedRooms = reservations.where((r) => 
        r.status == 'reserved' || r.status == 'checked_in'
      ).length;
      
      return {
        'total': totalRooms,
        'available': availableRooms,
        'occupied': occupiedRooms,
        'booked': bookedRooms,
      };
    } catch (e) {
      debugPrint('Error getting room statistics: $e');
      return {
        'total': 0,
        'available': 0,
        'occupied': 0,
        'booked': 0,
      };
    }
  }

  /// Upload landing page image
  Future<String?> uploadImage(File imageFile, String imageType) async {
    try {
      // This would typically upload to Firebase Storage
      // For now, return a placeholder URL
      // In production, implement Firebase Storage upload
      return null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Get default landing page content
  Map<String, dynamic> _getDefaultContent() {
    return {
      'hotel_name': 'Grand Hotel',
      'hotel_description': 'Discover the perfect blend of comfort, elegance, and world-class service',
      'hero_video_url': './WiFi/assets/videos/hotel-lobby.mp4',
      'hero_title': 'Experience Luxury at Grand Hotel',
      'hero_subtitle': 'Discover the perfect blend of comfort, elegance, and world-class service',
      'about_title': 'Welcome to Luxury',
      'about_text': 'Grand Hotel stands as a beacon of luxury and hospitality in the heart of the city. With over 20 years of excellence, we have been the preferred choice for discerning travelers from around the world.',
      'about_image_url': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=1170&q=80',
      'contact_address': '123 Luxury Avenue\nNew York, NY 10001\nUnited States',
      'contact_phone': '+1 (555) 123-4567',
      'contact_email': 'info@grandhotel.com',
      'social_facebook': '',
      'social_twitter': '',
      'social_instagram': '',
      'social_linkedin': '',
      'room_images': {
        'single': 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
        'double': 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
        'suite': 'https://images.unsplash.com/photo-1578500494198-246f612d03b3?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
        'deluxe': 'https://images.unsplash.com/photo-1591088398332-8c5ecd3b3c4d?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
      },
    };
  }
}

