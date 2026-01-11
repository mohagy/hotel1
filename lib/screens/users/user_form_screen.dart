/// User Form Screen
/// 
/// Create or edit user information

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../models/role_model.dart';
import '../../services/user_service.dart';
import '../../services/role_service.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';

class UserFormScreen extends StatefulWidget {
  final dynamic userId; // Can be int (legacy) or String (Firebase UID)

  const UserFormScreen({super.key, this.userId});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  final RoleService _roleService = RoleService();
  bool _isLoading = false;
  bool _isLoadingRoles = false;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _role = 'staff';
  String _status = 'active';
  List<RoleModel> _roles = [];

  @override
  void initState() {
    super.initState();
    _loadRoles();
    if (widget.userId != null) {
      _loadUser();
    }
  }

  Future<void> _loadRoles() async {
    setState(() {
      _isLoadingRoles = true;
    });
    try {
      final roles = await _roleService.getRoles();
      if (mounted) {
        setState(() {
          _roles = roles;
          _isLoadingRoles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRoles = false;
        });
      }
    }
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = await _userService.getUserById(widget.userId!);
      if (user != null && mounted) {
        _usernameController.text = user.username;
        _emailController.text = user.email ?? '';
        _fullNameController.text = user.fullName;
        _role = user.role;
        _status = user.status;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user: ${e.toString()}'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate password if creating new user
    if (widget.userId == null) {
      if (_passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password is required for new users'),
            backgroundColor: AppColors.statusError,
          ),
        );
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: AppColors.statusError,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = UserModel(
        userId: widget.userId,
        username: _usernameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        role: _role,
        status: _status,
      );

      if (widget.userId == null) {
        // Create user with password using Firebase Auth
        await _userService.createUser(user, password: _passwordController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User created successfully'),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
          context.pop();
        }
      } else {
        await _userService.updateUser(user);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User updated successfully'),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userId == null ? 'New User' : 'Edit User'),
      ),
      body: _isLoading && widget.userId != null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username *',
                        hintText: 'Enter username',
                      ),
                      validator: (value) => Validators.required(value, 'Username'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'Enter full name',
                      ),
                      validator: (value) => Validators.required(value, 'Full name'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter email address',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          return Validators.email(value);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _isLoadingRoles
                        ? const CircularProgressIndicator()
                        : DropdownButtonFormField<String>(
                            value: _role,
                            decoration: const InputDecoration(
                              labelText: 'Role *',
                              hintText: 'Select a role',
                            ),
                            items: _roles.isEmpty
                                ? [
                                    const DropdownMenuItem(value: 'staff', child: Text('Staff')),
                                    const DropdownMenuItem(value: 'manager', child: Text('Manager')),
                                    const DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                  ]
                                : _roles.map((role) {
                                    return DropdownMenuItem<String>(
                                      value: role.name.toLowerCase(),
                                      child: Text(role.name),
                                    );
                                  }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _role = value;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a role';
                              }
                              return null;
                            },
                          ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status *',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _status = value;
                          });
                        }
                      },
                    ),
                    if (widget.userId == null) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password *',
                          hintText: 'Enter password',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (widget.userId == null && (value == null || value.isEmpty)) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password *',
                          hintText: 'Confirm password',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (widget.userId == null) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveUser,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(widget.userId == null ? 'Create User' : 'Update User'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

