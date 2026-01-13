/// POS Management Screen
/// 
/// Main POS management interface matching PHP dashboard layout
/// Includes mode selection (Retail, Restaurant, Reservation), metrics, and tabs

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/pos_service.dart';
import '../../services/reservation_service.dart';
import '../../services/room_service.dart';
import '../../services/billing_service.dart';
import '../../models/reservation_model.dart';
import '../../models/order_model.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/utils/formatters.dart';
import '../../config/app_config.dart';
import 'pos_terminal_screen.dart';

class POSManagementScreen extends StatefulWidget {
  const POSManagementScreen({super.key});

  @override
  State<POSManagementScreen> createState() => _POSManagementScreenState();
}

class _POSManagementScreenState extends State<POSManagementScreen> {
  final POSService _posService = POSService();
  final ReservationService _reservationService = ReservationService();
  final RoomService _roomService = RoomService();
  final BillingService _billingService = BillingService();

  String _currentMode = 'retail'; // 'retail', 'restaurant', 'reservation'
  String _currentSection = 'overview'; // Changes based on mode
  bool _isLoading = true;

  // Retail Metrics
  int _totalProducts = 0;
  int _totalCategories = 0;
  int _totalOrders = 0;
  double _todaySales = 0.0;

  // Restaurant Metrics
  int _restaurantMenuCount = 0;
  int _barMenuCount = 0;
  int _tableReservationsCount = 0;
  int _availableTables = 0;

  // Reservation Metrics
  int _hotelReservationsCount = 0;

  // Data Lists
  List<OrderModel> _recentOrders = [];
  List<ReservationModel> _hotelReservations = [];

  @override
  void initState() {
    super.initState();
    _loadSavedMode();
    _loadData();
  }

