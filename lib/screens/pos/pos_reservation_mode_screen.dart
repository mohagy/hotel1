/// POS Reservation Mode Screen
/// 
/// Displays reservations for payment in POS reservation mode

import 'package:flutter/material.dart';
import '../../models/reservation_model.dart';
import '../../services/reservation_service.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../services/pos_service.dart';

class POSReservationModeScreen extends StatefulWidget {
  final Function(OrderItemModel) onReservationSelected;

  const POSReservationModeScreen({super.key, required this.onReservationSelected});

  @override
  State<POSReservationModeScreen> createState() => _POSReservationModeScreenState();
}

class _POSReservationModeScreenState extends State<POSReservationModeScreen> {
  final ReservationService _reservationService = ReservationService();
  final POSService _posService = POSService();
  List<ReservationModel> _reservations = [];
  bool _isLoading = true;
  String? _error;
  String _viewType = 'detailed'; // 'detailed', 'list', 'compact', 'summary'

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reservations = await _reservationService.getReservationsForPayment();
      setState(() {
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectReservation(ReservationModel reservation) {
    final item = OrderItemModel(
      orderId: 0,
      productName: 'Reservation Payment - ${reservation.roomNumber ?? 'N/A'}',
      quantity: 1,
      price: reservation.balanceDue ?? reservation.totalPrice ?? 0.0,
      totalAmount: reservation.balanceDue ?? reservation.totalPrice ?? 0.0,
      isRestaurantItem: false,
      isReservation: true,
    );

    widget.onReservationSelected(item);
  }

  void _processPayment(ReservationModel reservation) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Payment'),
        content: Text('Process payment of ${Formatters.currency(reservation.balanceDue ?? reservation.totalPrice ?? 0.0)} for this reservation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final success = await _reservationService.processPayment(
                  reservation.reservationId!,
                  {
                    'amount': reservation.balanceDue ?? reservation.totalPrice ?? 0.0,
                    'payment_method': 'cash',
                  },
                );
                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment processed successfully'),
                        backgroundColor: AppColors.statusSuccess,
                      ),
                    );
                    _loadReservations();
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
            },
            child: const Text('Process Payment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // View Type Selector
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reservations for Payment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  _ViewTypeButton(
                    icon: Icons.grid_view,
                    label: 'Detailed',
                    isSelected: _viewType == 'detailed',
                    onTap: () => setState(() => _viewType = 'detailed'),
                  ),
                  const SizedBox(width: 8),
                  _ViewTypeButton(
                    icon: Icons.view_list,
                    label: 'List',
                    isSelected: _viewType == 'list',
                    onTap: () => setState(() => _viewType = 'list'),
                  ),
                  const SizedBox(width: 8),
                  _ViewTypeButton(
                    icon: Icons.view_module,
                    label: 'Compact',
                    isSelected: _viewType == 'compact',
                    onTap: () => setState(() => _viewType = 'compact'),
                  ),
                  const SizedBox(width: 8),
                  _ViewTypeButton(
                    icon: Icons.view_agenda,
                    label: 'Summary',
                    isSelected: _viewType == 'summary',
                    onTap: () => setState(() => _viewType = 'summary'),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Reservations Grid/List
        Expanded(
          child: _isLoading
              ? const LoadingWidget(message: 'Loading reservations...')
              : _error != null
                  ? ErrorDisplayWidget(message: _error!, onRetry: _loadReservations)
                  : _reservations.isEmpty
                      ? const EmptyStateWidget(
                          message: 'No reservations found for payment',
                          icon: Icons.receipt_long_outlined,
                        )
                      : RefreshIndicator(
                          onRefresh: _loadReservations,
                          child: _buildReservationsView(),
                        ),
        ),
      ],
    );
  }

  Widget _buildReservationsView() {
    switch (_viewType) {
      case 'list':
        return _buildListView();
      case 'compact':
        return _buildCompactView();
      case 'summary':
        return _buildSummaryView();
      default:
        return _buildDetailedView();
    }
  }

  Widget _buildDetailedView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _reservations.length,
      itemBuilder: (context, index) {
        final reservation = _reservations[index];
        return _ReservationDetailedCard(
          reservation: reservation,
          onTap: () => _selectReservation(reservation),
          onPay: () => _processPayment(reservation),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _reservations.length,
      itemBuilder: (context, index) {
        final reservation = _reservations[index];
        return _ReservationListCard(
          reservation: reservation,
          onTap: () => _selectReservation(reservation),
          onPay: () => _processPayment(reservation),
        );
      },
    );
  }

  Widget _buildCompactView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _reservations.length,
      itemBuilder: (context, index) {
        final reservation = _reservations[index];
        return _ReservationCompactCard(
          reservation: reservation,
          onTap: () => _selectReservation(reservation),
        );
      },
    );
  }

  Widget _buildSummaryView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _reservations.length,
      itemBuilder: (context, index) {
        final reservation = _reservations[index];
        return _ReservationSummaryCard(
          reservation: reservation,
          onTap: () => _selectReservation(reservation),
        );
      },
    );
  }
}

class _ViewTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewTypeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationDetailedCard extends StatelessWidget {
  final ReservationModel reservation;
  final VoidCallback onTap;
  final VoidCallback onPay;

  const _ReservationDetailedCard({
    required this.reservation,
    required this.onTap,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (reservation.status) {
      case 'reserved':
        statusColor = AppColors.secondaryOrange;
        break;
      case 'checked_in':
        statusColor = AppColors.roomOccupied;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reservation ID
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    reservation.roomNumber ?? 'Room N/A',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      reservation.status.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Guest Info
              if (reservation.guestName != null) ...[
                Text(
                  reservation.guestName!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              if (reservation.guestPhone != null)
                Text(
                  Formatters.phone(reservation.guestPhone!),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              const SizedBox(height: 16),
              // Dates
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check-in: ${Formatters.date(reservation.checkInDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Check-out: ${Formatters.date(reservation.checkOutDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${reservation.calculatedNights} nights',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Payment Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Price:',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          Formatters.currency(reservation.totalPrice ?? 0.0),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (reservation.balanceDue != null && reservation.balanceDue! > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Balance Due:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.statusError,
                            ),
                          ),
                          Text(
                            Formatters.currency(reservation.balanceDue!),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.statusError,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Actions
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  child: const Text('Process Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReservationListCard extends StatelessWidget {
  final ReservationModel reservation;
  final VoidCallback onTap;
  final VoidCallback onPay;

  const _ReservationListCard({
    required this.reservation,
    required this.onTap,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Room Info
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.secondaryBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    reservation.roomNumber ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (reservation.guestName != null)
                      Text(
                        reservation.guestName!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${Formatters.date(reservation.checkInDate)} - ${Formatters.date(reservation.checkOutDate)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(reservation.balanceDue ?? reservation.totalPrice ?? 0.0),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: onPay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Pay'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReservationCompactCard extends StatelessWidget {
  final ReservationModel reservation;
  final VoidCallback onTap;

  const _ReservationCompactCard({required this.reservation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reservation.roomNumber ?? 'N/A',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              if (reservation.guestName != null)
                Text(
                  reservation.guestName!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const Spacer(),
              Text(
                Formatters.currency(reservation.balanceDue ?? reservation.totalPrice ?? 0.0),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReservationSummaryCard extends StatelessWidget {
  final ReservationModel reservation;
  final VoidCallback onTap;

  const _ReservationSummaryCard({required this.reservation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                reservation.roomNumber ?? 'N/A',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Formatters.currency(reservation.balanceDue ?? reservation.totalPrice ?? 0.0),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

