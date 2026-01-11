/// Billing Detail Screen
/// 
/// Displays detailed information about a specific invoice

import 'package:flutter/material.dart';
import '../../models/billing_model.dart';
import '../../services/billing_service.dart';
import '../../core/theme/app_theme.dart';

class BillingDetailScreen extends StatefulWidget {
  final int billingId;

  const BillingDetailScreen({Key? key, required this.billingId}) : super(key: key);

  @override
  State<BillingDetailScreen> createState() => _BillingDetailScreenState();
}

class _BillingDetailScreenState extends State<BillingDetailScreen> {
  final BillingService _billingService = BillingService();
  BillingModel? _billing;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBilling();
  }

  Future<void> _loadBilling() async {
    setState(() => _isLoading = true);
    try {
      final billing = await _billingService.getInvoiceById(widget.billingId);
      setState(() {
        _billing = billing;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading invoice: $e')),
        );
      }
    }
  }

  Future<void> _processPayment() async {
    if (_billing == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PaymentDialog(billing: _billing!),
    );

    if (result != null) {
      try {
        await _billingService.processPayment(_billing!.billingId!, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment processed successfully')),
          );
          _loadBilling();
          Navigator.pop(context, true);
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
      appBar: AppBar(
        title: const Text('Invoice Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _billing == null
              ? const Center(child: Text('Invoice not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Invoice #${_billing!.billingId}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      _billing!.paymentStatus.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: _getStatusColor(_billing!.paymentStatus),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Amount: ${_formatCurrency(_billing!.amount)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Details Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Invoice Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              const SizedBox(height: 8),
                              _DetailRow('Reservation ID', '${_billing!.reservationId}'),
                              _DetailRow('Guest ID', '${_billing!.guestId}'),
                              _DetailRow('Invoice Date', _billing!.invoiceDate.toLocal().toString().split(' ')[0]),
                              if (_billing!.dueDate != null)
                                _DetailRow('Due Date', _billing!.dueDate!.toLocal().toString().split(' ')[0]),
                              if (_billing!.paidDate != null)
                                _DetailRow('Paid Date', _billing!.paidDate!.toLocal().toString().split(' ')[0]),
                              _DetailRow('Payment Method', _billing!.paymentMethod.replaceAll('_', ' ').toUpperCase()),
                              _DetailRow('Payment Status', _billing!.paymentStatus.toUpperCase()),
                              if (_billing!.notes != null && _billing!.notes!.isNotEmpty)
                                _DetailRow('Notes', _billing!.notes!),
                            ],
                          ),
                        ),
                      ),

                      // Action Buttons
                      if (_billing!.isPending || _billing!.isPartial)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _processPayment,
                              icon: const Icon(Icons.payment),
                              label: const Text('Process Payment'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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

