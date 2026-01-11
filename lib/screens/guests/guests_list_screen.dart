/// Guests List Screen
/// 
/// Displays guests management page matching PHP guests.php layout
/// Includes metrics, filters, current guests table, all guests table, and VIP guests grid

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/guest_model.dart';
import '../../models/reservation_model.dart';
import '../../services/guest_service.dart';
import '../../services/reservation_service.dart';
import '../../providers/guest_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/utils/formatters.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GuestsListScreen extends StatefulWidget {
  const GuestsListScreen({super.key});

  @override
  State<GuestsListScreen> createState() => _GuestsListScreenState();
}

class _GuestsListScreenState extends State<GuestsListScreen> {
  final GuestService _guestService = GuestService();
  final ReservationService _reservationService = ReservationService();
  
  List<GuestModel> _allGuests = [];
  List<ReservationModel> _allReservations = [];
  List<GuestModel> _currentGuests = []; // Checked in guests
  List<GuestModel> _vipGuests = []; // VIP guests
  
  // Statistics
  int _totalGuests = 0;
  int _checkedInGuests = 0;
  int _expectedTodayGuests = 0;
  int _vipGuestsCount = 0;
  
  // Filters
  String? _statusFilter;
  String? _typeFilter;
  String _sortFilter = 'name';
  
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
      // Load guests and reservations in parallel
      final results = await Future.wait([
        _guestService.getGuests(),
        _reservationService.getReservations(),
      ]);
      
      final guests = results[0] as List<GuestModel>;
      final reservations = results[1] as List<ReservationModel>;
      
      // Calculate statistics
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      final checkedInReservations = reservations.where((r) => r.status == 'checked_in').toList();
      final expectedTodayReservations = reservations.where((r) {
        if (r.status != 'reserved' && r.status != 'checked_in') return false;
        final checkInDate = DateTime(r.checkInDate.year, r.checkInDate.month, r.checkInDate.day);
        return checkInDate.isAtSameMomentAs(todayStart);
      }).toList();
      
      // Get current guests (checked in) with room info
      final checkedInGuestIds = checkedInReservations.map((r) => r.guestId).toSet();
      final currentGuestsList = guests.where((g) => checkedInGuestIds.contains(g.guestId)).toList();
      
      // Get VIP guests (checked in or reserved)
      final vipReservations = reservations.where((r) => 
        r.status == 'checked_in' || r.status == 'reserved'
      ).toList();
      final vipGuestIds = vipReservations.map((r) => r.guestId).toSet();
      final vipGuestsList = guests.where((g) => 
        g.guestType == 'vip' && vipGuestIds.contains(g.guestId)
      ).toList();
      