  Future<void> _loadSavedMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('pos_mode') ?? 'retail';
    setState(() {
      _currentMode = savedMode;
      // Set default section based on mode
      if (_currentMode == 'retail') {
        _currentSection = 'overview';
      } else if (_currentMode == 'restaurant') {
        _currentSection = 'menu';
      } else {
        _currentSection = 'hotel-reservations';
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load metrics in parallel
      await Future.wait([
        _loadRetailMetrics(),
        _loadRestaurantMetrics(),
        _loadReservationMetrics(),
        _loadRecentOrders(),
      ]);
    } catch (e) {
      debugPrint('Error loading POS data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRetailMetrics() async {
    try {
      final products = await _posService.getRetailProducts();
      final categories = await _posService.getCategories(mode: 'retail');
      final orders = await _posService.getHoldBills();

      // Calculate today's sales
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      double todaySales = 0.0;
      for (var order in orders) {
        if (order.createdAt != null) {
          final orderDate = DateTime(
            order.createdAt!.year,
            order.createdAt!.month,
            order.createdAt!.day,
          );
          if (orderDate.isAtSameMomentAs(todayDate) && order.status == 'completed') {
            todaySales += order.total ?? 0.0;
          }
        }
      }

      setState(() {
        _totalProducts = products.length;
        _totalCategories = categories.length;
        _totalOrders = orders.length;
        _todaySales = todaySales;
      });
    } catch (e) {
      debugPrint('Error loading retail metrics: $e');
    }
  }

  Future<void> _loadRestaurantMetrics() async {
    try {
      final menuItems = await _posService.getRestaurantMenuItems();
      // TODO: Load bar items, table reservations, available tables from API
      setState(() {
        _restaurantMenuCount = menuItems.length;
        _barMenuCount = 0; // TODO: Load from API
        _tableReservationsCount = 0; // TODO: Load from API
        _availableTables = 0; // TODO: Load from API
      });
    } catch (e) {
      debugPrint('Error loading restaurant metrics: $e');
    }
  }

  Future<void> _loadReservationMetrics() async {
    try {
      // Use getReservationsForPayment to get reservations from Firestore
      // This includes all reservations with balance_due > 0, which is what we want to show
      final reservations = await _reservationService.getReservationsForPayment();
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      final upcomingReservations = reservations.where((r) {
        final checkInDate = DateTime(
          r.checkInDate.year,
          r.checkInDate.month,
          r.checkInDate.day,
        );
        return (checkInDate.isAtSameMomentAs(todayDate) || checkInDate.isAfter(todayDate)) &&
            r.status != 'cancelled';
      }).toList();

      setState(() {
        _hotelReservationsCount = upcomingReservations.length;
      });
    } catch (e) {
      debugPrint('Error loading reservation metrics: $e');
    }
  }

  Future<void> _loadRecentOrders() async {
    try {
      final orders = await _posService.getHoldBills();
      // Sort by created date, most recent first
      orders.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      setState(() {
        _recentOrders = orders.take(10).toList();
      });
    } catch (e) {
      debugPrint('Error loading recent orders: $e');
    }
  }

  Future<void> _switchMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pos_mode', mode);

    setState(() {
      _currentMode = mode;
      // Set default section for mode
      if (mode == 'retail') {
        _currentSection = 'overview';
      } else if (mode == 'restaurant') {
        _currentSection = 'menu';
      } else {
        _currentSection = 'hotel-reservations';
      }
    });

    // Reload data for the new mode
    _loadData();
  }

  void _switchSection(String section) {
    setState(() {
      _currentSection = section;
    });

    // Load section-specific data
    if (section == 'categories' && _currentMode == 'retail') {
      // Categories will load when section is displayed
    } else if (section == 'menu' && _currentMode == 'restaurant') {
      // Menu will load when section is displayed
    } else if (section == 'hotel-reservations' && _currentMode == 'reservation') {
      _loadHotelReservations();
    }
  }

  Future<void> _loadHotelReservations() async {
    try {
      final reservations = await _reservationService.getReservationsForPayment();
      setState(() {
        _hotelReservations = reservations;
      });
    } catch (e) {
      debugPrint('Error loading hotel reservations: $e');
    }
  }

  void _openPOSTerminal() {
    context.go('/pos/terminal?mode=$_currentMode');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Page Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'POS Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2c3e50),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Manage your Point of Sale system - Select a mode to begin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _openPOSTerminal,
                  icon: const Icon(Icons.point_of_sale),
                  label: const Text('Open POS Terminal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498db),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Mode Selector
          Container(
            padding: const EdgeInsets.all(15),
            margin: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    icon: Icons.shopping_bag,
                    label: 'Retail',
                    subtitle: 'Products & Inventory',
                    mode: 'retail',
                    currentMode: _currentMode,
                    onTap: () => _switchMode('retail'),
                    activeColor: const Color(0xFF3498db),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeButton(
                    icon: Icons.restaurant,
                    label: 'Restaurant',
                    subtitle: 'Menu & Tables',
                    mode: 'restaurant',
                    currentMode: _currentMode,
                    onTap: () => _switchMode('restaurant'),
                    activeColor: const Color(0xFF27ae60),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeButton(
                    icon: Icons.calendar_today,
                    label: 'Reservation',
                    subtitle: 'Bookings & Reservations',
                    mode: 'reservation',
                    currentMode: _currentMode,
                    onTap: () => _switchMode('reservation'),
                    activeColor: const Color(0xFFf39c12),
                  ),
                ),
              ],
            ),
          ),

          // Metrics Cards
          if (_currentMode == 'retail')
            _RetailMetricsCards(
              totalProducts: _totalProducts,
              totalCategories: _totalCategories,
              todaySales: _todaySales,
              totalOrders: _totalOrders,
            )
          else if (_currentMode == 'restaurant')
            _RestaurantMetricsCards(
              menuItems: _restaurantMenuCount,
              barItems: _barMenuCount,
              tableReservations: _tableReservationsCount,
              availableTables: _availableTables,
            )
          else
            _ReservationMetricsCards(
              hotelReservations: _hotelReservationsCount,
              tableReservations: _tableReservationsCount,
              availableTables: _availableTables,
            ),

          const SizedBox(height: 30),

          // Navigation Tabs
          _buildNavigationTabs(),

          // Content Sections
          _buildCurrentSection(),
        ],
      ),
    );
  }

  Widget _buildNavigationTabs() {
    if (_currentMode == 'retail') {
      return _RetailTabs(
        currentSection: _currentSection,
        onSectionChange: _switchSection,
      );
    } else if (_currentMode == 'restaurant') {
      return _RestaurantTabs(
        currentSection: _currentSection,
        onSectionChange: _switchSection,
      );
    } else {
      return _ReservationTabs(
        currentSection: _currentSection,
        onSectionChange: _switchSection,
      );
    }
  }

  Widget _buildCurrentSection() {
    if (_currentMode == 'retail') {
      return _RetailSection(
        section: _currentSection,
        totalProducts: _totalProducts,
        totalCategories: _totalCategories,
        recentOrders: _recentOrders,
        onOpenTerminal: _openPOSTerminal,
      );
    } else if (_currentMode == 'restaurant') {
      return _RestaurantSection(
        section: _currentSection,
      );
    } else {
      return _ReservationSection(
        section: _currentSection,
        hotelReservations: _hotelReservations,
        onRefresh: _loadHotelReservations,
      );
    }
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final String mode;
  final String currentMode;
  final VoidCallback onTap;
  final Color activeColor;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.mode,
    required this.currentMode,
    required this.onTap,
    required this.activeColor,
  });

  bool get isActive => mode == currentMode;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(
            color: isActive ? activeColor : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isActive ? activeColor.withOpacity(0.1) : Colors.white,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? activeColor : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? activeColor : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RetailMetricsCards extends StatelessWidget {
  final int totalProducts;
  final int totalCategories;
  final double todaySales;
  final int totalOrders;

  const _RetailMetricsCards({
    required this.totalProducts,
    required this.totalCategories,
    required this.todaySales,
    required this.totalOrders,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.2,
        children: [
          _MetricCard(
            title: 'Total Products',
            value: totalProducts.toString(),
            icon: Icons.inventory_2,
            color: const Color(0xFF3498db),
            bgColor: const Color(0xFFe3f2fd),
          ),
          _MetricCard(
            title: 'Categories',
            value: totalCategories.toString(),
            icon: Icons.category,
            color: const Color(0xFF2ecc71),
            bgColor: const Color(0xFFe8f5e9),
          ),
          _MetricCard(
            title: "Today's Sales",
            value: '\$${todaySales.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: const Color(0xFFf39c12),
            bgColor: const Color(0xFFfff3e0),
          ),
          _MetricCard(
            title: 'Total Orders',
            value: totalOrders.toString(),
            icon: Icons.shopping_cart,
            color: const Color(0xFFe74c3c),
            bgColor: const Color(0xFFffebee),
          ),
        ],
      ),
    );
  }
}

