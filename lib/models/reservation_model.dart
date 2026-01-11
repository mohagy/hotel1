/// Reservation Model
/// 
/// Represents booking records

class ReservationModel {
  final int? reservationId;
  final int guestId;
  final int roomId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final String status; // 'reserved', 'checked_in', 'checked_out', 'cancelled'
  final double? totalPrice;
  final int? numberOfNights;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Related data (from joins)
  final String? reservationNumber;
  final String? guestName;
  final String? guestEmail;
  final String? guestPhone;
  final String? roomNumber;
  final String? roomType;
  final double? balanceDue;

  ReservationModel({
    this.reservationId,
    required this.guestId,
    required this.roomId,
    required this.checkInDate,
    required this.checkOutDate,
    this.status = 'reserved',
    this.totalPrice,
    this.numberOfNights,
    this.createdAt,
    this.updatedAt,
    this.reservationNumber,
    this.guestName,
    this.guestEmail,
    this.guestPhone,
    this.roomNumber,
    this.roomType,
    this.balanceDue,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      reservationId: json['reservation_id'] as int?,
      guestId: (json['guest_id'] as num).toInt(),
      roomId: (json['room_id'] as num).toInt(),
      checkInDate: DateTime.parse(json['check_in_date'] as String),
      checkOutDate: DateTime.parse(json['check_out_date'] as String),
      status: json['status'] as String? ?? 'reserved',
      totalPrice: json['total_price'] != null
          ? (json['total_price'] as num).toDouble()
          : null,
      numberOfNights: json['number_of_nights'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      reservationNumber: json['reservation_number'] as String?,
      guestName: json['guest_name'] as String?,
      guestEmail: json['guest_email'] as String?,
      guestPhone: json['guest_phone'] as String?,
      roomNumber: json['room_number'] as String?,
      roomType: json['room_type'] as String?,
      balanceDue: json['balance_due'] != null
          ? (json['balance_due'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (reservationId != null) 'reservation_id': reservationId,
      'guest_id': guestId,
      'room_id': roomId,
      'check_in_date': checkInDate.toIso8601String().split('T')[0],
      'check_out_date': checkOutDate.toIso8601String().split('T')[0],
      'status': status,
      if (totalPrice != null) 'total_price': totalPrice,
      if (numberOfNights != null) 'number_of_nights': numberOfNights,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Helper methods
  bool get isReserved => status == 'reserved';
  bool get isCheckedIn => status == 'checked_in';
  bool get isCheckedOut => status == 'checked_out';
  bool get isCancelled => status == 'cancelled';
  
  int get calculatedNights {
    return checkOutDate.difference(checkInDate).inDays;
  }

  ReservationModel copyWith({
    int? reservationId,
    int? guestId,
    int? roomId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    String? status,
    double? totalPrice,
    int? numberOfNights,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? reservationNumber,
    String? guestName,
    String? guestEmail,
    String? guestPhone,
    String? roomNumber,
    String? roomType,
    double? balanceDue,
  }) {
    return ReservationModel(
      reservationId: reservationId ?? this.reservationId,
      guestId: guestId ?? this.guestId,
      roomId: roomId ?? this.roomId,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      numberOfNights: numberOfNights ?? this.numberOfNights,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reservationNumber: reservationNumber ?? this.reservationNumber,
      guestName: guestName ?? this.guestName,
      guestEmail: guestEmail ?? this.guestEmail,
      guestPhone: guestPhone ?? this.guestPhone,
      roomNumber: roomNumber ?? this.roomNumber,
      roomType: roomType ?? this.roomType,
      balanceDue: balanceDue ?? this.balanceDue,
    );
  }

  static List<ReservationModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => ReservationModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}

