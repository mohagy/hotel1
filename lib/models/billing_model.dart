/// Billing Model
/// 
/// Represents invoice and payment records

class BillingModel {
  final int? billingId;
  final int reservationId;
  final int guestId;
  final double amount;
  final String paymentMethod; // 'cash', 'credit_card', 'debit_card', 'bank_transfer'
  final String paymentStatus; // 'pending', 'paid', 'partial', 'overdue'
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final DateTime? paidDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BillingModel({
    this.billingId,
    required this.reservationId,
    required this.guestId,
    required this.amount,
    this.paymentMethod = 'cash',
    this.paymentStatus = 'pending',
    required this.invoiceDate,
    this.dueDate,
    this.paidDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory BillingModel.fromJson(Map<String, dynamic> json) {
    return BillingModel(
      billingId: json['billing_id'] as int?,
      reservationId: (json['reservation_id'] as num).toInt(),
      guestId: (json['guest_id'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      invoiceDate: DateTime.parse(json['invoice_date'] as String),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      paidDate: json['paid_date'] != null
          ? DateTime.parse(json['paid_date'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (billingId != null) 'billing_id': billingId,
      'reservation_id': reservationId,
      'guest_id': guestId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'invoice_date': invoiceDate.toIso8601String().split('T')[0],
      if (dueDate != null) 'due_date': dueDate!.toIso8601String().split('T')[0],
      if (paidDate != null) 'paid_date': paidDate!.toIso8601String().split('T')[0],
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Helper methods
  bool get isPending => paymentStatus == 'pending';
  bool get isPaid => paymentStatus == 'paid';
  bool get isPartial => paymentStatus == 'partial';
  bool get isOverdue => paymentStatus == 'overdue';

  BillingModel copyWith({
    int? billingId,
    int? reservationId,
    int? guestId,
    double? amount,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? invoiceDate,
    DateTime? dueDate,
    DateTime? paidDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BillingModel(
      billingId: billingId ?? this.billingId,
      reservationId: reservationId ?? this.reservationId,
      guestId: guestId ?? this.guestId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<BillingModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => BillingModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}

