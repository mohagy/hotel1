/// Billing Form Screen
/// 
/// Create or edit billing records

import 'package:flutter/material.dart';
import '../../models/billing_model.dart';
import '../../services/billing_service.dart';
import '../../core/widgets/common_widgets.dart';

class BillingFormScreen extends StatefulWidget {
  final BillingModel? billing;

  const BillingFormScreen({Key? key, this.billing}) : super(key: key);

  @override
  State<BillingFormScreen> createState() => _BillingFormScreenState();
}

class _BillingFormScreenState extends State<BillingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _billingService = BillingService();
  bool _isLoading = false;

  late int _reservationId;
  late double _amount;
  late String _paymentMethod;
  late String _paymentStatus;
  DateTime? _invoiceDate;
  DateTime? _dueDate;
  String _notes = '';

  @override
  void initState() {
    super.initState();
    if (widget.billing != null) {
      _reservationId = widget.billing!.reservationId;
      _amount = widget.billing!.amount;
      _paymentMethod = widget.billing!.paymentMethod;
      _paymentStatus = widget.billing!.paymentStatus;
      _invoiceDate = widget.billing!.invoiceDate;
      _dueDate = widget.billing!.dueDate;
      _notes = widget.billing!.notes ?? '';
    } else {
      _reservationId = 0;
      _amount = 0.0;
      _paymentMethod = 'cash';
      _paymentStatus = 'pending';
      _invoiceDate = DateTime.now();
    }
  }

  Future<void> _saveBilling() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final billing = BillingModel(
        billingId: widget.billing?.billingId,
        reservationId: _reservationId,
        guestId: 0, // Will be set by backend from reservation
        amount: _amount,
        paymentMethod: _paymentMethod,
        paymentStatus: _paymentStatus,
        invoiceDate: _invoiceDate ?? DateTime.now(),
        dueDate: _dueDate,
        notes: _notes.isEmpty ? null : _notes,
      );

      if (widget.billing != null) {
        await _billingService.updateInvoice(billing);
      } else {
        await _billingService.createInvoice(billing);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.billing != null
                ? 'Invoice updated successfully'
                : 'Invoice created successfully'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving invoice: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDueDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDueDate ? (_dueDate ?? DateTime.now()) : (_invoiceDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
        } else {
          _invoiceDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.billing != null ? 'Edit Invoice' : 'New Invoice'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveBilling,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Reservation ID *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                initialValue: _reservationId == 0 ? '' : _reservationId.toString(),
                onSaved: (value) => _reservationId = int.tryParse(value ?? '0') ?? 0,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter reservation ID';
                  }
                  final id = int.tryParse(value);
                  if (id == null || id <= 0) {
                    return 'Please enter valid reservation ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Amount *',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                initialValue: _amount == 0.0 ? '' : _amount.toStringAsFixed(2),
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
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
                  DropdownMenuItem(value: 'debit_card', child: Text('Debit Card')),
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                ],
                onChanged: (value) => setState(() => _paymentMethod = value ?? 'cash'),
                validator: (value) => value == null ? 'Please select payment method' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _paymentStatus,
                decoration: const InputDecoration(
                  labelText: 'Payment Status *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'paid', child: Text('Paid')),
                  DropdownMenuItem(value: 'partial', child: Text('Partial')),
                  DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                ],
                onChanged: (value) => setState(() => _paymentStatus = value ?? 'pending'),
                validator: (value) => value == null ? 'Please select payment status' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context, false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Invoice Date *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _invoiceDate != null
                        ? _invoiceDate!.toLocal().toString().split(' ')[0]
                        : 'Select date',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context, true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date (optional)',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _dueDate != null
                        ? _dueDate!.toLocal().toString().split(' ')[0]
                        : 'Select date (optional)',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                initialValue: _notes,
                onSaved: (value) => _notes = value ?? '',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveBilling,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.billing != null ? 'Update Invoice' : 'Create Invoice'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

