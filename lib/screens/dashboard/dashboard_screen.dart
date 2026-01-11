/// Dashboard Screen
/// 
/// Main dashboard showing key metrics and statistics
/// Matches the PHP dashboard layout exactly

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/utils/formatters.dart';
import '../../services/room_service.dart';
import '../../services/reservation_service.dart';
import '../../services/billing_service.dart';
import '../../models/room_model.dart';
import '../../models/reservation_model.dart';
import '../../models/billing_model.dart';
import '../../providers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final RoomService _roomService = RoomService();
  final ReservationService _reservationService = ReservationService();
  final BillingService _billingService = BillingService();

  int _totalRooms = 0;
  int _occupiedRooms = 0;
  int _availableRooms = 0;
  int _maintenanceRooms = 0;
  int _todayCheckIns = 0;
  double _todayRevenue = 0.0;
  List<ReservationModel> _recentBookings = [];
  List<RoomModel> _roomsOverview = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _roomService.getRooms(),
        _reservationService.getReservations(),
        _billingService.getInvoices(),
      ]);

      final rooms = results[0] as List<RoomModel>;
      final reservations = results[1] as List<ReservationModel>;
      final billings = results[2] as List<BillingModel>;

      // Calculate statistics
      _totalRooms = rooms.length;
      _occupiedRooms = rooms.where((r) => r.status == 'occupied').length;
      _availableRooms = rooms.where((r) => r.status == 'available').length;
      _maintenanceRooms = rooms.where((r) => r.status == 'maintenance').length;

      // Get today's date
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // Calculate today's check-ins
      _todayCheckIns = reservations.where((r) {
        final checkInDate = DateTime(
          r.checkInDate.year,
          r.checkInDate.month,
          r.checkInDate.day,
        );
        return checkInDate.isAtSameMomentAs(todayDate) &&
            (r.status == 'reserved' || r.status == 'checked_in');
      }).length;

      // Calculate today's revenue
      _todayRevenue = billings
          .where((b) {
            if (b.paidDate == null) return false;
            final paidDate = DateTime(
              b.paidDate!.year,
              b.paidDate!.month,
              b.paidDate!.day,
            );
            return paidDate.isAtSameMomentAs(todayDate) &&
                b.paymentStatus == 'paid';
          })
          .fold(0.0, (sum, b) => sum + (b.amount ?? 0.0));

      // Get recent bookings (5 most recent)
      _recentBookings = reservations.take(5).toList();

      // Get first 10 rooms for overview
      _roomsOverview = rooms.take(10).toList();
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';

    return _isLoading
          ? const LoadingWidget(message: 'Loading dashboard...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Grand Hotel',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2c3e50),
                            ),
                          ),
                          const SizedBox(height: 5),
                          _DateTimeDisplay(),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Welcome back, $userName!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2c3e50),
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Here's what's happening at Grand Hotel today.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Metrics Cards (4 in a row)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 1.2,
                    children: [
                      _MetricCard(
                        title: 'Total Rooms',
                        value: '$_totalRooms',
                        icon: Icons.door_front_door,
                        color: const Color(0xFF3498db),
                        bgColor: const Color(0xFFe3f2fd),
                      ),
                      _MetricCard(
                        title: 'Occupied Rooms',
                        value: '$_occupiedRooms',
                        icon: Icons.people,
                        color: const Color(0xFF2ecc71),
                        bgColor: const Color(0xFFe8f5e9),
                      ),
                      _MetricCard(
                        title: 'Check-ins Today',
                        value: '$_todayCheckIns',
                        icon: Icons.login,
                        color: const Color(0xFFf39c12),
                        bgColor: const Color(0xFFfff3e0),
                      ),
                      _MetricCard(
                        title: "Today's Revenue",
                        value: '\$${_todayRevenue.toStringAsFixed(0)}',
                        icon: Icons.attach_money,
                        color: const Color(0xFFe74c3c),
                        bgColor: const Color(0xFFffebee),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Quick Actions Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2c3e50),
                            ),
                          ),
                          const SizedBox(height: 20),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 4,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                            childAspectRatio: 1.5,
                            children: [
                              _QuickActionCard(
                                title: 'Check-in Guest',
                                icon: Icons.login,
                                color: const Color(0xFF3498db),
                                bgColor: const Color(0xFFe3f2fd),
                                onTap: () => context.go('/reservations'),
                              ),
                              _QuickActionCard(
                                title: 'Check-out Guest',
                                icon: Icons.logout,
                                color: const Color(0xFF2ecc71),
                                bgColor: const Color(0xFFe8f5e9),
                                onTap: () => context.go('/reservations'),
                              ),
                              _QuickActionCard(
                                title: 'New Reservation',
                                icon: Icons.calendar_today,
                                color: const Color(0xFF9c27b0),
                                bgColor: const Color(0xFFf3e5f5),
                                onTap: () => context.go('/reservations'),
                              ),
                              _QuickActionCard(
                                title: 'Create Invoice',
                                icon: Icons.receipt,
                                color: const Color(0xFFf39c12),
                                bgColor: const Color(0xFFfff3e0),
                                onTap: () => context.go('/billing/new'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Two Column Layout: Recent Bookings and Room Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recent Bookings
                      Expanded(
                        child: Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.event, color: Color(0xFF2c3e50)),
                                        SizedBox(width: 8),
                                        Text(
                                          'Recent Bookings',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2c3e50),
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: () => context.go('/reservations'),
                                      child: const Text(
                                        'View All',
                                        style: TextStyle(
                                          color: Color(0xFF3498db),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              if (_recentBookings.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Center(
                                    child: Text(
                                      'No recent bookings',
                                      style: TextStyle(color: Color(0xFF999999)),
                                    ),
                                  ),
                                )
                              else
                                _RecentBookingsTable(bookings: _recentBookings),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                      // Room Status Overview
                      Expanded(
                        child: Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.view_module, color: Color(0xFF2c3e50)),
                                        SizedBox(width: 8),
                                        Text(
                                          'Room Status Overview',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2c3e50),
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: () => context.go('/rooms'),
                                      child: const Text(
                                        'Manage Rooms',
                                        style: TextStyle(
                                          color: Color(0xFF3498db),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: _RoomStatusGrid(
                                  rooms: _roomsOverview,
                                  availableRooms: _availableRooms,
                                  occupiedRooms: _occupiedRooms,
                                  maintenanceRooms: _maintenanceRooms,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Recent Activity Section (simplified for now)
                  Card(
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
                                  Icon(Icons.history, color: Color(0xFF2c3e50)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Recent Activity',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2c3e50),
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  'See All',
                                  style: TextStyle(
                                    color: Color(0xFF3498db),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'No recent activity',
                                style: TextStyle(color: Color(0xFF999999)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Today's Check-ins Section
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.access_time, color: Color(0xFF2c3e50)),
                                  SizedBox(width: 8),
                                  Text(
                                    "Today's Check-ins",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2c3e50),
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => context.go('/reservations'),
                                child: const Text(
                                  'View All',
                                  style: TextStyle(
                                    color: Color(0xFF3498db),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              _todayCheckIns == 0
                                  ? 'No check-ins scheduled for today'
                                  : '$_todayCheckIns check-in(s) scheduled',
                              style: const TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 14,
                              ),
                            ),
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

class _DateTimeDisplay extends StatefulWidget {
  @override
  State<_DateTimeDisplay> createState() => _DateTimeDisplayState();
}

class _DateTimeDisplayState extends State<_DateTimeDisplay> {
  String _dateString = '';
  String _timeString = '';

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    // Update every minute
    final now = DateTime.now();
    Future.delayed(Duration(seconds: 60 - now.second), () {
      if (mounted) {
        _updateDateTime();
        _startTimer();
      }
    });
  }

  void _startTimer() {
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        _updateDateTime();
        _startTimer();
      }
    });
  }

  void _updateDateTime() {
    final now = DateTime.now();
    setState(() {
      _dateString = DateFormat('EEEE, MMMM d, y').format(now);
      _timeString = DateFormat('h:mm a').format(now);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '$_dateString • $_timeString',
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF666666),
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
      child: Padding(
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

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
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

class _RecentBookingsTable extends StatelessWidget {
  final List<ReservationModel> bookings;

  const _RecentBookingsTable({required this.bookings});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        dataRowHeight: 60,
        columns: const [
          DataColumn(label: Text('Guest Name', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Room No.', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Check-in', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Check-out', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Status', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w600))),
        ],
        rows: bookings.map((booking) {
          Color statusColor;
          String statusText;
          switch (booking.status) {
            case 'checked_in':
              statusColor = const Color(0xFF2ecc71);
              statusText = 'Checked In';
              break;
            case 'reserved':
              statusColor = const Color(0xFF3498db);
              statusText = 'Reserved';
              break;
            case 'checked_out':
              statusColor = Colors.grey;
              statusText = 'Checked Out';
              break;
            default:
              statusColor = Colors.grey;
              statusText = booking.status.toUpperCase();
          }

          return DataRow(
            cells: [
              DataCell(Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade300,
                    child: Text(
                      (booking.guestName ?? 'G')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(booking.guestName ?? 'N/A', style: const TextStyle(fontSize: 13)),
                ],
              )),
              DataCell(Text(booking.roomNumber ?? 'N/A', style: const TextStyle(fontSize: 13))),
              DataCell(Text(DateFormat('MMM d').format(booking.checkInDate), style: const TextStyle(fontSize: 13))),
              DataCell(Text(DateFormat('MMM d').format(booking.checkOutDate), style: const TextStyle(fontSize: 13))),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _RoomStatusGrid extends StatelessWidget {
  final List<RoomModel> rooms;
  final int availableRooms;
  final int occupiedRooms;
  final int maintenanceRooms;

  const _RoomStatusGrid({
    required this.rooms,
    required this.availableRooms,
    required this.occupiedRooms,
    required this.maintenanceRooms,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Room grid (5 columns)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            Color statusColor;
            switch (room.status) {
              case 'available':
                statusColor = const Color(0xFF2ecc71);
                break;
              case 'occupied':
                statusColor = const Color(0xFFe74c3c);
                break;
              case 'maintenance':
                statusColor = const Color(0xFFf39c12);
                break;
              default:
                statusColor = Colors.grey;
            }

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFf9f9f9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    room.roomNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2c3e50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    room.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 15),
        // Summary
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _RoomSummaryItem(
              value: availableRooms.toString(),
              label: 'Available',
              color: const Color(0xFF2ecc71),
            ),
            _RoomSummaryItem(
              value: occupiedRooms.toString(),
              label: 'Occupied',
              color: const Color(0xFFe74c3c),
            ),
            _RoomSummaryItem(
              value: maintenanceRooms.toString(),
              label: 'Maintenance',
              color: const Color(0xFFf39c12),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoomSummaryItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _RoomSummaryItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }
}