class _RestaurantMetricsCards extends StatelessWidget {
  final int menuItems;
  final int barItems;
  final int tableReservations;
  final int availableTables;

  const _RestaurantMetricsCards({
    required this.menuItems,
    required this.barItems,
    required this.tableReservations,
    required this.availableTables,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.2,
        children: [
          _MetricCard(
            title: 'Menu Items',
            value: menuItems.toString(),
            icon: Icons.restaurant,
            color: const Color(0xFF27ae60),
            bgColor: const Color(0xFFe8f5e9),
          ),
          _MetricCard(
            title: 'Bar Items',
            value: barItems.toString(),
            icon: Icons.local_bar,
            color: const Color(0xFF3498db),
            bgColor: const Color(0xFFe3f2fd),
          ),
          _MetricCard(
            title: 'Table Reservations',
            value: tableReservations.toString(),
            icon: Icons.event,
            color: const Color(0xFFf39c12),
            bgColor: const Color(0xFFfff3e0),
          ),
          _MetricCard(
            title: 'Available Tables',
            value: availableTables.toString(),
            icon: Icons.table_restaurant,
            color: const Color(0xFF2ecc71),
            bgColor: const Color(0xFFe8f5e9),
          ),
        ],
      ),
    );
  }
}

class _ReservationMetricsCards extends StatelessWidget {
  final int hotelReservations;
  final int tableReservations;
  final int availableTables;

