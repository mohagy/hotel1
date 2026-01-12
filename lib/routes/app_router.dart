/// App Router Configuration
/// 
/// Navigation routing using go_router

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/guests/guests_list_screen.dart';
import '../screens/guests/guest_form_screen.dart';
import '../screens/rooms/rooms_list_screen.dart';
import '../screens/reservations/reservations_list_screen.dart';
import '../screens/reservations/reservation_form_screen.dart';
import '../screens/roles/roles_list_screen.dart';
import '../screens/roles/role_form_screen.dart';
import '../screens/users/users_list_screen.dart';
import '../screens/users/user_form_screen.dart';
import '../screens/pos/pos_terminal_screen.dart';
import '../screens/pos/pos_management_screen.dart';
import '../screens/billing/billing_list_screen.dart';
import '../screens/billing/billing_detail_screen.dart';
import '../screens/billing/billing_form_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/messages/messages_list_screen.dart';
import '../screens/messages/chat_screen.dart';
import '../screens/rooms/room_form_screen.dart';
import '../screens/landing/landing_page_screen.dart';
import '../screens/landing/landing_page_management_screen.dart';
import '../services/room_service.dart';
import '../services/guest_service.dart';
import '../models/guest_model.dart';
import '../models/room_model.dart';
import '../widgets/main_layout.dart';
import '../widgets/permission_guard.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // Public Landing Page (no authentication required)
      GoRoute(
        path: '/landing',
        builder: (context, state) => const LandingPageScreen(),
      ),
      // POS Terminal - Standalone (outside MainLayout)
      GoRoute(
        path: '/pos/terminal',
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'];
          final reservationId = state.uri.queryParameters['reservation_id'];
          return POSTerminalScreen(
            initialMode: mode,
            initialReservationId: reservationId != null ? int.tryParse(reservationId) : null,
          );
        },
      ),
      // Main Layout Shell Route for authenticated pages
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(
            currentRoute: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => PermissionGuard(
              requiredPermission: 'dashboard.view',
              child: const DashboardScreen(),
            ),
          ),
          // Guests Routes
          GoRoute(
            path: '/guests',
            builder: (context, state) => PermissionGuard(
              requiredPermission: 'guests.view',
              child: const GuestsListScreen(),
            ),
          ),
          GoRoute(
            path: '/guests/new',
            builder: (context, state) => PermissionGuard(
              requiredPermission: 'guests.create',
              child: const GuestFormScreen(),
            ),
          ),
          GoRoute(
            path: '/guests/:id',
            builder: (context, state) {
              final guestId = int.tryParse(state.pathParameters['id'] ?? '');
              return PermissionGuard(
                requiredPermission: 'guests.edit',
                child: GuestFormScreen(guestId: guestId),
              );
            },
          ),
          // Rooms Routes
          GoRoute(
            path: '/rooms',
            builder: (context, state) => PermissionGuard(
              requiredPermission: 'rooms.view',
              child: const RoomsListScreen(),
            ),
          ),
          GoRoute(
            path: '/rooms/new',
            builder: (context, state) => PermissionGuard(
              requiredPermission: 'rooms.create',
              child: const RoomFormScreen(),
            ),
          ),
          GoRoute(
            path: '/rooms/:id',
            builder: (context, state) {
              final roomId = int.tryParse(state.pathParameters['id'] ?? '');
              return PermissionGuard(
                requiredPermission: 'rooms.edit',
                child: RoomFormScreen(roomId: roomId),
              );
            },
          ),
          // Reservations Routes
          GoRoute(
            path: '/reservations',
            builder: (context, state) => PermissionGuard(
              requiredPermission: 'reservations.view',
              child: const ReservationsListScreen(),
            ),
          ),
          GoRoute(
            path: '/reservations/new',
            builder: (context, state) => PermissionGuard(
              requiredPermission: 'reservations.create',
              child: const ReservationFormScreen(),
            ),
          ),
          GoRoute(
            path: '/reservations/:id',
            builder: (context, state) {
              final reservationId = int.tryParse(state.pathParameters['id'] ?? '');
              return PermissionGuard(
                requiredPermission: 'reservations.edit',
                child: ReservationFormScreen(reservationId: reservationId),
              );
            },
          ),
          // POS Routes
          GoRoute(
            path: '/pos',
            builder: (context, state) => PermissionGuard(
              requiredPermission: 'pos.view',
              child: const POSManagementScreen(),
            ),
          ),
          // Billing Routes
          GoRoute(
            path: '/billing',
            builder: (context, state) => PermissionGuard(
              requiredPermission: 'billing.view',
              child: const BillingListScreen(),
            ),
          ),
          GoRoute(
            path: '/billing/new',
            builder: (context, state) => PermissionGuard(
              requiredPermission: 'billing.create',
              child: const BillingFormScreen(),
            ),
          ),
          GoRoute(
            path: '/billing/:id',
            builder: (context, state) {
              final billingId = int.parse(state.pathParameters['id']!);
              return PermissionGuard(
                requiredPermission: 'billing.view',
                child: BillingDetailScreen(billingId: billingId),
              );
            },
          ),
          GoRoute(
            path: '/billing/:id/edit',
            builder: (context, state) {
              // TODO: Load billing from service and pass to form screen
              return PermissionGuard(
                requiredPermission: 'billing.edit',
                child: const BillingFormScreen(billing: null), // Placeholder
              );
            },
          ),
          // Reports Routes
          GoRoute(
            path: '/reports',
            builder: (context, state) => PermissionGuard(
              requiredPermission: 'reports.view',
              child: const ReportsScreen(),
            ),
          ),
          // Settings Routes
          GoRoute(
            path: '/settings',
            builder: (context, state) => PermissionGuard(
              requiredPermission: 'settings.view',
              child: const SettingsScreen(),
            ),
          ),
          // Landing Page Routes
          GoRoute(
            path: '/landing-page',
            builder: (context, state) => PermissionGuard(
              requiredPermission: 'settings.view',
              child: const LandingPageManagementScreen(),
            ),
          ),
          // Messages Routes
          GoRoute(
            path: '/messages',
            builder: (context, state) => PermissionGuard(
              requiredPermission: 'messages.view',
              child: const MessagesListScreen(),
            ),
          ),
          GoRoute(
            path: '/messages/chat',
            builder: (context, state) {
              final conversationId = state.uri.queryParameters['conversationId'] ?? '';
              final isGroupChat = state.uri.queryParameters['isGroupChat'] == 'true';
              final title = state.uri.queryParameters['title'];
              final otherParticipantId = state.uri.queryParameters['otherParticipantId'];
              final otherParticipantName = state.uri.queryParameters['otherParticipantName'] ?? 'Unknown';
              return PermissionGuard(
                requiredPermission: 'messages.view',
                child: ChatScreen(
                  conversationId: conversationId,
                  isGroupChat: isGroupChat,
                  title: title,
                  otherParticipantId: otherParticipantId,
                  otherParticipantName: otherParticipantName,
                ),
              );
            },
          ),
          // Roles & Permissions Routes
          GoRoute(
            path: '/roles',
            builder: (context, state) => PermissionGuard(
              requiredPermission: 'roles.manage',
              child: const RolesListScreen(),
            ),
          ),
          GoRoute(
            path: '/roles/new',
            builder: (context, state) => PermissionGuard(
              requiredPermission: 'roles.manage',
              child: const RoleFormScreen(),
            ),
          ),
          GoRoute(
            path: '/roles/:id',
            builder: (context, state) {
              final roleId = int.tryParse(state.pathParameters['id'] ?? '');
              return PermissionGuard(
                requiredPermission: 'roles.manage',
                child: RoleFormScreen(roleId: roleId),
              );
            },
          ),
          // Users Routes
          GoRoute(
            path: '/users',
            builder: (context, state) => PermissionGuard(
              requiredPermission: 'users.view',
              child: const UsersListScreen(),
            ),
          ),
          GoRoute(
            path: '/users/new',
            builder: (context, state) => PermissionGuard(
              requiredPermission: 'users.create',
              child: const UserFormScreen(),
            ),
          ),
          GoRoute(
            path: '/users/:id',
            builder: (context, state) {
              // userId can be int or string (Firebase UID)
              final idParam = state.pathParameters['id'] ?? '';
              final userId = int.tryParse(idParam) ?? idParam; // Try int first, fallback to string
              return PermissionGuard(
                requiredPermission: 'users.edit',
                child: UserFormScreen(userId: userId),
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}

