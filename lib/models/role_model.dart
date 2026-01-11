/// Role Model
/// 
/// Represents user roles in the system

class RoleModel {
  final int? roleId;
  final String name;
  final String? description;
  final bool isSystemRole; // System roles cannot be deleted
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RoleModel({
    this.roleId,
    required this.name,
    this.description,
    this.isSystemRole = false,
    this.createdAt,
    this.updatedAt,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      roleId: json['role_id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String?,
      isSystemRole: json['is_system_role'] as bool? ?? false,
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
      if (roleId != null) 'role_id': roleId,
      'name': name,
      if (description != null) 'description': description,
      'is_system_role': isSystemRole,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  RoleModel copyWith({
    int? roleId,
    String? name,
    String? description,
    bool? isSystemRole,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoleModel(
      roleId: roleId ?? this.roleId,
      name: name ?? this.name,
      description: description ?? this.description,
      isSystemRole: isSystemRole ?? this.isSystemRole,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