  const _ReservationMetricsCards({
    required this.hotelReservations,
    required this.tableReservations,
    required this.availableTables,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.5,
        children: [
          _MetricCard(
            title: 'Hotel Reservations',
            value: hotelReservations.toString(),
            icon: Icons.hotel,
            color: const Color(0xFFf39c12),
            bgColor: const Color(0xFFfff3e0),
          ),
          _MetricCard(
            title: 'Table Reservations',
            value: tableReservations.toString(),
            icon: Icons.calendar_today,
            color: const Color(0xFF3498db),
            bgColor: const Color(0xFFe3f2fd),
          ),
          _MetricCard(
            title: 'Available Tables',
            value: availableTables.toString(),
            icon: Icons.table_restaurant,
            color: const Color(0xFF2ecc71),
            bgColor: const Color(0xFFe8f5e9),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: color, width: 4),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2c3e50),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetailTabs extends StatelessWidget {
  final String currentSection;
  final Function(String) onSectionChange;

  const _RetailTabs({
    required this.currentSection,
    required this.onSectionChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 2)),
      ),
      child: Row(
        children: [
          _TabButton(
            icon: Icons.dashboard,
            label: 'Overview',
            section: 'overview',
            currentSection: currentSection,
            onTap: () => onSectionChange('overview'),
          ),
          _TabButton(
            icon: Icons.inventory_2,
            label: 'Products',
            section: 'products',
            currentSection: currentSection,
            onTap: () => onSectionChange('products'),
          ),
          _TabButton(
            icon: Icons.category,
            label: 'Categories',
            section: 'categories',
            currentSection: currentSection,
            onTap: () => onSectionChange('categories'),
          ),
          _TabButton(
            icon: Icons.shopping_cart,
            label: 'Orders',
            section: 'orders',
            currentSection: currentSection,
            onTap: () => onSectionChange('orders'),
          ),
          _TabButton(
            icon: Icons.settings,
            label: 'Settings',
            section: 'settings',
            currentSection: currentSection,
            onTap: () => onSectionChange('settings'),
          ),
        ],
      ),
    );
  }
}

class _RestaurantTabs extends StatelessWidget {
  final String currentSection;
  final Function(String) onSectionChange;

  const _RestaurantTabs({
    required this.currentSection,
    required this.onSectionChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 2)),
      ),
      child: Row(
        children: [
          _TabButton(
            icon: Icons.restaurant,
            label: 'Menu',
            section: 'menu',
            currentSection: currentSection,
            onTap: () => onSectionChange('menu'),
          ),
          _TabButton(
            icon: Icons.table_restaurant,
            label: 'Tables',
            section: 'tables',
            currentSection: currentSection,
            onTap: () => onSectionChange('tables'),
          ),
          _TabButton(
            icon: Icons.event,
            label: 'Reservations',
            section: 'reservations-list',
            currentSection: currentSection,
            onTap: () => onSectionChange('reservations-list'),
          ),
          _TabButton(
            icon: Icons.receipt,
            label: 'Orders',
            section: 'restaurant-orders',
            currentSection: currentSection,
            onTap: () => onSectionChange('restaurant-orders'),
          ),
        ],
      ),
    );
  }
}

class _ReservationTabs extends StatelessWidget {
  final String currentSection;
  final Function(String) onSectionChange;

  const _ReservationTabs({
    required this.currentSection,
    required this.onSectionChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 2)),
      ),
      child: Row(
        children: [
          _TabButton(
            icon: Icons.hotel,
            label: 'Hotel Bookings',
            section: 'hotel-reservations',
            currentSection: currentSection,
            onTap: () => onSectionChange('hotel-reservations'),
          ),
          _TabButton(
            icon: Icons.calendar_today,
            label: 'Table Reservations',
            section: 'table-reservations',
            currentSection: currentSection,
            onTap: () => onSectionChange('table-reservations'),
          ),
          _TabButton(
            icon: Icons.calendar_month,
            label: 'Calendar View',
            section: 'reservation-calendar',
            currentSection: currentSection,
            onTap: () => onSectionChange('reservation-calendar'),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String section;
  final String currentSection;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.section,
    required this.currentSection,
    required this.onTap,
  });

  bool get isActive => section == currentSection;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF3498db) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? const Color(0xFF3498db) : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF3498db) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Retail Sections
