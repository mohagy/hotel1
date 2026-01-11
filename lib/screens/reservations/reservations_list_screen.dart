/// Reservations List Screen
/// 
/// Displays reservations management page matching PHP reservations.php layout
/// Includes metrics, filters, today's check-ins, and all reservations table

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/reservation_model.dart';
import '../../services/reservation_service.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/utils/formatters.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ReservationsListScreen extends StatefulWidget {
  const ReservationsListScreen({super.key});

  @override
  State<ReservationsListScreen> createState() => _ReservationsListScreenState();
}

class _ReservationsListScreenState extends State<ReservationsListScreen> {
  final ReservationService _reservationService = ReservationService();
  
  List<ReservationModel> _allReservations = [];
  List<ReservationModel> _todaysCheckIns = [];
  
  // Statistics
  int _totalReservations = 0;
  int _checkedInReservations = 0;
  int _pendingCheckIns = 0;
  int _cancelledReservations = 0;
  
  // Filters
  String? _statusFilter;
  String? _dateFilter;
  String? _roomTypeFilter;
  String _viewType = 'list'; // 'list' or 'calendar'
  
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
      final reservations = await _reservationService.getReservations();
      
      // Calculate statistics
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      final checkedIn = reservations.where((r) => r.status == 'checked_in').length;
      final pending = reservations.where((r) {
        if (r.status != 'reserved' && r.status != 'confirmed') return false;
        final checkInDate = DateTime(r.checkInDate.year, r.checkInDate.month, r.checkInDate.day);
        return checkInDate.isAtSameMomentAs(todayStart);
      }).length;
      final cancelled = reservations.where((r) => r.status == 'cancelled').length;
      
      // Get today's check-ins (pending/confirmed for today)
      final todaysCheckInsList = reservations.where((r) {
        if (r.status != 'reserved' && r.status != 'confirmed') return false;
        final checkInDate = DateTime(r.checkInDate.year, r.checkInDate.month, r.checkInDate.day);
        return checkInDate.isAtSameMomentAs(todayStart);
      }).take(5).toList();
      
