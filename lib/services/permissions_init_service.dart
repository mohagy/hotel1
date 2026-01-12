/// Permissions Initialization Service
/// 
/// Initializes default permissions and roles for the hotel management system

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/permission_model.dart';
import '../models/role_model.dart';
import 'permission_service.dart';
import 'role_service.dart';

class PermissionsInitService {
  final PermissionService _permissionService = PermissionService();
  final RoleService _roleService = RoleService();
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Get default permissions for hotel management system
  List<PermissionModel> getDefaultPermissions() {
    return [
      // Dashboard Permissions
      PermissionModel(
        name: 'View Dashboard',
        key: 'dashboard.view',
        category: 'dashboard',
        description: 'View the main dashboard',
      ),
      
      // Guest Permissions
      PermissionModel(
        name: 'View Guests',
        key: 'guests.view',
        category: 'guests',
        description: 'View guest list and details',
      ),
      PermissionModel(
        name: 'Create Guests',
        key: 'guests.create',
        category: 'guests',
        description: 'Create new guest records',
      ),
      PermissionModel(
        name: 'Edit Guests',
        key: 'guests.edit',
        category: 'guests',
        description: 'Edit existing guest records',
      ),
      PermissionModel(
        name: 'Delete Guests',
        key: 'guests.delete',
        category: 'guests',
        description: 'Delete guest records',
      ),
      
      // Room Permissions
      PermissionModel(
        name: 'View Rooms',
        key: 'rooms.view',
        category: 'rooms',
        description: 'View room list and details',
      ),
      PermissionModel(
        name: 'Create Rooms',
        key: 'rooms.create',
        category: 'rooms',
        description: 'Create new room records',
      ),
      PermissionModel(
        name: 'Edit Rooms',
        key: 'rooms.edit',
        category: 'rooms',
        description: 'Edit existing room records',
      ),
      PermissionModel(
        name: 'Delete Rooms',
        key: 'rooms.delete',
        category: 'rooms',
        description: 'Delete room records',
      ),
      
      // Reservation Permissions
      PermissionModel(
        name: 'View Reservations',
        key: 'reservations.view',
        category: 'reservations',
        description: 'View reservation list and details',
      ),
      PermissionModel(
        name: 'Create Reservations',
        key: 'reservations.create',
        category: 'reservations',
        description: 'Create new reservations',
      ),
      PermissionModel(
        name: 'Edit Reservations',
        key: 'reservations.edit',
        category: 'reservations',
        description: 'Edit existing reservations',
      ),
      PermissionModel(
        name: 'Check In',
        key: 'reservations.checkin',
        category: 'reservations',
        description: 'Check in guests',
      ),
      PermissionModel(
        name: 'Check Out',
        key: 'reservations.checkout',
        category: 'reservations',
        description: 'Check out guests',
      ),
      PermissionModel(
        name: 'Cancel Reservations',
        key: 'reservations.cancel',
        category: 'reservations',
        description: 'Cancel reservations',
      ),
      
      // Billing Permissions
      PermissionModel(
        name: 'View Billing',
        key: 'billing.view',
        category: 'billing',
        description: 'View billing and invoices',
      ),
      PermissionModel(
        name: 'Create Billing',
        key: 'billing.create',
        category: 'billing',
        description: 'Create invoices and bills',
      ),
      PermissionModel(
        name: 'Edit Billing',
        key: 'billing.edit',
        category: 'billing',
        description: 'Edit billing records',
      ),
      PermissionModel(
        name: 'Process Payments',
        key: 'billing.payment',
        category: 'billing',
        description: 'Process payments',
      ),
      
      // POS Permissions
      PermissionModel(
        name: 'View POS',
        key: 'pos.view',
        category: 'pos',
        description: 'Access POS system',
      ),
      PermissionModel(
        name: 'Process Sales',
        key: 'pos.sales',
        category: 'pos',
        description: 'Process sales transactions',
      ),
      PermissionModel(
        name: 'Manage Products',
        key: 'pos.products',
        category: 'pos',
        description: 'Manage POS products',
      ),
      
      // Reports Permissions
      PermissionModel(
        name: 'View Reports',
        key: 'reports.view',
        category: 'reports',
        description: 'View reports and analytics',
      ),
      PermissionModel(
        name: 'Export Reports',
        key: 'reports.export',
        category: 'reports',
        description: 'Export reports',
      ),
      
      // Messages Permissions
      PermissionModel(
        name: 'View Messages',
        key: 'messages.view',
        category: 'messages',
        description: 'View and send messages',
      ),
      
      // Users & Roles Permissions
      PermissionModel(
        name: 'View Users',
        key: 'users.view',
        category: 'users',
        description: 'View user list',
      ),
      PermissionModel(
        name: 'Create Users',
        key: 'users.create',
        category: 'users',
        description: 'Create new users',
      ),
      PermissionModel(
        name: 'Edit Users',
        key: 'users.edit',
        category: 'users',
        description: 'Edit user accounts',
      ),
      PermissionModel(
        name: 'Delete Users',
        key: 'users.delete',
        category: 'users',
        description: 'Delete user accounts',
      ),
      PermissionModel(
        name: 'Manage Roles',
        key: 'roles.manage',
        category: 'users',
        description: 'Manage roles and permissions',
      ),
      
      // Settings Permissions
      PermissionModel(
        name: 'View Settings',
        key: 'settings.view',
        category: 'settings',
        description: 'View settings',
      ),
      PermissionModel(
        name: 'Edit Settings',
        key: 'settings.edit',
        category: 'settings',
        description: 'Edit system settings',
      ),
      
      // Landing Page Permissions
      PermissionModel(
        name: 'View Landing Page',
        key: 'landing.view',
        category: 'landing',
        description: 'View the public landing page',
      ),
      PermissionModel(
        name: 'Manage Landing Page',
        key: 'landing.manage',
        category: 'landing',
        description: 'Manage landing page content, media, and settings',
      ),
    ];
  }

