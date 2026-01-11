/// Main Layout Widget
/// 
/// Provides consistent sidebar navigation and header across all pages
/// Matches the PHP dashboard layout structure

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/colors.dart';
import '../providers/auth_provider.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _sidebarCollapsed = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarCollapsed = !_sidebarCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          // Sidebar
          _Sidebar(
            collapsed: _sidebarCollapsed,
            currentRoute: widget.currentRoute,
            onToggle: _toggleSidebar,
          ),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Header
                _AppHeader(
                  searchController: _searchController,
                ),
                // Page Content
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final bool collapsed;
  final String currentRoute;
  final VoidCallback onToggle;

  const _Sidebar({
    required this.collapsed,
    required this.currentRoute,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: collapsed ? 70 : 250,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2c3e50), Color(0xFF34495e)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(3, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color.fromRGBO(255, 255, 255, 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(52, 152, 219, 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.hotel,
                    color: Color(0xFF3498db),
                    size: 20,
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Hotel Management',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Management System',
                          style: TextStyle(
                            color: Color.fromRGBO(255, 255, 255, 0.7),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 18),
                  onPressed: onToggle,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Navigation Menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 15),
              children: [
                _NavItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  route: '/dashboard',
                  currentRoute: currentRoute,
                  collapsed: collapsed,
                ),
                _NavItem(
                  icon: Icons.people,
                  label: 'Guests',
                  route: '/guests',
                  currentRoute: currentRoute,
                  collapsed: collapsed,
                ),
                _NavItem(
                  icon: Icons.door_front_door,
                  label: 'Rooms',
                  route: '/rooms',
                  currentRoute: currentRoute,
                  collapsed: collapsed,
                ),
                _NavItem(
                  icon: Icons.calendar_today,
                  label: 'Reservations',
                  route: '/reservations',
                  currentRoute: currentRoute,
                  collapsed: collapsed,
                ),
                _NavItem(
                  icon: Icons.credit_card,
                  label: 'Billing',
                  route: '/billing',
                  currentRoute: currentRoute,
                  collapsed: collapsed,
                ),
                _NavItem(
                  icon: Icons.bar_chart,
                  label: 'Reports',
                  route: '/reports',
                  currentRoute: currentRoute,
                  collapsed: collapsed,
                ),
                _NavItem(
                  icon: Icons.point_of_sale,
                  label: 'POS Management',
                  route: '/pos',
                  currentRoute: currentRoute,
                  collapsed: collapsed,
                ),
                _NavItem(
                  icon: Icons.message,
                  label: 'Messages',
                  route: '/messages',
                  currentRoute: currentRoute,
                  collapsed: collapsed,
                ),
                _NavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  route: '/settings',
                  currentRoute: currentRoute,
                  collapsed: collapsed,
                ),
                const Divider(color: Color.fromRGBO(255, 255, 255, 0.1), height: 20),
                _NavItem(
                  icon: Icons.people_outline,
                  label: 'Users',
                  route: '/users',
                  currentRoute: currentRoute,
                  collapsed: collapsed,
                ),
                _NavItem(
                  icon: Icons.security,
                  label: 'Roles & Permissions',
                  route: '/roles',
                  currentRoute: currentRoute,
                  collapsed: collapsed,
                ),
              ],
            ),
          ),
          // Sidebar Footer - User Info
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.user;
              return Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Color.fromRGBO(255, 255, 255, 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color.fromRGBO(255, 255, 255, 0.1),
                        child: Text(
                          user?.displayName?.substring(0, 1).toUpperCase() ?? 
                          user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      if (!collapsed) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? user?.email ?? 'User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Admin',
                                style: TextStyle(
                                  color: Color.fromRGBO(255, 255, 255, 0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final bool collapsed;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    required this.collapsed,
  });

  bool get isActive {
    if (route == '/dashboard') {
      return currentRoute == '/dashboard' || currentRoute == '/';
    }
    return currentRoute.startsWith(route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? const Color.fromRGBO(52, 152, 219, 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? const Border(
                left: BorderSide(color: Color(0xFF3498db), width: 4),
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            context.go(route);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 10 : 20,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? const Color(0xFF3498db) : const Color.fromRGBO(255, 255, 255, 0.8),
                  size: 18,
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isActive
                            ? const Color(0xFF3498db)
                            : const Color.fromRGBO(255, 255, 255, 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  final TextEditingController searchController;

  const _AppHeader({required this.searchController});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: const Color(0xFFf5f7fa),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF95a5a6), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search guests, rooms, reservations...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Color(0xFF95a5a6), fontSize: 14),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Notifications
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Color(0xFF2c3e50)),
                onPressed: () {
                  context.go('/messages');
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFFe74c3c),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Messages
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.message_outlined, color: Color(0xFF2c3e50)),
                onPressed: () {
                  context.go('/messages');
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFFe74c3c),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // User Profile
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFe9ecef),
                    child: Text(
                      user?.displayName?.substring(0, 1).toUpperCase() ??
                      user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(color: Color(0xFF6c757d), fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user?.displayName ?? user?.email ?? 'User',
                    style: const TextStyle(
                      color: Color(0xFF2c3e50),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Color(0xFF2c3e50)),
                ],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 18),
                    SizedBox(width: 12),
                    Text('My Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 18),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'password',
                child: Row(
                  children: [
                    Icon(Icons.lock, size: 18),
                    SizedBox(width: 12),
                    Text('Change Password'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Color(0xFFe74c3c), size: 18),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Color(0xFFe74c3c))),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  // TODO: Navigate to profile
                  break;
                case 'settings':
                  context.go('/settings');
                  break;
                case 'password':
                  // TODO: Navigate to change password
                  break;
                case 'logout':
                  authProvider.signOut();
                  context.go('/login');
                  break;
              }
            },
          ),
        ],
      ),
    );
  }
}

