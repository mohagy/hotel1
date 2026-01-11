/// App Color Theme
/// 
/// Defines color palette for the Hotel Management System
/// Uses Navy & Gold branding consistent with the PHP app

import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Navy & Gold)
  static const Color primaryNavy = Color(0xFF1a2332); // Dark Navy
  static const Color primaryGold = Color(0xFFd4af37); // Gold
  
  // Secondary Colors
  static const Color secondaryBlue = Color(0xFF3498db);
  static const Color secondaryGreen = Color(0xFF27ae60);
  static const Color secondaryRed = Color(0xFFe74c3c);
  static const Color secondaryOrange = Color(0xFFf39c12);
  
  // Neutral Colors
  static const Color backgroundLight = Color(0xFFf5f7fa);
  static const Color backgroundDark = Color(0xFF1a2332);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFe0e0e0);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF2c3e50);
  static const Color textSecondary = Color(0xFF7f8c8d);
  static const Color textLight = Color(0xFFbdc3c7);
  static const Color textWhite = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color statusSuccess = Color(0xFF27ae60);
  static const Color statusWarning = Color(0xFFf39c12);
  static const Color statusError = Color(0xFFe74c3c);
  static const Color statusInfo = Color(0xFF3498db);
  
  // POS Mode Colors
  static const Color posRetail = Color(0xFF3498db);
  static const Color posRestaurant = Color(0xFFe74c3c);
  static const Color posReservation = Color(0xFF27ae60);
  
  // Room Status Colors
  static const Color roomAvailable = Color(0xFF27ae60);
  static const Color roomOccupied = Color(0xFFe74c3c);
  static const Color roomReserved = Color(0xFFf39c12);
  static const Color roomMaintenance = Color(0xFF7f8c8d);
  static const Color roomCleaning = Color(0xFF3498db);
}