  /// Initialize permissions in Firestore
  /// Creates all default permissions, including any new ones that don't exist yet
  Future<void> initializePermissions() async {
    try {
      final existingPermissions = await _permissionService.getPermissions();
      final existingKeys = existingPermissions.map((p) => p.key).toSet();
      
      final defaultPermissions = getDefaultPermissions();
      
      // Create permissions that don't exist yet
      int createdCount = 0;
      for (var permission in defaultPermissions) {
        if (!existingKeys.contains(permission.key)) {
          await _permissionService.createPermission(permission);
          createdCount++;
        }
      }
      
      if (createdCount > 0) {
        debugPrint('Created $createdCount new permission(s)');
      }
    } catch (e) {
      throw Exception('Failed to initialize permissions: $e');
    }
  }

  /// Get default roles with their permissions
  Map<String, List<String>> getDefaultRolesPermissions() {
    return {
      'Owner': [
        // All permissions
        'dashboard.view',
        'guests.view', 'guests.create', 'guests.edit', 'guests.delete',
        'rooms.view', 'rooms.create', 'rooms.edit', 'rooms.delete',
        'reservations.view', 'reservations.create', 'reservations.edit', 
        'reservations.checkin', 'reservations.checkout', 'reservations.cancel',
        'billing.view', 'billing.create', 'billing.edit', 'billing.payment',
        'pos.view', 'pos.sales', 'pos.products',
        'reports.view', 'reports.export',
        'messages.view',
        'users.view', 'users.create', 'users.edit', 'users.delete', 'roles.manage',
        'settings.view', 'settings.edit',
        'landing.view', 'landing.manage',
      ],
      'Admin': [
        'dashboard.view',
        'guests.view', 'guests.create', 'guests.edit', 'guests.delete',
        'rooms.view', 'rooms.create', 'rooms.edit', 'rooms.delete',
        'reservations.view', 'reservations.create', 'reservations.edit',
        'reservations.checkin', 'reservations.checkout', 'reservations.cancel',
        'billing.view', 'billing.create', 'billing.edit', 'billing.payment',
        'pos.view', 'pos.sales', 'pos.products',
        'reports.view', 'reports.export',
        'messages.view',
        'users.view', 'users.create', 'users.edit', 'users.delete', 'roles.manage',
        'settings.view', 'settings.edit',
        'landing.view', 'landing.manage',
      ],
      'Manager': [
        'dashboard.view',
        'guests.view', 'guests.create', 'guests.edit',
        'rooms.view', 'rooms.create', 'rooms.edit',
        'reservations.view', 'reservations.create', 'reservations.edit',
        'reservations.checkin', 'reservations.checkout',
        'billing.view', 'billing.create', 'billing.edit', 'billing.payment',
        'pos.view', 'pos.sales',
        'reports.view', 'reports.export',
        'messages.view',
        'users.view',
        'settings.view',
        'landing.view', 'landing.manage',
      ],
      'Receptionist': [
        'dashboard.view',
        'guests.view', 'guests.create', 'guests.edit',
        'rooms.view',
        'reservations.view', 'reservations.create', 'reservations.edit',
        'reservations.checkin', 'reservations.checkout',
        'billing.view', 'billing.create', 'billing.payment',
        'messages.view',
      ],
      'Cashier': [
        'dashboard.view',
        'guests.view',
        'reservations.view',
        'billing.view', 'billing.create', 'billing.payment',
        'pos.view', 'pos.sales',
        'messages.view',
      ],
      'Staff': [
        'dashboard.view',
        'guests.view',
        'rooms.view',
        'reservations.view',
        'messages.view',
      ],
    };
  }

