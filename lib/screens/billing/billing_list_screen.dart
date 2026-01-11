/// Billing List Screen
/// 
/// Displays all invoices and billing records with filtering and payment processing

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/billing_model.dart';
import '../../models/reservation_model.dart';
import '../../services/billing_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import 'billing_detail_screen.dart';
import 'billing_form_screen.dart';

class BillingListScreen extends StatefulWidget {
  const BillingListScreen({Key? key}) : super(key: key);

  @override
  State<BillingListScreen> createState() => _BillingListScreenState();
}

class _BillingListScreenState extends State<BillingListScreen> {
  final BillingService _billingService = BillingService();
  List<BillingModel> _billings = [];
  List<BillingModel> _filteredBillings = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _paymentMethodFilter = 'all';

  // Statistics
  double _todayRevenue = 0.0;
  int _pendingInvoices = 0;
  int _overduePayments = 0;
  double _monthlyRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBillings();
    _loadStatistics();
  }

  Future<void> _loadBillings() async {
    setState(() => _isLoading = true);
    try {
      final billings = await _billingService.getInvoices();
      setState(() {
        _billings = billings;
        _filteredBillings = billings;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading billings: $e')),
        );
      }
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month, 1);

      // Calculate statistics from loaded billings
      setState(() {
        _todayRevenue = _billings
            .where((b) => b.isPaid && 
                  b.paidDate != null && 
                  b.paidDate!.isAtSameMomentAs(today) ||
                  (b.paidDate != null && 
                   b.paidDate!.year == now.year &&
                   b.paidDate!.month == now.month &&
                   b.paidDate!.day == now.day))
            .fold(0.0, (sum, b) => sum + b.amount);

        _pendingInvoices = _billings.where((b) => b.isPending || b.isPartial).length;

        _overduePayments = _billings.where((b) => 
          b.isOverdue || 
          (b.isPending && b.dueDate != null && b.dueDate!.isBefore(today))
        ).length;

        _monthlyRevenue = _billings
            .where((b) => b.isPaid && 
                  b.paidDate != null && 
                  b.paidDate!.isAfter(monthStart.subtract(const Duration(days: 1))))
            .fold(0.0, (sum, b) => sum + b.amount);
      });
    } catch (e) {
      // Statistics calculation error - continue
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredBillings = _billings.where((billing) {
        // Status filter
        if (_statusFilter != 'all') {
          if (billing.paymentStatus != _statusFilter) return false;
        }

        // Payment method filter
        if (_paymentMethodFilter != 'all') {
          if (billing.paymentMethod != _paymentMethodFilter) return false;
        }

        // Search query (by invoice ID, guest name, reservation ID)
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!billing.billingId.toString().contains(query) &&
              !billing.reservationId.toString().contains(query)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  Future<void> _processPayment(BillingModel billing) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PaymentDialog(billing: billing),
    );

    if (result != null) {
      try {
        await _billingService.processPayment(billing.billingId!, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment processed successfully')),
          );
          _loadBillings();
          _loadStatistics();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error processing payment: $e')),
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'partial':
        return Colors.blue;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Billing & Invoicing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BillingFormScreen()),
              );
              if (result == true) {
                _loadBillings();
                _loadStatistics();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistics Cards
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Today\'s Revenue',
                          value: _formatCurrency(_todayRevenue),
                          icon: Icons.attach_money,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Pending Invoices',
                          value: '$_pendingInvoices',
                          icon: Icons.pending,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Overdue Payments',
                          value: '$_overduePayments',
                          icon: Icons.warning,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Monthly Revenue',
                          value: _formatCurrency(_monthlyRevenue),
                          icon: Icons.trending_up,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                // Filters and Search
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by invoice ID, reservation ID...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          _applyFilters();
                        },
                      ),
                      const SizedBox(height: 12),

                      // Filter Chips
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _statusFilter,
                              decoration: InputDecoration(
                                labelText: 'Payment Status',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                DropdownMenuItem(value: 'paid', child: Text('Paid')),
                                DropdownMenuItem(value: 'partial', child: Text('Partial')),
                                DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                              ],
                              onChanged: (value) {
                                setState(() => _statusFilter = value ?? 'all');
                                _applyFilters();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _paymentMethodFilter,
                              decoration: InputDecoration(
                                labelText: 'Payment Method',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('All Methods')),
                                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                                DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
                                DropdownMenuItem(value: 'debit_card', child: Text('Debit Card')),
                                DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                              ],
                              onChanged: (value) {
                                setState(() => _paymentMethodFilter = value ?? 'all');
                                _applyFilters();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Billing List
                Expanded(
                  child: _filteredBillings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No invoices found',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadBillings,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredBillings.length,
                            itemBuilder: (context, index) {
                              final billing = _filteredBillings[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Invoice #${billing.billingId}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          billing.paymentStatus.toUpperCase(),
                                          style: const TextStyle(fontSize: 10, color: Colors.white),
                                        ),
                                        backgroundColor: _getStatusColor(billing.paymentStatus),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text('Reservation ID: ${billing.reservationId}'),
                                      Text('Guest ID: ${billing.guestId}'),
                                      Text('Amount: ${_formatCurrency(billing.amount)}'),
                                      Text('Payment Method: ${billing.paymentMethod.replaceAll('_', ' ').toUpperCase()}'),
                                      if (billing.dueDate != null)
                                        Text('Due Date: ${billing.dueDate!.toLocal().toString().split(' ')[0]}'),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BillingDetailScreen(billingId: billing.billingId!),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadBillings();
                                        _loadStatistics();
                                      }
                                    },
                                  ),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BillingDetailScreen(billingId: billing.billingId!),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadBillings();
                                      _loadStatistics();
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final BillingModel billing;

  const _PaymentDialog({required this.billing});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  String _paymentMethod = 'cash';
  double _amount = 0.0;
  String _notes = '';

  @override
  void initState() {
    super.initState();
    _amount = widget.billing.amount;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Process Payment - Invoice #${widget.billing.billingId}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Amount Due: \$${widget.billing.amount.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
                  DropdownMenuItem(value: 'debit_card', child: Text('Debit Card')),
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                ],
                onChanged: (value) => setState(() => _paymentMethod = value ?? 'cash'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                initialValue: _amount.toStringAsFixed(2),
                onSaved: (value) => _amount = double.tryParse(value ?? '0') ?? 0.0,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onSaved: (value) => _notes = value ?? '',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              Navigator.pop(context, {
                'payment_method': _paymentMethod,
                'amount': _amount,
                'notes': _notes,
                'payment_status': _amount >= widget.billing.amount ? 'paid' : 'partial',
              });
            }
          },
          child: const Text('Process Payment'),
        ),
      ],
    );
  }
}