      setState(() {
        _allReservations = reservations;
        _todaysCheckIns = todaysCheckInsList;
        _totalReservations = reservations.length;
        _checkedInReservations = checkedIn;
        _pendingCheckIns = pending;
        _cancelledReservations = cancelled;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<ReservationModel> get _filteredReservations {
    var reservations = List<ReservationModel>.from(_allReservations);
    
    // Filter by status
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      reservations = reservations.where((r) => r.status == _statusFilter).toList();
    }
    
    // Filter by date range
    if (_dateFilter != null && _dateFilter!.isNotEmpty) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      reservations = reservations.where((r) {
        final checkInDate = DateTime(r.checkInDate.year, r.checkInDate.month, r.checkInDate.day);
        switch (_dateFilter) {
          case 'today':
            return checkInDate.isAtSameMomentAs(today);
          case 'week':
            final weekStart = today.subtract(Duration(days: today.weekday - 1));
            return checkInDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                   checkInDate.isBefore(weekStart.add(const Duration(days: 7)));
          case 'month':
            return checkInDate.year == now.year && checkInDate.month == now.month;
          default:
            return true;
        }
      }).toList();
    }
    
    // Filter by room type
    if (_roomTypeFilter != null && _roomTypeFilter!.isNotEmpty) {
      reservations = reservations.where((r) => r.roomType == _roomTypeFilter).toList();
    }
    
    // Sort by check-in date (most recent first)
    reservations.sort((a, b) => b.checkInDate.compareTo(a.checkInDate));
    
    return reservations;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingWidget(message: 'Loading reservations...')),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: ErrorDisplayWidget(
          message: _error!,
          onRetry: _loadData,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          _buildPageHeader(),
          const SizedBox(height: 30),
          
          // Metrics Cards
          _buildMetricsCards(),
          const SizedBox(height: 30),
          
          // Filters and View Options
          _buildFiltersSection(),
          const SizedBox(height: 25),
          
          // Today's Check-ins Section
          _buildTodaysCheckInsSection(),
          const SizedBox(height: 30),
          
          // All Reservations Section
          _buildAllReservationsSection(),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reservations Management',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2c3e50),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Manage all hotel bookings, check-ins, and reservations',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsCards() {
    return Row(
      children: [
        Expanded(child: _MetricCard(
          title: 'Total Reservations',
          value: _totalReservations.toString(),
          icon: Icons.calendar_today,
          color: const Color(0xFF3498db),
        )),
        const SizedBox(width: 20),
        Expanded(child: _MetricCard(
          title: 'Checked In',
          value: _checkedInReservations.toString(),
          icon: Icons.check_circle,
          color: const Color(0xFF2ecc71),
        )),
        const SizedBox(width: 20),
        Expanded(child: _MetricCard(
          title: 'Pending Check-ins',
          value: _pendingCheckIns.toString(),
          icon: Icons.access_time,
          color: const Color(0xFFf39c12),
        )),
        const SizedBox(width: 20),
        Expanded(child: _MetricCard(
          title: 'Cancellations',
          value: _cancelledReservations.toString(),
          icon: Icons.cancel,
          color: const Color(0xFFe74c3c),
        )),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Row(
      children: [
        // Status Filter
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STATUS',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: _statusFilter,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFFdddddd)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Statuses')),
                  DropdownMenuItem(value: 'checked_in', child: Text('Checked In')),
                  DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                  DropdownMenuItem(value: 'reserved', child: Text('Reserved')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (value) {
                  setState(() => _statusFilter = value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        
        // Date Range Filter
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DATE RANGE',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: _dateFilter,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFFdddddd)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Dates')),
                  DropdownMenuItem(value: 'today', child: Text('Today')),
                  DropdownMenuItem(value: 'week', child: Text('This Week')),
                  DropdownMenuItem(value: 'month', child: Text('This Month')),
                ],
                onChanged: (value) {
                  setState(() => _dateFilter = value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        
        // Room Type Filter
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ROOM TYPE',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: _roomTypeFilter,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFFdddddd)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Types')),
                  DropdownMenuItem(value: 'single', child: Text('Single')),
                  DropdownMenuItem(value: 'double', child: Text('Double')),
                  DropdownMenuItem(value: 'suite', child: Text('Suite')),
                  DropdownMenuItem(value: 'deluxe', child: Text('Deluxe')),
                ],
                onChanged: (value) {
                  setState(() => _roomTypeFilter = value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        
        // View Buttons and New Reservation
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _viewType = 'list'),
              icon: const Icon(Icons.list, size: 16),
              label: const Text('List View'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3498db),
                side: const BorderSide(color: Color(0xFF3498db)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => setState(() => _viewType = 'calendar'),
              icon: const Icon(Icons.calendar_today, size: 16),
              label: const Text('Calendar View'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () async {
                await context.push('/reservations/new');
                _loadData(); // Refresh list after returning from form
              },
              icon: const Icon(Icons.add),
              label: const Text('New Reservation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498db),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodaysCheckInsSection() {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2c3e50),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF3498db),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Table
          if (_todaysCheckIns.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 32, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text(
                    'No check-ins scheduled for today.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Guest', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Room', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Check-in Time', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
                ],
                rows: _todaysCheckIns.map((reservation) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person, color: Colors.grey[600], size: 16),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  reservation.guestName ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                if (reservation.guestEmail != null)
                                  Text(
                                    reservation.guestEmail!,
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              reservation.roomNumber ?? 'N/A',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              reservation.roomType ?? '',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(_formatTime(reservation.checkInDate))),
                      DataCell(_buildStatusBadge(reservation.status)),
                      DataCell(
                        reservation.status == 'reserved' || reservation.status == 'confirmed'
                            ? ElevatedButton.icon(
                                onPressed: () async {
                                  await _checkIn(reservation.reservationId!);
                                },
                                icon: const Icon(Icons.login, size: 14),
                                label: const Text('Check In'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3498db),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAllReservationsSection() {
    final filteredReservations = _filteredReservations;
    
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.list, color: Color(0xFF2c3e50)),
                    SizedBox(width: 8),
                    Text(
                      'All Reservations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2c3e50),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Export data
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export feature coming soon')),
                    );
                  },
                  child: const Text(
                    'Export Data',
                    style: TextStyle(
                      color: Color(0xFF3498db),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Table
          if (filteredReservations.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text(
                    'No reservations found. Click "New Reservation" to create one.',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Reservation ID', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Guest', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Room', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Check-in', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Check-out', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
                ],
                rows: filteredReservations.map((reservation) {
                  final reservationNumber = reservation.reservationId != null
                      ? 'RES-${reservation.reservationId!.toString().padLeft(4, '0')}'
                      : 'N/A';
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          '#$reservationNumber',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3498db),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person, color: Colors.grey[600], size: 14),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Guest',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  reservation.guestName ?? 'Unknown',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                if (reservation.guestEmail != null)
                                  Text(
                                    reservation.guestEmail!,
                                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              reservation.roomNumber ?? 'N/A',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              reservation.roomType ?? '',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(Formatters.date(reservation.checkInDate))),
                      DataCell(Text(Formatters.date(reservation.checkOutDate))),
                      DataCell(
                        Text(
                          Formatters.currency(reservation.totalPrice ?? 0.0),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2ecc71),
                          ),
                        ),
                      ),
                      DataCell(_buildStatusBadge(reservation.status)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (reservation.status == 'checked_in')
                              IconButton(
                                icon: const Icon(Icons.logout, size: 18),
                                onPressed: () async {
                                  await _checkOut(reservation.reservationId!);
                                },
                                color: const Color(0xFF2ecc71),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Check Out',
                              ),
                            if (reservation.status == 'reserved' || reservation.status == 'confirmed')
                              IconButton(
                                icon: const Icon(Icons.login, size: 18),
                                onPressed: () async {
                                  await _checkIn(reservation.reservationId!);
                                },
                                color: const Color(0xFF3498db),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Check In',
                              ),
                            IconButton(
                              icon: const Icon(Icons.visibility, size: 18),
                              onPressed: () {
                                // TODO: View reservation
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('View reservation feature coming soon')),
                                );
                              },
                              color: const Color(0xFF3498db),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () {
                                // TODO: Edit reservation
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Edit reservation feature coming soon')),
                                );
                              },
                              color: const Color(0xFF3498db),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () => _deleteReservation(reservation),
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
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'checked_in':
        color = const Color(0xFF2ecc71); // success/green
        text = 'Checked In';
        break;
      case 'confirmed':
        color = const Color(0xFF3498db); // info/blue
        text = 'Confirmed';
        break;
      case 'reserved':
        color = const Color(0xFFf39c12); // warning/orange
        text = 'Reserved';
        break;
      case 'cancelled':
        color = const Color(0xFFe74c3c); // danger/red
        text = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        text = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = dateTime.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $amPm';
  }

  Future<void> _checkIn(int reservationId) async {
    try {
      final success = await _reservationService.checkIn(reservationId);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reservation checked in successfully'),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
          _loadData(); // Refresh the list
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to check in reservation'),
              backgroundColor: AppColors.statusError,
            ),
          );
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
    }
  }

  Future<void> _checkOut(int reservationId) async {
    try {
      final success = await _reservationService.checkOut(reservationId);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reservation checked out successfully'),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
          _loadData(); // Refresh the list
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to check out reservation'),
              backgroundColor: AppColors.statusError,
            ),
          );
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
    }
  }

  Future<void> _deleteReservation(ReservationModel reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reservation'),
        content: Text('Are you sure you want to delete reservation ${reservation.reservationNumber ?? reservation.reservationId}?'),
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

    if (confirmed == true) {
      // TODO: Implement reservation deletion
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete reservation feature coming soon')),
        );
      }
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
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
                color: color.withOpacity(0.1),
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
