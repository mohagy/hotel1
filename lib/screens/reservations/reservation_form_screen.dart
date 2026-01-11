/// Reservation Form Screen
/// 
/// Create or edit reservation information

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/reservation_model.dart';
import '../../models/guest_model.dart';
import '../../models/room_model.dart';
import '../../services/reservation_service.dart';
import '../../services/guest_service.dart';
import '../../services/room_service.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/utils/formatters.dart';

class ReservationFormScreen extends StatefulWidget {
  final ReservationModel? reservation;
  final int? reservationId;

  const ReservationFormScreen({super.key, this.reservation, this.reservationId});

  @override
  State<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ReservationService _reservationService = ReservationService();
  final GuestService _guestService = GuestService();
  final RoomService _roomService = RoomService();
  bool _isLoading = false;
  bool _isLoadingGuests = false;
  bool _isLoadingRooms = false;

  int? _selectedGuestId;
  int? _selectedRoomId;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  String _status = 'reserved';

  List<GuestModel> _guests = [];
  List<RoomModel> _rooms = [];

  @override
  void initState() {
    super.initState();
    _loadGuests();
    _loadRooms();
    if (widget.reservation != null) {
      _loadReservationData(widget.reservation!);
    } else if (widget.reservationId != null) {
      _loadReservationById(widget.reservationId!);
    } else {
      // Set default dates for new reservation
      final now = DateTime.now();
      _checkInDate = DateTime(now.year, now.month, now.day);
      _checkOutDate = DateTime(now.year, now.month, now.day + 1);
    }
  }

  void _loadReservationData(ReservationModel reservation) {
    _selectedGuestId = reservation.guestId;
    _selectedRoomId = reservation.roomId;
    _checkInDate = reservation.checkInDate;
    _checkOutDate = reservation.checkOutDate;
    _status = reservation.status;
  }

  Future<void> _loadReservationById(int reservationId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final reservation = await _reservationService.getReservationById(reservationId);
      if (reservation != null && mounted) {
        _loadReservationData(reservation);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reservation: ${e.toString()}'),
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

  Future<void> _loadGuests() async {
    setState(() {
      _isLoadingGuests = true;
    });
    try {
      final guests = await _guestService.getGuests();
      if (mounted) {
        setState(() {
          _guests = guests;
          _isLoadingGuests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGuests = false;
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

  Future<void> _selectCheckInDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _checkInDate = DateTime(picked.year, picked.month, picked.day);
        // If check-out is before check-in, update it
        if (_checkOutDate != null && _checkOutDate!.isBefore(_checkInDate!)) {
          _checkOutDate = DateTime(_checkInDate!.year, _checkInDate!.month, _checkInDate!.day + 1);
        }
      });
    }
  }

  Future<void> _selectCheckOutDate() async {
    final firstDate = _checkInDate ?? DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _checkOutDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  int? get _calculatedNights {
    if (_checkInDate != null && _checkOutDate != null) {
      return _checkOutDate!.difference(_checkInDate!).inDays;
    }
    return null;
  }

  Future<void> _saveReservation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGuestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a guest'),
          backgroundColor: AppColors.statusError,
        ),
      );
      return;
    }

    if (_selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a room'),
          backgroundColor: AppColors.statusError,
        ),
      );
      return;
    }

    if (_checkInDate == null || _checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select check-in and check-out dates'),
          backgroundColor: AppColors.statusError,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final reservation = ReservationModel(
        reservationId: widget.reservation?.reservationId ?? widget.reservationId,
        guestId: _selectedGuestId!,
        roomId: _selectedRoomId!,
        checkInDate: _checkInDate!,
        checkOutDate: _checkOutDate!,
        status: _status,
      );

      if (widget.reservation == null && widget.reservationId == null) {
        await _reservationService.createReservation(reservation);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reservation created successfully'),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
          context.pop();
        }
      } else {
        await _reservationService.updateReservation(reservation);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reservation updated successfully'),
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
        title: Text(widget.reservation == null && widget.reservationId == null
            ? 'New Reservation'
            : 'Edit Reservation'),
      ),
      body: _isLoading && widget.reservationId != null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Guest Selection
                    const Text(
                      'Guest Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _isLoadingGuests
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<int>(
                            value: _selectedGuestId,
                            decoration: const InputDecoration(
                              labelText: 'Guest *',
                              hintText: 'Select a guest',
                            ),
                            items: _guests.map((guest) {
                              return DropdownMenuItem<int>(
                                value: guest.guestId,
                                child: Text(
                                  '${guest.firstName} ${guest.lastName}${guest.email != null ? ' (${guest.email})' : ''}',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedGuestId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a guest';
                              }
                              return null;
                            },
                          ),
                    const SizedBox(height: 24),
                    // Room Selection
                    const Text(
                      'Room Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _isLoadingRooms
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<int>(
                            value: _selectedRoomId,
                            decoration: const InputDecoration(
                              labelText: 'Room *',
                              hintText: 'Select a room',
                            ),
                            items: _rooms.map((room) {
                              return DropdownMenuItem<int>(
                                value: room.roomId,
                                child: Text(
                                  'Room ${room.roomNumber} - ${room.roomType} (\$${room.pricePerNight}/night) - ${room.status}',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedRoomId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a room';
                              }
                              return null;
                            },
                          ),
                    const SizedBox(height: 24),
                    // Dates
                    const Text(
                      'Reservation Dates',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectCheckInDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Check-in Date *',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _checkInDate != null
                                    ? Formatters.date(_checkInDate!)
                                    : 'Select check-in date',
                                style: TextStyle(
                                  color: _checkInDate != null
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectCheckOutDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Check-out Date *',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _checkOutDate != null
                                    ? Formatters.date(_checkOutDate!)
                                    : 'Select check-out date',
                                style: TextStyle(
                                  color: _checkOutDate != null
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_calculatedNights != null && _calculatedNights! > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${_calculatedNights} night${_calculatedNights! > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Status
                    const Text(
                      'Reservation Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Status *'),
                      items: const [
                        DropdownMenuItem(value: 'reserved', child: Text('Reserved')),
                        DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _status = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    // Save Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveReservation,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(widget.reservation == null && widget.reservationId == null
                          ? 'Create Reservation'
                          : 'Update Reservation'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