  /// Initialize roles and assign permissions
  Future<void> initializeRoles() async {
    try {
      final rolesPermissions = getDefaultRolesPermissions();
      final allPermissions = await _permissionService.getPermissions();
      
      // Create a map of permission key to permission ID
      final permissionKeyToId = <String, int>{};
      for (var perm in allPermissions) {
        if (perm.permissionId != null) {
          permissionKeyToId[perm.key] = perm.permissionId!;
        }
      }

      final existingRoles = await _roleService.getRoles();

      for (var entry in rolesPermissions.entries) {
        final roleName = entry.key;
        final permissionKeys = entry.value;

        // Check if role already exists
        var role = existingRoles.firstWhere(
          (r) => r.name.toLowerCase() == roleName.toLowerCase(),
          orElse: () => RoleModel(name: '', isSystemRole: true),
        );

        // Create role if it doesn't exist
        if (role.name.isEmpty) {
          role = await _roleService.createRole(
            RoleModel(
              name: roleName,
              description: 'Default $roleName role',
              isSystemRole: true,
            ),
          );
        }

        // Assign permissions (merge with existing, don't replace)
        if (role.roleId != null) {
          final newPermissionIds = permissionKeys
              .map((key) => permissionKeyToId[key])
              .whereType<int>()
              .toList();
          
          // Get existing permissions for this role
          final existingPermissionIds = await _roleService.getRolePermissions(role.roleId!);
          
          // Merge: combine existing and new, remove duplicates
          final allPermissionIds = {...existingPermissionIds, ...newPermissionIds}.toList();
          
          // Update role_permissions collection
          await _roleService.updateRolePermissions(role.roleId!, allPermissionIds);
          
          // Also update permissions array directly on role document (for faster access)
          final roleDocRef = _firestore.collection('roles').doc(role.roleId.toString());
          await roleDocRef.update({
            'permissions': permissionKeys, // Store permission keys as array
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to initialize roles: $e');
    }
  }

  /// Initialize both permissions and roles
  Future<void> initializeAll() async {
    await initializePermissions();
    await initializeRoles();
  }
}