class _RetailSection extends StatelessWidget {
  final String section;
  final int totalProducts;
  final int totalCategories;
  final List<OrderModel> recentOrders;
  final VoidCallback onOpenTerminal;

  const _RetailSection({
    required this.section,
    required this.totalProducts,
    required this.totalCategories,
    required this.recentOrders,
    required this.onOpenTerminal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: _buildSectionContent(context),
    );
  }

  Widget _buildSectionContent(BuildContext context) {
    switch (section) {
      case 'overview':
        return _RetailOverviewSection(
          totalProducts: totalProducts,
          totalCategories: totalCategories,
          recentOrders: recentOrders,
          onOpenTerminal: onOpenTerminal,
        );
      case 'products':
        return _ProductsSection(onOpenTerminal: onOpenTerminal);
      case 'categories':
        return _CategoriesSection();
      case 'orders':
        return _OrdersSection(recentOrders: recentOrders);
      case 'settings':
        return _SettingsSection(onOpenTerminal: onOpenTerminal);
      default:
        return const SizedBox();
    }
  }
}

class _RetailOverviewSection extends StatelessWidget {
  final int totalProducts;
  final int totalCategories;
  final List<OrderModel> recentOrders;
  final VoidCallback onOpenTerminal;

  const _RetailOverviewSection({
    required this.totalProducts,
    required this.totalCategories,
    required this.recentOrders,
    required this.onOpenTerminal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Actions
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 1.5,
          children: [
            _QuickActionCard(
              icon: Icons.point_of_sale,
              title: 'Open POS Terminal',
              onTap: onOpenTerminal,
              color: const Color(0xFF3498db),
              bgColor: const Color(0xFFe3f2fd),
            ),
            _QuickActionCard(
              icon: Icons.inventory_2,
              title: 'Manage Products',
              onTap: () {
                // Navigate to products section
              },
              color: const Color(0xFF3498db),
              bgColor: const Color(0xFFe3f2fd),
            ),
            _QuickActionCard(
              icon: Icons.category,
              title: 'Manage Categories',
              onTap: () {
                // Navigate to categories section
              },
              color: const Color(0xFF3498db),
              bgColor: const Color(0xFFe3f2fd),
            ),
            _QuickActionCard(
              icon: Icons.shopping_cart,
              title: 'View Orders',
              onTap: () {
                // Navigate to orders section
              },
              color: const Color(0xFF3498db),
              bgColor: const Color(0xFFe3f2fd),
            ),
          ],
        ),
        const SizedBox(height: 30),

        // Recent Orders
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Recent Orders',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2c3e50),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 30),
                if (recentOrders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'No recent orders',
                        style: TextStyle(color: Color(0xFF999999)),
                      ),
                    ),
                  )
                else
                  ...recentOrders.map((order) => _OrderRow(order: order)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;
  final Color bgColor;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2c3e50),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final OrderModel order;

  const _OrderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2c3e50),
                  ),
                ),
                if (order.createdAt != null)
                  Text(
                    '${order.createdAt!.month}/${order.createdAt!.day}/${order.createdAt!.year} ${order.createdAt!.hour}:${order.createdAt!.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            Formatters.currency(order.total ?? 0.0),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2c3e50),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2ecc71).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              order.status?.toUpperCase() ?? 'UNKNOWN',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2ecc71),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsSection extends StatelessWidget {
  final VoidCallback onOpenTerminal;

  const _ProductsSection({required this.onOpenTerminal});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Products Management',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2c3e50),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onOpenTerminal,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open POS Terminal'),
                ),
              ],
            ),
            const Divider(height: 30),
            const Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.inventory_2, size: 48, color: Color(0xFF3498db)),
                  SizedBox(height: 20),
                  Text(
                    'Product Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2c3e50),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'For full product management including adding, editing, and bulk import, please use the dedicated POS Terminal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF666666)),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFf8f9fa),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2c3e50),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _ActionItem(icon: Icons.add, color: const Color(0xFF27ae60), text: 'Add new products'),
                  _ActionItem(icon: Icons.edit, color: const Color(0xFF3498db), text: 'Edit existing products'),
                  _ActionItem(icon: Icons.upload, color: const Color(0xFFf39c12), text: 'Bulk import products'),
                  _ActionItem(icon: Icons.bar_chart, color: const Color(0xFF9b59b6), text: 'View inventory reports'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _ActionItem({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesSection extends StatefulWidget {
  @override
  State<_CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<_CategoriesSection> {
  final POSService _posService = POSService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _posService.getCategories(mode: 'retail');
      setState(() {
        _categories = categories.map((c) => {
          'id': c['id'] ?? 0,
          'name': c['name'] ?? 'Unknown',
          'description': c['description'] ?? '',
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Categories Management',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2c3e50),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Show add category dialog
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New Category'),
                ),
              ],
            ),
            const Divider(height: 30),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_categories.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'No categories found. Click "Add New Category" to create one.',
                    style: TextStyle(color: Color(0xFF999999)),
                  ),
                ),
              )
            else
              ..._categories.map((category) => _CategoryItem(
                    category: category,
                    onEdit: () {
                      // TODO: Show edit dialog
                    },
                    onDelete: () {
                      // TODO: Show delete confirmation
                    },
                  )),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryItem({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2c3e50),
                  ),
                ),
                if (category['description'] != null && category['description'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      category['description'].toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, size: 18, color: Color(0xFFe74c3c)),
                label: const Text('Delete', style: TextStyle(color: Color(0xFFe74c3c))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrdersSection extends StatelessWidget {
  final List<OrderModel> recentOrders;

  const _OrdersSection({required this.recentOrders});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Orders History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2c3e50),
              ),
            ),
            const Divider(height: 30),
            if (recentOrders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'No orders found',
                    style: TextStyle(color: Color(0xFF999999)),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Order ID', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Total', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Date', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Status', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w600))),
                  ],
                  rows: recentOrders.map((order) {
                    return DataRow(
                      cells: [
                        DataCell(Text('${order.id ?? 'N/A'}', style: const TextStyle(fontSize: 13))),
                        DataCell(Text(Formatters.currency(order.total ?? 0.0), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                        DataCell(Text(
                          order.createdAt != null
                              ? '${order.createdAt!.month}/${order.createdAt!.day}/${order.createdAt!.year} ${order.createdAt!.hour}:${order.createdAt!.minute.toString().padLeft(2, '0')}'
                              : 'N/A',
                          style: const TextStyle(fontSize: 13),
                        )),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ecc71).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order.status?.toUpperCase() ?? 'UNKNOWN',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2ecc71),
                            ),
                          ),
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final VoidCallback onOpenTerminal;

  const _SettingsSection({required this.onOpenTerminal});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'POS Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2c3e50),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onOpenTerminal,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open POS Terminal'),
                ),
              ],
            ),
            const Divider(height: 30),
            const Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.settings, size: 48, color: Color(0xFF3498db)),
                  SizedBox(height: 20),
                  Text(
                    'POS Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2c3e50),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'For full POS settings management including store information, tax rates, and receipt settings, please use the dedicated POS Terminal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFf8f9fa),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Settings:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2c3e50),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _ActionItem(icon: Icons.store, color: const Color(0xFF27ae60), text: 'Store information'),
                  _ActionItem(icon: Icons.percent, color: const Color(0xFF3498db), text: 'Tax rates'),
                  _ActionItem(icon: Icons.receipt, color: const Color(0xFFf39c12), text: 'Receipt settings'),
                  _ActionItem(icon: Icons.print, color: const Color(0xFF9b59b6), text: 'Printer configuration'),
                  _ActionItem(icon: Icons.admin_panel_settings, color: const Color(0xFFe74c3c), text: 'User permissions'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Restaurant Sections
class _RestaurantSection extends StatelessWidget {
  final String section;

  const _RestaurantSection({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: _buildSectionContent(context),
    );
  }

  Widget _buildSectionContent(BuildContext context) {
    switch (section) {
      case 'menu':
        return const _MenuSection();
      case 'tables':
        return const _TablesSection();
      case 'reservations-list':
        return const _TableReservationsSection();
      case 'restaurant-orders':
        return const _RestaurantOrdersSection();
      default:
        return const SizedBox();
    }
  }
}

class _MenuSection extends StatefulWidget {
  const _MenuSection();

  @override
  State<_MenuSection> createState() => _MenuSectionState();
}

class _MenuSectionState extends State<_MenuSection> {
  final POSService _posService = POSService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _menuItems = [];

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _posService.getRestaurantMenuItems();
      // Group by category
      final grouped = <String, List<dynamic>>{};
      for (var item in items) {
        final category = item.categoryName ?? 'Uncategorized';
        if (!grouped.containsKey(category)) {
          grouped[category] = [];
        }
        grouped[category]!.add(item);
      }

      setState(() {
        _menuItems = grouped.entries.map((e) => {
          'category': e.key,
          'items': e.value,
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading menu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.restaurant, color: Color(0xFF2c3e50)),
                    SizedBox(width: 8),
                    Text(
                      'Restaurant Menu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2c3e50),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Open full menu in browser
                  },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('View Full Menu'),
                ),
              ],
            ),
            const Divider(height: 30),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_menuItems.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'No menu items found.',
                    style: TextStyle(color: Color(0xFF999999)),
                  ),
                ),
              )
            else
              ..._menuItems.map((group) => _MenuCategoryGroup(
                    category: group['category'] as String,
                    items: group['items'] as List,
                  )),
          ],
        ),
      ),
    );
  }
}

