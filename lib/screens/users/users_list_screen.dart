/// Users List Screen
/// 
/// Displays users management page

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../models/role_model.dart';
import '../../services/user_service.dart';
import '../../services/role_service.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/common_widgets.dart';
import 'user_form_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final UserService _userService = UserService();
  final RoleService _roleService = RoleService();

  List<UserModel> _users = [];
  List<RoleModel> _roles = [];
  Map<int, String> _roleNames = {}; // roleId -> roleName (using role string from UserModel for now)

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _userService.getUsers();
      final roles = await _roleService.getRoles();

      // Create role name map (for now using the role string from UserModel)
      final Map<int, String> roleNamesMap = {};
      for (var role in roles) {
        if (role.roleId != null) {
          roleNamesMap[role.roleId!] = role.name;
        }
      }

      setState(() {
        _users = users;
        _roles = roles;
        _roleNames = roleNamesMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "${user.fullName}"?'),
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

    if (confirmed == true && user.userId != null) {
      try {
        await _userService.deleteUser(user.userId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted successfully'),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting user: ${e.toString()}'),
              backgroundColor: AppColors.statusError,
            ),
          );
        }
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = AppColors.statusSuccess;
        break;
      case 'inactive':
        color = AppColors.statusError;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    switch (role.toLowerCase()) {
      case 'admin':
        color = Colors.red;
        break;
      case 'manager':
        color = Colors.blue;
        break;
      case 'staff':
        color = Colors.green;
        break;
      case 'owner':
        color = Colors.purple;
        break;
      case 'receptionist':
        color = Colors.orange;
        break;
      case 'cashier':
        color = Colors.teal;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            const SizedBox(height: 30),
            _buildUsersTable(),
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
              'Users Management',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2c3e50),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Manage system users and their access',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () async {
            await context.push('/users/new');
            _loadData();
          },
          icon: const Icon(Icons.add),
          label: const Text('New User'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3498db),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTable() {
    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Username', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
          rows: _users.map((user) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryNavy.withOpacity(0.1),
                        child: Text(
                          user.fullName.isNotEmpty
                              ? user.fullName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: AppColors.primaryNavy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(user.username)),
                DataCell(Text(user.email ?? '-')),
                DataCell(_buildRoleBadge(user.role)),
                DataCell(_buildStatusBadge(user.status)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () async {
                          await context.push('/users/${user.userId}');
                          _loadData();
                        },
                        color: const Color(0xFF3498db),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: () => _deleteUser(user),
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