      setState(() {
        _allGuests = guests;
        _allReservations = reservations;
        _currentGuests = currentGuestsList;
        _vipGuests = vipGuestsList;
        _totalGuests = guests.length;
        _checkedInGuests = checkedInGuestIds.length;
        _expectedTodayGuests = expectedTodayReservations.length;
        _vipGuestsCount = guests.where((g) => g.guestType == 'vip').length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<GuestModel> get _filteredGuests {
    var guests = List<GuestModel>.from(_allGuests);
    
    // Filter by status (requires checking reservations)
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      final statusReservations = _allReservations.where((r) => r.status == _statusFilter).toList();
      final statusGuestIds = statusReservations.map((r) => r.guestId).toSet();
      guests = guests.where((g) => statusGuestIds.contains(g.guestId)).toList();
    }
    
    // Filter by type
    if (_typeFilter != null && _typeFilter!.isNotEmpty) {
      guests = guests.where((g) => g.guestType == _typeFilter).toList();
    }
    
    // Sort
    switch (_sortFilter) {
      case 'name':
        guests.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case 'recent':
        guests.sort((a, b) {
          final aDate = a.createdAt ?? DateTime(1970);
          final bDate = b.createdAt ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });
        break;
      case 'email':
        guests.sort((a, b) {
          final aEmail = a.email ?? '';
          final bEmail = b.email ?? '';
          return aEmail.compareTo(bEmail);
        });
        break;
    }
    
    return guests;
  }

  ReservationModel? _getGuestReservation(int guestId) {
    final reservations = _allReservations
        .where((r) => r.guestId == guestId && r.status == 'checked_in')
        .toList();
    return reservations.isEmpty ? null : reservations.first;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingWidget(message: 'Loading guests...')),
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
          
          // Filters and Add Button
          _buildFiltersSection(),
          const SizedBox(height: 25),
          
          // Current Guests Section
          _buildCurrentGuestsSection(),
          const SizedBox(height: 30),
          
          // All Guests Section
          _buildAllGuestsSection(),
          const SizedBox(height: 30),
          
          // VIP Guests Section
          _buildVipGuestsSection(),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Guests Management',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2c3e50),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Manage all guest information, check-ins, and profiles',
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
          title: 'Total Guests',
          value: _totalGuests.toString(),
          icon: Icons.people,
          color: const Color(0xFF3498db),
        )),
        const SizedBox(width: 20),
        Expanded(child: _MetricCard(
          title: 'Checked In',
          value: _checkedInGuests.toString(),
          icon: Icons.check_circle,
          color: const Color(0xFF2ecc71),
        )),
        const SizedBox(width: 20),
        Expanded(child: _MetricCard(
          title: 'Expected Today',
          value: _expectedTodayGuests.toString(),
          icon: Icons.calendar_today,
          color: const Color(0xFFf39c12),
        )),
        const SizedBox(width: 20),
        Expanded(child: _MetricCard(
          title: 'VIP Guests',
          value: _vipGuestsCount.toString(),
          icon: Icons.star,
          color: const Color(0xFF9c27b0),
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
                  DropdownMenuItem(value: 'reserved', child: Text('Reserved')),
                  DropdownMenuItem(value: 'checked_out', child: Text('Checked Out')),
                ],
                onChanged: (value) {
                  setState(() => _statusFilter = value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        
        // Type Filter
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GUEST TYPE',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: _typeFilter,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFFdddddd)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Types')),
                  DropdownMenuItem(value: 'regular', child: Text('Regular')),
                  DropdownMenuItem(value: 'vip', child: Text('VIP')),
                  DropdownMenuItem(value: 'corporate', child: Text('Corporate')),
                ],
                onChanged: (value) {
                  setState(() => _typeFilter = value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        
        // Sort Filter
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SORT BY',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: _sortFilter,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFFdddddd)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                  DropdownMenuItem(value: 'recent', child: Text('Most Recent')),
                  DropdownMenuItem(value: 'email', child: Text('Email')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortFilter = value);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        
        // Add Guest Button
        ElevatedButton.icon(
          onPressed: () async {
            await context.push('/guests/new');
            _loadData();
          },
          icon: const Icon(Icons.add),
          label: const Text('Add New Guest'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3498db),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentGuestsSection() {
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
                    Icon(Icons.door_front_door, color: Color(0xFF2c3e50)),
                    SizedBox(width: 8),
                    Text(
                      'Current Guests',
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
          if (_currentGuests.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text(
                    'No guests currently checked in.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            _buildCurrentGuestsTable(),
        ],
      ),
    );
  }

  Widget _buildCurrentGuestsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Guest', style: TextStyle(fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Room', style: TextStyle(fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Check-in', style: TextStyle(fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Check-out', style: TextStyle(fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
        ],
        rows: _currentGuests.take(10).map((guest) {
          final reservation = _getGuestReservation(guest.guestId!);
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
                      child: Icon(Icons.person, color: Colors.grey[600], size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          guest.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (guest.email != null)
                          Text(
                            guest.email!,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              DataCell(Text(reservation?.roomNumber ?? 'N/A')),
              DataCell(Text(reservation != null 
                ? Formatters.date(reservation.checkInDate)
                : 'N/A')),
              DataCell(Text(reservation != null 
                ? Formatters.date(reservation.checkOutDate)
                : 'N/A')),
              DataCell(_buildStatusBadge(reservation?.status ?? '')),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 18),
                      onPressed: () => context.push('/guests/${guest.guestId}'),
                      color: const Color(0xFF3498db),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => context.push('/guests/${guest.guestId}'),
                      color: const Color(0xFF3498db),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      onPressed: () => _deleteGuest(guest),
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
    );
  }

  Widget _buildAllGuestsSection() {
    final filteredGuests = _filteredGuests;
    
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
              children: [
                const Icon(Icons.list, color: Color(0xFF2c3e50)),
                const SizedBox(width: 8),
                Text(
                  'All Guests (${filteredGuests.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2c3e50),
                  ),
                ),
              ],
            ),
          ),
          
          // Table
          if (filteredGuests.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text(
                    'No guests found. Click "Add New Guest" to create one.',
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
                  DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Country', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
                ],
                rows: filteredGuests.map((guest) {
                  return DataRow(
                    cells: [
                      DataCell(Text(guest.fullName, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(guest.email ?? '-')),
                      DataCell(Text(guest.phone)),
                      DataCell(Text(guest.country ?? '-')),
                      DataCell(_buildTypeBadge(guest.guestType)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              onPressed: () => context.push('/guests/${guest.guestId}'),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _deleteGuest(guest),
                              icon: const Icon(Icons.delete, size: 16),
                              label: const Text('Delete'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
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

  Widget _buildVipGuestsSection() {
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
                    Icon(Icons.star, color: Color(0xFF2c3e50)),
                    SizedBox(width: 8),
                    Text(
                      'VIP Guests',
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
          
          // VIP Grid
          if (_vipGuests.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.star, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text(
                    'No VIP guests currently checked in.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.85,
                ),
                itemCount: _vipGuests.length,
                itemBuilder: (context, index) {
                  final guest = _vipGuests[index];
                  final reservations = _allReservations
                      .where((r) => r.guestId == guest.guestId && 
                              (r.status == 'checked_in' || r.status == 'reserved'))
                      .toList();
                  final reservation = reservations.isEmpty ? null : reservations.first;
                  return _VipGuestCard(
                    guest: guest,
                    reservation: reservation,
                  );
                },
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
        color = const Color(0xFF2ecc71);
        text = 'Checked In';
        break;
      case 'reserved':
        color = const Color(0xFF3498db);
        text = 'Reserved';
        break;
      case 'checked_out':
        color = Colors.grey;
        text = 'Checked Out';
        break;
      default:
        color = Colors.grey;
        text = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    final text = type.substring(0, 1).toUpperCase() + type.substring(1);
    return Text(text);
  }

  Future<void> _deleteGuest(GuestModel guest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Guest'),
        content: Text('Are you sure you want to delete ${guest.fullName}?'),
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
      try {
        await _guestService.deleteGuest(guest.guestId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Guest deleted successfully')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting guest: $e')),
          );
        }
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
            Column(
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

class _VipGuestCard extends StatelessWidget {
  final GuestModel guest;
  final ReservationModel? reservation;

  const _VipGuestCard({
    required this.guest,
    this.reservation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                guest.firstName[0].toUpperCase() + guest.lastName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          
          // Name
          Text(
            guest.fullName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2c3e50),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Room Info
          if (reservation != null) ...[
            Text(
              'Room ${reservation!.roomNumber ?? 'N/A'} • ${reservation!.roomType ?? 'Standard'}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Check-out: ${Formatters.date(reservation!.checkOutDate)}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 12),
          
          // VIP Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFf39c12), Color(0xFFe67e22)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'VIP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
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