class _MenuCategoryGroup extends StatelessWidget {
  final String category;
  final List<dynamic> items;

  const _MenuCategoryGroup({
    required this.category,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.9,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.name ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2c3e50),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          Formatters.currency(item.price ?? 0.0),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF27ae60),
                          ),
                        ),
                      ],
                    ),
                    if (item.description != null && item.description.toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          item.description.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

class _TablesSection extends StatefulWidget {
  const _TablesSection();

  @override
  State<_TablesSection> createState() => _TablesSectionState();
}

class _TablesSectionState extends State<_TablesSection> {
  final POSService _posService = POSService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _tables = [];

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load tables from API
      // For now, show placeholder
      setState(() {
        _tables = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading tables: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.table_restaurant, color: Color(0xFF2c3e50)),
                    SizedBox(width: 8),
                    Text(
                      'Table Management',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2c3e50),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _loadTables,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const Divider(height: 30),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'Loading tables...',
                    style: TextStyle(color: Color(0xFF999999)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TableReservationsSection extends StatelessWidget {
  const _TableReservationsSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.event, color: Color(0xFF2c3e50)),
                    SizedBox(width: 8),
                    Text(
                      'Table Reservations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2c3e50),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Open restaurant portal
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Reservation'),
                ),
              ],
            ),
            const Divider(height: 30),
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Loading reservations...',
                  style: TextStyle(color: Color(0xFF999999)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantOrdersSection extends StatelessWidget {
  const _RestaurantOrdersSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt, color: Color(0xFF2c3e50)),
                SizedBox(width: 8),
                Text(
                  'Restaurant Orders',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2c3e50),
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Restaurant orders will be displayed here. Check the POS Terminal for full order management.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF999999)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reservation Sections
class _ReservationSection extends StatelessWidget {
  final String section;
  final List<ReservationModel> hotelReservations;
  final VoidCallback onRefresh;

  const _ReservationSection({
    required this.section,
    required this.hotelReservations,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: _buildSectionContent(context),
    );
  }

  Widget _buildSectionContent(BuildContext context) {
    switch (section) {
      case 'hotel-reservations':
        return _HotelReservationsSection(
          reservations: hotelReservations,
          onRefresh: onRefresh,
        );
      case 'table-reservations':
        return const _TableReservationsReservationSection();
      case 'reservation-calendar':
        return const _ReservationCalendarSection();
      default:
        return const SizedBox();
    }
  }
}

class _HotelReservationsSection extends StatelessWidget {
  final List<ReservationModel> reservations;
  final VoidCallback onRefresh;

  const _HotelReservationsSection({
    required this.reservations,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.hotel, color: Color(0xFF2c3e50)),
                    SizedBox(width: 8),
                    Text(
                      'Hotel Reservations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2c3e50),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context.go('/reservations');
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Booking'),
                ),
              ],
            ),
            const Divider(height: 30),
            if (reservations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.calendar_today, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 15),
                    const Text(
                      'No reservations found',
                      style: TextStyle(color: Color(0xFF999999)),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.go('/reservations');
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create New Reservation'),
                    ),
                  ],
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Reservation ID', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Guest', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Room', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Check-in', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Check-out', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Total', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Paid', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Balance', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Status', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w600))),
                  ],
                  rows: reservations.map((res) {
                    final balanceDue = res.balanceDue ?? 0.0;
                    final hasBalance = balanceDue > 0;
                    Color statusColor;
                    switch (res.status) {
                      case 'checked_in':
                        statusColor = const Color(0xFF2ecc71);
                        break;
                      case 'confirmed':
                      case 'reserved':
                        statusColor = const Color(0xFFf39c12);
                        break;
                      default:
                        statusColor = Colors.grey;
                    }

                    return DataRow(
                      cells: [
                        DataCell(Text(
                          res.reservationNumber ?? (res.reservationId != null ? '#${res.reservationId}' : 'N/A'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3498db),
                          ),
                        )),
                        DataCell(Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              res.guestName ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2c3e50),
                              ),
                            ),
                          ],
                        )),
                        DataCell(Text(res.roomNumber ?? 'N/A', style: const TextStyle(fontSize: 13))),
                        DataCell(Text(
                          '${res.checkInDate.month}/${res.checkInDate.day}/${res.checkInDate.year}',
                          style: const TextStyle(fontSize: 13),
                        )),
                        DataCell(Text(
                          '${res.checkOutDate.month}/${res.checkOutDate.day}/${res.checkOutDate.year}',
                          style: const TextStyle(fontSize: 13),
                        )),
                        DataCell(Text(
                          Formatters.currency(res.totalPrice ?? 0.0),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        )),
                        DataCell(Text(
                          Formatters.currency((res.totalPrice ?? 0.0) - (res.balanceDue ?? 0.0)),
                          style: const TextStyle(fontSize: 13, color: Color(0xFF27ae60)),
                        )),
                        DataCell(Text(
                          Formatters.currency(balanceDue),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: hasBalance ? const Color(0xFFe74c3c) : const Color(0xFF27ae60),
                          ),
                        )),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            res.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        )),
                        DataCell(
                          hasBalance
                              ? TextButton.icon(
                                  onPressed: () {
                                    context.go('/pos/terminal?mode=reservation&reservation_id=${res.reservationId}');
                                  },
                                  icon: const Icon(Icons.payment, size: 16),
                                  label: const Text('Pay Now', style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                )
                              : const Text(
                                  'Paid',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF27ae60),
                                  ),
                                ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFf8f9fa),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, size: 18, color: Color(0xFF666666)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Note: To process payments for reservations, switch to Reservation mode in the POS Terminal.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go('/pos/terminal?mode=reservation');
                    },
                    child: const Text('Open POS Terminal'),
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

class _TableReservationsReservationSection extends StatelessWidget {
  const _TableReservationsReservationSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_today, color: Color(0xFF2c3e50)),
                    SizedBox(width: 8),
                    Text(
                      'Table Reservations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2c3e50),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Open restaurant portal
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Reservation'),
                ),
              ],
            ),
            const Divider(height: 30),
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Loading reservations...',
                  style: TextStyle(color: Color(0xFF999999)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationCalendarSection extends StatelessWidget {
  const _ReservationCalendarSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_month, color: Color(0xFF2c3e50)),
                SizedBox(width: 8),
                Text(
                  'Calendar View',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2c3e50),
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Calendar view will display all reservations in a calendar format. This feature is coming soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF999999)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

