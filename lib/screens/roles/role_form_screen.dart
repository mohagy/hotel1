/// Role Form Screen
/// 
/// Create or edit role information

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/role_model.dart';
import '../../services/role_service.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';

class RoleFormScreen extends StatefulWidget {
  final int? roleId;

  const RoleFormScreen({super.key, this.roleId});

  @override
  State<RoleFormScreen> createState() => _RoleFormScreenState();
}

class _RoleFormScreenState extends State<RoleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final RoleService _roleService = RoleService();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.roleId != null) {
      _loadRole();
    }
  }

  Future<void> _loadRole() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final role = await _roleService.getRoleById(widget.roleId!);
      if (role != null && mounted) {
        _nameController.text = role.name;
        _descriptionController.text = role.description ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading role: ${e.toString()}'),
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
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveRole() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final role = RoleModel(
        roleId: widget.roleId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isSystemRole: false,
      );

      if (widget.roleId == null) {
        await _roleService.createRole(role);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Role created successfully'),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
          context.pop();
        }
      } else {
        await _roleService.updateRole(role);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Role updated successfully'),
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
        title: Text(widget.roleId == null ? 'New Role' : 'Edit Role'),
      ),
      body: _isLoading && widget.roleId != null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Role Name *',
                        hintText: 'e.g., Manager, Staff',
                      ),
                      validator: (value) => Validators.required(value, 'Role name'),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Brief description of this role',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveRole,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(widget.roleId == null ? 'Create Role' : 'Update Role'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

