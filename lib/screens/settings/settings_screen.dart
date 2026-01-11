/// Settings Screen
/// 
/// Application settings and configuration

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _language = 'English';
  String _currency = 'USD';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.blue,
                      child: Text(
                        user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.email ?? 'User',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.uid ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // TODO: Navigate to profile edit screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile editing coming soon')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Preferences Section
            const Text(
              'Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    subtitle: const Text('Receive push notifications'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use dark theme'),
                    value: _darkModeEnabled,
                    onChanged: (value) {
                      setState(() => _darkModeEnabled = value);
                      // TODO: Implement dark mode toggle
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dark mode coming soon')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Language'),
                    subtitle: Text(_language),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showLanguageDialog();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Currency'),
                    subtitle: Text(_currency),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showCurrencyDialog();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Application Section
            const Text(
              'Application',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About'),
                    subtitle: const Text('Version 1.0.0'),
                    onTap: () {
                      _showAboutDialog();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Help & Support'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to help screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help & Support coming soon')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to privacy policy
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy Policy coming soon')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Terms of Service'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to terms of service
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Terms of Service coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account Section
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showChangePasswordDialog();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.red),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.red),
                    onTap: () {
                      _showSignOutDialog(context, authProvider);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value ?? 'English');
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Spanish'),
              value: 'Spanish',
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value ?? 'English');
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('French'),
              value: 'French',
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value ?? 'English');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('USD - US Dollar'),
              value: 'USD',
              groupValue: _currency,
              onChanged: (value) {
                setState(() => _currency = value ?? 'USD');
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('EUR - Euro'),
              value: 'EUR',
              groupValue: _currency,
              onChanged: (value) {
                setState(() => _currency = value ?? 'USD');
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('GBP - British Pound'),
              value: 'GBP',
              groupValue: _currency,
              onChanged: (value) {
                setState(() => _currency = value ?? 'USD');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Hotel Management System',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.hotel, size: 48),
      children: [
        const Text('A comprehensive hotel management system built with Flutter and Firebase.'),
      ],
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement password change
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password change coming soon')),
              );
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

