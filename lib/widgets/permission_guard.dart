/// Permission Guard Widget
/// 
/// Wraps a child widget and checks if the user has the required permission.
/// Shows an access denied screen if the user doesn't have permission.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/permission_provider.dart';
import '../providers/auth_provider.dart';

class PermissionGuard extends StatelessWidget {
  final Widget child;
  final String? requiredPermission;
  final List<String>? anyPermissions; // User needs at least one of these
  final List<String>? allPermissions; // User needs all of these
  final Widget? accessDeniedWidget;

  const PermissionGuard({
    super.key,
    required this.child,
    this.requiredPermission,
    this.anyPermissions,
    this.allPermissions,
    this.accessDeniedWidget,
  }) : assert(
          requiredPermission != null || anyPermissions != null || allPermissions != null,
          'At least one permission check must be provided',
        );

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PermissionProvider>(
      builder: (context, authProvider, permissionProvider, _) {
        // Check if user is authenticated
        if (!authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if permissions are still loading
        if (permissionProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check permissions
        bool hasPermission = false;

        if (requiredPermission != null) {
          hasPermission = permissionProvider.hasPermission(requiredPermission!);
        } else if (anyPermissions != null && anyPermissions!.isNotEmpty) {
          hasPermission = permissionProvider.hasAnyPermission(anyPermissions!);
        } else if (allPermissions != null && allPermissions!.isNotEmpty) {
          hasPermission = permissionProvider.hasAllPermissions(allPermissions!);
        }

        if (!hasPermission) {
          return accessDeniedWidget ?? _defaultAccessDeniedWidget(context);
        }

        return child;
      },
    );
  }

  Widget _defaultAccessDeniedWidget(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You do not have permission to access this page.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  context.go('/dashboard');
                },
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

