/// Permission Model
/// 
/// Represents permissions in the system

class PermissionModel {
  final int? permissionId;
  final String name;
  final String key; // Unique identifier like 'guests.create', 'rooms.edit'
  final String? description;
  final String category; // 'guests', 'rooms', 'reservations', etc.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PermissionModel({
    this.permissionId,
    required this.name,
    required this.key,
    this.description,
    required this.category,
    this.createdAt,
    this.updatedAt,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      permissionId: json['permission_id'] as int?,
      name: json['name'] as String,
      key: json['key'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (permissionId != null) 'permission_id': permissionId,
      'name': name,
      'key': key,
      if (description != null) 'description': description,
      'category': category,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  PermissionModel copyWith({
    int? permissionId,
    String? name,
    String? key,
    String? description,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PermissionModel(
      permissionId: permissionId ?? this.permissionId,
      name: name ?? this.name,
      key: key ?? this.key,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Role Permission Model
/// 
/// Represents the relationship between roles and permissions

class RolePermissionModel {
  final int? rolePermissionId;
  final int roleId;
  final int permissionId;
  final DateTime? createdAt;

  RolePermissionModel({
    this.rolePermissionId,
    required this.roleId,
    required this.permissionId,
    this.createdAt,
  });

  factory RolePermissionModel.fromJson(Map<String, dynamic> json) {
    return RolePermissionModel(
      rolePermissionId: json['role_permission_id'] as int?,
      roleId: json['role_id'] as int,
      permissionId: json['permission_id'] as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (rolePermissionId != null) 'role_permission_id': rolePermissionId,
      'role_id': roleId,
      'permission_id': permissionId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

