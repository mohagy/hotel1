/// Roles List Screen
/// 
/// Displays roles management page with permissions matrix

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/role_model.dart';
import '../../models/permission_model.dart';
import '../../services/role_service.dart';
import '../../services/permission_service.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../services/permissions_init_service.dart';
import 'role_form_screen.dart';

class RolesListScreen extends StatefulWidget {
  const RolesListScreen({super.key});

  @override
  State<RolesListScreen> createState() => _RolesListScreenState();
}

class _RolesListScreenState extends State<RolesListScreen> {
  final RoleService _roleService = RoleService();
  final PermissionService _permissionService = PermissionService();
  final PermissionsInitService _initService = PermissionsInitService();

  List<RoleModel> _roles = [];
  List<PermissionModel> _permissions = [];
  Map<int, List<int>> _rolePermissions = {}; // roleId -> [permissionIds]
  Map<String, List<PermissionModel>> _permissionsByCategory = {};

  bool _isLoading = true;
  bool _isInitializing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _initializePermissions() async {
    setState(() {
      _isInitializing = true;
      _error = null;
    });

    try {
      await _initService.initializeAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions and roles initialized successfully'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing: ${e.toString()}'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final roles = await _roleService.getRoles();
      final permissionsByCategory = await _permissionService.getPermissionsByCategory();
      final allPermissions = await _permissionService.getPermissions();

      // If no permissions exist, show initialization button
      if (allPermissions.isEmpty) {
        setState(() {
          _roles = roles;
          _permissions = [];
          _permissionsByCategory = {};
          _rolePermissions = {};
          _isLoading = false;
        });
        return;
      }

      // Load permissions for each role
      final Map<int, List<int>> rolePermissionsMap = {};
      for (var role in roles) {
        if (role.roleId != null) {
          final permissionIds = await _roleService.getRolePermissions(role.roleId!);
          rolePermissionsMap[role.roleId!] = permissionIds;
        }
      }

      setState(() {
        _roles = roles;
        _permissions = allPermissions;
        _permissionsByCategory = permissionsByCategory;
        _rolePermissions = rolePermissionsMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRole(RoleModel role) async {
    if (role.isSystemRole) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('System roles cannot be deleted'),
          backgroundColor: AppColors.statusError,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Role'),
        content: Text('Are you sure you want to delete "${role.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && role.roleId != null) {
      try {
        await _roleService.deleteRole(role.roleId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Role deleted successfully'),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting role: ${e.toString()}'),
              backgroundColor: AppColors.statusError,
            ),
          );
        }
      }
    }
  }

  void _showPermissionsMatrix(RoleModel role) {
    showDialog(
      context: context,
      builder: (context) => _PermissionsMatrixDialog(
        role: role,
        permissionsByCategory: _permissionsByCategory,
        selectedPermissionIds: _rolePermissions[role.roleId] ?? [],
        onSave: (permissionIds) async {
          if (role.roleId != null) {
            try {
              await _roleService.updateRolePermissions(role.roleId!, permissionIds);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Permissions updated successfully'),
                    backgroundColor: AppColors.statusSuccess,
                  ),
                );
                _loadData();
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating permissions: ${e.toString()}'),
                    backgroundColor: AppColors.statusError,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              if (_isInitializing) ...[
                const SizedBox(height: 20),
                const Text('Initializing permissions and roles...'),
              ],
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show initialization prompt if no permissions exist
    if (_permissions.isEmpty) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(30),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 20),
                const Text(
                  'No Permissions Found',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Initialize default permissions and roles for the hotel management system',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _initializePermissions,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Initialize Permissions & Roles'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'This will create default permissions and roles:\nOwner, Admin, Manager, Receptionist, Cashier, Staff',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            const SizedBox(height: 30),
            _buildRolesTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Roles & Permissions',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2c3e50),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Manage user roles and their permissions',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () async {
            await context.push('/roles/new');
            _loadData();
          },
          icon: const Icon(Icons.add),
          label: const Text('New Role'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3498db),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildRolesTable() {
    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Role Name', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Permissions', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
          rows: _roles.map((role) {
            final permissionCount = _rolePermissions[role.roleId]?.length ?? 0;
            return DataRow(
              cells: [
                DataCell(Text(role.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(Text(role.description ?? '-')),
                DataCell(Text('$permissionCount permissions')),
                DataCell(
                  Chip(
                    label: Text(role.isSystemRole ? 'System' : 'Custom'),
                    backgroundColor: role.isSystemRole ? Colors.blue[100] : Colors.green[100],
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: role.isSystemRole ? Colors.blue[800] : Colors.green[800],
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.security, size: 18),
                        onPressed: () => _showPermissionsMatrix(role),
                        color: const Color(0xFF3498db),
                        tooltip: 'Manage Permissions',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () async {
                          await context.push('/roles/${role.roleId}');
                          _loadData();
                        },
                        color: const Color(0xFF3498db),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      if (!role.isSystemRole)
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: () => _deleteRole(role),
                          color: Colors.red,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Permissions Matrix Dialog
class _PermissionsMatrixDialog extends StatefulWidget {
  final RoleModel role;
  final Map<String, List<PermissionModel>> permissionsByCategory;
  final List<int> selectedPermissionIds;
  final Function(List<int>) onSave;

  const _PermissionsMatrixDialog({
    required this.role,
    required this.permissionsByCategory,
    required this.selectedPermissionIds,
    required this.onSave,
  });

  @override
  State<_PermissionsMatrixDialog> createState() => _PermissionsMatrixDialogState();
}

class _PermissionsMatrixDialogState extends State<_PermissionsMatrixDialog> {
  late Set<int> _selectedPermissionIds;

  @override
  void initState() {
    super.initState();
    _selectedPermissionIds = widget.selectedPermissionIds.toSet();
  }

  void _togglePermission(int permissionId) {
    setState(() {
      if (_selectedPermissionIds.contains(permissionId)) {
        _selectedPermissionIds.remove(permissionId);
      } else {
        _selectedPermissionIds.add(permissionId);
      }
    });
  }

  void _toggleCategory(String category, List<PermissionModel> permissions) {
    final categoryPermissionIds = permissions.map((p) => p.permissionId).whereType<int>().toSet();
    final allSelected = categoryPermissionIds.every((id) => _selectedPermissionIds.contains(id));

    setState(() {
      if (allSelected) {
        // Deselect all in category
        _selectedPermissionIds.removeAll(categoryPermissionIds);
      } else {
        // Select all in category
        _selectedPermissionIds.addAll(categoryPermissionIds);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Permissions Matrix: ${widget.role.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Select permissions for this role',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.permissionsByCategory.entries.map((entry) {
                    final category = entry.key;
                    final permissions = entry.value;
                    final categoryPermissionIds = permissions.map((p) => p.permissionId).whereType<int>().toSet();
                    final allSelected = categoryPermissionIds.isNotEmpty &&
                        categoryPermissionIds.every((id) => _selectedPermissionIds.contains(id));
                    final someSelected = categoryPermissionIds.any((id) => _selectedPermissionIds.contains(id));

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Checkbox(
                              value: allSelected,
                              tristate: true,
                              onChanged: (value) => _toggleCategory(category, permissions),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${categoryPermissionIds.length} permissions)',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: permissions.map((permission) {
                                final isSelected = permission.permissionId != null &&
                                    _selectedPermissionIds.contains(permission.permissionId);
                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: permission.permissionId != null
                                      ? (value) => _togglePermission(permission.permissionId!)
                                      : null,
                                  title: Text(
                                    permission.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: permission.description != null
                                      ? Text(permission.description!)
                                      : Text(
                                          permission.key,
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      widget.onSave(_selectedPermissionIds.toList());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Permissions'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

