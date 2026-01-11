/// Room Form Screen
/// 
/// Create or edit room information

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/room_model.dart';
import '../../services/room_service.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';

class RoomFormScreen extends StatefulWidget {
  final RoomModel? room;
  final int? roomId;

  const RoomFormScreen({super.key, this.room, this.roomId});

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final RoomService _roomService = RoomService();
  bool _isLoading = false;

  final _roomNumberController = TextEditingController();
  final _floorController = TextEditingController();
  final _capacityController = TextEditingController();
  final _pricePerNightController = TextEditingController();
  final _amenitiesController = TextEditingController();

  String _roomType = 'single';
  String _status = 'available';

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _loadRoomData(widget.room!);
    } else if (widget.roomId != null) {
      _loadRoomById(widget.roomId!);
    }
  }

  void _loadRoomData(RoomModel room) {
    _roomNumberController.text = room.roomNumber;
    _floorController.text = room.floor.toString();
    _capacityController.text = room.capacity.toString();
    _pricePerNightController.text = room.pricePerNight.toString();
    _amenitiesController.text = room.amenities ?? '';
    _roomType = room.roomType;
    _status = room.status;
  }

  Future<void> _loadRoomById(int roomId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final room = await _roomService.getRoomById(roomId);
      if (room != null && mounted) {
        _loadRoomData(room);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading room: ${e.toString()}'),
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
    _roomNumberController.dispose();
    _floorController.dispose();
    _capacityController.dispose();
    _pricePerNightController.dispose();
    _amenitiesController.dispose();
    super.dispose();
  }

  Future<void> _saveRoom() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final room = RoomModel(
        roomId: widget.room?.roomId ?? widget.roomId,
        roomNumber: _roomNumberController.text.trim(),
        floor: int.parse(_floorController.text.trim()),
        roomType: _roomType,
        capacity: int.parse(_capacityController.text.trim()),
        pricePerNight: double.parse(_pricePerNightController.text.trim()),
        status: _status,
        amenities: _amenitiesController.text.trim().isEmpty
            ? null
            : _amenitiesController.text.trim(),
      );

      if (widget.room == null && widget.roomId == null) {
        await _roomService.createRoom(room);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room created successfully'),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
          context.pop();
        }
      } else {
        await _roomService.updateRoom(room);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room updated successfully'),
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
        title: Text(widget.room == null ? 'New Room' : 'Edit Room'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveRoom,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Room Information
              const Text(
                'Room Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomNumberController,
                decoration: const InputDecoration(
                  labelText: 'Room Number *',
                  hintText: 'e.g., 101, 202, 301',
                ),
                validator: (value) => Validators.required(value, 'Room number'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _floorController,
                      decoration: const InputDecoration(
                        labelText: 'Floor *',
                        hintText: 'e.g., 1, 2, 3',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => Validators.number(value, min: 0),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(
                        labelText: 'Capacity *',
                        hintText: 'Number of guests',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => Validators.number(value, min: 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _roomType,
                decoration: const InputDecoration(labelText: 'Room Type *'),
                items: const [
                  DropdownMenuItem(value: 'single', child: Text('Single')),
                  DropdownMenuItem(value: 'double', child: Text('Double')),
                  DropdownMenuItem(value: 'suite', child: Text('Suite')),
                  DropdownMenuItem(value: 'deluxe', child: Text('Deluxe')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _roomType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              // Pricing & Status
              const Text(
                'Pricing & Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pricePerNightController,
                decoration: const InputDecoration(
                  labelText: 'Price Per Night *',
                  hintText: 'e.g., 100.00',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) => Validators.number(value, min: 0),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status *'),
                items: const [
                  DropdownMenuItem(value: 'available', child: Text('Available')),
                  DropdownMenuItem(value: 'occupied', child: Text('Occupied')),
                  DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              // Additional Information
              const Text(
                'Additional Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amenitiesController,
                decoration: const InputDecoration(
                  labelText: 'Amenities',
                  hintText: 'e.g., WiFi, TV, AC, Mini Bar (comma-separated)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveRoom,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(widget.room == null ? 'Create Room' : 'Update Room'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

