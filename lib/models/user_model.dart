/// User Model
/// 
/// Represents staff and admin accounts

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final dynamic userId; // Can be int (legacy) or String (Firebase UID)
  final String username;
  final String? email;
  final String fullName;
  final String role; // 'admin', 'manager', 'staff'
  final String status; // 'active', 'inactive'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    this.userId,
    required this.username,
    this.email,
    required this.fullName,
    required this.role,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle user_id as int or string (Firebase UID)
    dynamic userId = json['user_id'];
    
    return UserModel(
      userId: userId, // Can be int or String
      username: json['username'] as String? ?? (json['email'] as String? ?? 'user').split('@').first,
      email: json['email'] as String?,
      fullName: json['full_name'] as String? ?? json['username'] as String? ?? 'User',
      role: json['role'] as String? ?? 'staff',
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? (json['created_at'] is String
              ? DateTime.parse(json['created_at'] as String)
              : (json['created_at'] is Timestamp
                  ? (json['created_at'] as Timestamp).toDate()
                  : null))
          : null,
      updatedAt: json['updated_at'] != null
          ? (json['updated_at'] is String
              ? DateTime.parse(json['updated_at'] as String)
              : (json['updated_at'] is Timestamp
                  ? (json['updated_at'] as Timestamp).toDate()
                  : null))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'user_id': userId,
      'username': username,
      if (email != null) 'email': email,
      'full_name': fullName,
      'role': role,
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Helper methods
  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager' || role == 'admin';
  bool get isStaff => role == 'staff';

  UserModel copyWith({
    dynamic userId,
    String? username,
    String? email,
    String? fullName,
    String? role,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

