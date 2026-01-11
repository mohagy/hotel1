/// Order Model (POS)
/// 
/// Represents POS orders with multi-mode support (retail, restaurant, reservation)

class OrderModel {
  final int? id;
  final int? customerId;
  final int? salespersonId;
  final double subtotal;
  final double discountTotal;
  final double serviceCharge;
  final double tipAmount;
  final double tax;
  final double total;
  final String status; // 'completed', 'pending', 'cancelled', 'hold'
  final String paymentMethod; // 'cash', 'credit_card', 'debit_card', 'bank_transfer'
  final String businessMode; // 'retail', 'restaurant', 'reservation'
  final int? stationId;
  final String? waiterName;
  final String? tableNo;
  final String? billNumber;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Related data
  final List<OrderItemModel>? items;

  OrderModel({
    this.id,
    this.customerId,
    this.salespersonId,
    this.subtotal = 0.0,
    this.discountTotal = 0.0,
    this.serviceCharge = 0.0,
    this.tipAmount = 0.0,
    this.tax = 0.0,
    this.total = 0.0,
    this.status = 'completed',
    this.paymentMethod = 'cash',
    this.businessMode = 'retail',
    this.stationId,
    this.waiterName,
    this.tableNo,
    this.billNumber,
    this.comment,
    this.createdAt,
    this.updatedAt,
    this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as int?,
      customerId: json['customer_id'] as int?,
      salespersonId: json['salesperson_id'] as int?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountTotal: (json['discount_total'] as num?)?.toDouble() ?? 0.0,
      serviceCharge: (json['service_charge'] as num?)?.toDouble() ?? 0.0,
      tipAmount: (json['tip_amount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'completed',
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      businessMode: json['business_mode'] as String? ?? 'retail',
      stationId: json['station_id'] as int?,
      waiterName: json['waiter_name'] as String?,
      tableNo: json['table_no'] as String?,
      billNumber: json['bill_number'] as String?,
      comment: json['comment'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      items: json['items'] != null
          ? (json['items'] as List).map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (salespersonId != null) 'salesperson_id': salespersonId,
      'subtotal': subtotal,
      'discount_total': discountTotal,
      'service_charge': serviceCharge,
      'tip_amount': tipAmount,
      'tax': tax,
      'total': total,
      'status': status,
      'payment_method': paymentMethod,
      'business_mode': businessMode,
      if (stationId != null) 'station_id': stationId,
      if (waiterName != null) 'waiter_name': waiterName,
      if (tableNo != null) 'table_no': tableNo,
      if (billNumber != null) 'bill_number': billNumber,
      if (comment != null) 'comment': comment,
      if (items != null) 'items': items!.map((item) => item.toJson()).toList(),
    };
  }

  Map<String, dynamic> toOrderJson() {
    // For sending to API - includes order items separately
    return {
      if (id != null) 'order_id': id,
      if (customerId != null) 'customer_id': customerId,
      if (salespersonId != null) 'salesperson_id': salespersonId,
      'subtotal': subtotal,
      'discount_total': discountTotal,
      'service_charge': serviceCharge,
      'tip_amount': tipAmount,
      'tax': tax,
      'total': total,
      'status': status,
      'payment_method': paymentMethod,
      'business_mode': businessMode,
      if (stationId != null) 'station_id': stationId,
      if (waiterName != null) 'waiter_name': waiterName,
      if (tableNo != null) 'table_no': tableNo,
      if (comment != null) 'comment': comment,
      if (items != null) 'items': items!.map((item) => item.toJson()).toList(),
    };
  }

  // Helper methods
  bool get isRetailMode => businessMode == 'retail';
  bool get isRestaurantMode => businessMode == 'restaurant';
  bool get isReservationMode => businessMode == 'reservation';
  bool get isHold => status == 'hold';

  OrderModel copyWith({
    int? id,
    int? customerId,
    int? salespersonId,
    double? subtotal,
    double? discountTotal,
    double? serviceCharge,
    double? tipAmount,
    double? tax,
    double? total,
    String? status,
    String? paymentMethod,
    String? businessMode,
    int? stationId,
    String? waiterName,
    String? tableNo,
    String? billNumber,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderItemModel>? items,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      salespersonId: salespersonId ?? this.salespersonId,
      subtotal: subtotal ?? this.subtotal,
      discountTotal: discountTotal ?? this.discountTotal,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      tipAmount: tipAmount ?? this.tipAmount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      businessMode: businessMode ?? this.businessMode,
      stationId: stationId ?? this.stationId,
      waiterName: waiterName ?? this.waiterName,
      tableNo: tableNo ?? this.tableNo,
      billNumber: billNumber ?? this.billNumber,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  static List<OrderModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}

/// Order Item Model
class OrderItemModel {
  final int? id;
  final int orderId;
  final int? productId;
  final int? menuId;
  final String? productName;
  final int quantity;
  final double price;
  final double discountAmount;
  final double totalAmount;
  final bool isRestaurantItem;
  final bool isReservation;
  final DateTime? createdAt;

  OrderItemModel({
    this.id,
    required this.orderId,
    this.productId,
    this.menuId,
    this.productName,
    this.quantity = 1,
    required this.price,
    this.discountAmount = 0.0,
    this.totalAmount = 0.0,
    this.isRestaurantItem = false,
    this.isReservation = false,
    this.createdAt,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as int?,
      orderId: (json['order_id'] as num).toInt(),
      productId: json['product_id'] as int?,
      menuId: json['menu_id'] as int?,
      productName: json['product_name'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num).toDouble(),
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      isRestaurantItem: (json['is_restaurant_item'] as num?)?.toInt() == 1,
      isReservation: (json['is_reservation'] as num?)?.toInt() == 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'order_id': orderId,
      if (productId != null) 'product_id': productId,
      if (menuId != null) 'menu_id': menuId,
      if (productName != null) 'product_name': productName,
      'quantity': quantity,
      'price': price,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'is_restaurant_item': isRestaurantItem ? 1 : 0,
      'is_reservation': isReservation ? 1 : 0,
    };
  }

  OrderItemModel copyWith({
    int? id,
    int? orderId,
    int? productId,
    int? menuId,
    String? productName,
    int? quantity,
    double? price,
    double? discountAmount,
    double? totalAmount,
    bool? isRestaurantItem,
    bool? isReservation,
    DateTime? createdAt,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      menuId: menuId ?? this.menuId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      isRestaurantItem: isRestaurantItem ?? this.isRestaurantItem,
      isReservation: isReservation ?? this.isReservation,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static List<OrderItemModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => OrderItemModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}

