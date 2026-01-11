/// Rooms List Screen
/// 
/// Displays room management page matching PHP rooms.php layout
/// Grid of room cards with status badges, info boxes, and action buttons

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/room_model.dart';
import '../../services/room_service.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/utils/formatters.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RoomsListScreen extends StatefulWidget {
  const RoomsListScreen({super.key});

  @override
  State<RoomsListScreen> createState() => _RoomsListScreenState();
}

class _RoomsListScreenState extends State<RoomsListScreen> {
  final RoomService _roomService = RoomService();
  List<RoomModel> _rooms = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rooms = await _roomService.getRooms();
      // Sort by room number
      rooms.sort((a, b) => a.roomNumber.compareTo(b.roomNumber));
      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRoom(RoomModel room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Are you sure you want to delete Room ${room.roomNumber}?'),
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
      // TODO: Implement room deletion in service
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete room feature coming soon')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingWidget(message: 'Loading rooms...')),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: ErrorDisplayWidget(
          message: _error!,
          onRetry: _loadRooms,
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
          
          // Rooms Grid
          if (_rooms.isEmpty)
            _buildEmptyState()
          else
            _buildRoomsGrid(),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Room Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2c3e50),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Manage all rooms and their availability',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            await context.push('/rooms/new');
            // Refresh the list after returning from add
            _loadRooms();
          },
          icon: const Icon(Icons.add),
          label: const Text('Add New Room'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3498db),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.85,
      ),
      itemCount: _rooms.length,
      itemBuilder: (context, index) {
        final room = _rooms[index];
        return _RoomCard(
          room: room,
          onEdit: () async {
            if (room.roomId != null) {
              await context.push('/rooms/${room.roomId}');
              // Refresh the list after returning from edit
              _loadRooms();
            }
          },
          onDelete: () => _deleteRoom(room),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 15),
            Text(
              'No rooms found. Click "Add New Room" to create one.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoomCard({
    required this.room,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getStatusColor() {
    switch (room.status) {
      case 'available':
        return const Color(0xFF2ecc71); // success/green
      case 'occupied':
        return const Color(0xFFf39c12); // warning/orange
      case 'maintenance':
        return const Color(0xFFe74c3c); // danger/red
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    return room.status.substring(0, 1).toUpperCase() + room.status.substring(1);
  }

  String _getRoomTypeText() {
    return room.roomType.substring(0, 1).toUpperCase() + room.roomType.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Room Number/Type and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room ${room.roomNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2c3e50),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _getRoomTypeText(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFf5f7fa),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2c3e50),
                        ),
                        children: [
                          const TextSpan(
                            text: 'Capacity: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: '${room.capacity} guests',
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2c3e50),
                        ),
                        children: [
                          const TextSpan(
                            text: 'Price: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: '${Formatters.currency(room.pricePerNight)}/night',
                          ),
                        ],
                      ),
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2c3e50),
                      ),
                      children: [
                        const TextSpan(
                          text: 'Floor: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: '${room.floor}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3498db),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFe74c3c),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
