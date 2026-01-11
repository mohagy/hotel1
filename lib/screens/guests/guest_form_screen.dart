/// Guest Form Screen
/// 
/// Create or edit guest information

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/guest_model.dart';
import '../../models/room_model.dart';
import '../../services/guest_service.dart';
import '../../services/room_service.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';

class GuestFormScreen extends StatefulWidget {
  final GuestModel? guest;
  final int? guestId;

  const GuestFormScreen({super.key, this.guest, this.guestId});

  @override
  State<GuestFormScreen> createState() => _GuestFormScreenState();
}

class _GuestFormScreenState extends State<GuestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final GuestService _guestService = GuestService();
  final RoomService _roomService = RoomService();
  bool _isLoading = false;
  bool _isLoadingRooms = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _countryController = TextEditingController();
  final _specialRequestsController = TextEditingController();

  String _idType = 'passport';
  String _guestType = 'regular';
  int? _selectedRoomId;
  List<RoomModel> _rooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
    if (widget.guest != null) {
      _loadGuestData(widget.guest!);
    } else if (widget.guestId != null) {
      _loadGuestById(widget.guestId!);
    }
  }

  void _loadGuestData(GuestModel guest) {
    _firstNameController.text = guest.firstName;
    _lastNameController.text = guest.lastName;
    _emailController.text = guest.email ?? '';
    _phoneController.text = guest.phone;
    _idNumberController.text = guest.idNumber;
    _countryController.text = guest.country ?? '';
    _specialRequestsController.text = guest.specialRequests ?? '';
    _idType = guest.idType;
    _guestType = guest.guestType;
    _selectedRoomId = guest.roomId;
  }

  Future<void> _loadGuestById(int guestId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final guest = await _guestService.getGuestById(guestId);
      if (guest != null && mounted) {
        _loadGuestData(guest);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading guest: ${e.toString()}'),
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

  Future<void> _loadRooms() async {
    setState(() {
      _isLoadingRooms = true;
    });
    try {
      final rooms = await _roomService.getRooms();
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _isLoadingRooms = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRooms = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _idNumberController.dispose();
    _countryController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _saveGuest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final guest = GuestModel(
        guestId: widget.guest?.guestId ?? widget.guestId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        idType: _idType,
        idNumber: _idNumberController.text.trim(),
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
        guestType: _guestType,
        specialRequests: _specialRequestsController.text.trim().isEmpty
            ? null
            : _specialRequestsController.text.trim(),
        roomId: _selectedRoomId,
      );

      if (widget.guest == null && widget.guestId == null) {
        await _guestService.createGuest(guest);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Guest created successfully'),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
          context.pop();
        }
      } else {
        await _guestService.updateGuest(guest);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Guest updated successfully'),
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
        title: Text(widget.guest == null && widget.guestId == null ? 'New Guest' : 'Edit Guest'),
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
              onPressed: _saveGuest,
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
              // Personal Information
              const Text(
                'Personal Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name *'),
                validator: (value) => Validators.required(value, 'First name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name *'),
                validator: (value) => Validators.required(value, 'Last name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone *'),
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
              const SizedBox(height: 24),
              // ID Information
              const Text(
                'ID Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _idType,
                decoration: const InputDecoration(labelText: 'ID Type *'),
                items: const [
                  DropdownMenuItem(value: 'passport', child: Text('Passport')),
                  DropdownMenuItem(value: 'driver_license', child: Text('Driver License')),
                  DropdownMenuItem(value: 'national_id', child: Text('National ID')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _idType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _idNumberController,
                decoration: const InputDecoration(labelText: 'ID Number *'),
                validator: (value) => Validators.required(value, 'ID number'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: 'Country'),
              ),
              const SizedBox(height: 24),
              // Guest Type
              const Text(
                'Guest Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _guestType,
                decoration: const InputDecoration(labelText: 'Guest Type'),
                items: const [
                  DropdownMenuItem(value: 'regular', child: Text('Regular')),
                  DropdownMenuItem(value: 'vip', child: Text('VIP')),
                  DropdownMenuItem(value: 'corporate', child: Text('Corporate')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _guestType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specialRequestsController,
                decoration: const InputDecoration(labelText: 'Special Requests'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              // Room Assignment (Optional)
              const Text(
                'Room Assignment (Optional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _isLoadingRooms
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<int?>(
                      value: _selectedRoomId,
                      decoration: const InputDecoration(
                        labelText: 'Room',
                        hintText: 'Select a room (optional)',
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('None'),
                        ),
                        ..._rooms.map((room) => DropdownMenuItem<int?>(
                              value: room.roomId,
                              child: Text('Room ${room.roomNumber} - ${room.roomType} (${room.status})'),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRoomId = value;
                        });
                      },
                    ),
              const SizedBox(height: 32),
              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveGuest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Guest'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

