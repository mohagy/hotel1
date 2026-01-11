/// Guest Model
/// 
/// Represents guest information

class GuestModel {
  final int? guestId;
  final String firstName;
  final String lastName;
  final String? email;
  final String phone;
  final String idType; // 'passport', 'driver_license', 'national_id'
  final String idNumber;
  final String? country;
  final String guestType; // 'regular', 'vip', 'corporate'
  final String? specialRequests;
  final int? roomId; // Optional room assignment
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GuestModel({
    this.guestId,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.phone,
    required this.idType,
    required this.idNumber,
    this.country,
    this.guestType = 'regular',
    this.specialRequests,
    this.roomId,
    this.createdAt,
    this.updatedAt,
  });

  factory GuestModel.fromJson(Map<String, dynamic> json) {
    return GuestModel(
      guestId: json['guest_id'] as int?,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String,
      idType: json['id_type'] as String,
      idNumber: json['id_number'] as String,
      country: json['country'] as String?,
      guestType: json['guest_type'] as String? ?? 'regular',
      specialRequests: json['special_requests'] as String?,
      roomId: json['room_id'] as int?,
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
      if (guestId != null) 'guest_id': guestId,
      'first_name': firstName,
      'last_name': lastName,
      if (email != null) 'email': email,
      'phone': phone,
      'id_type': idType,
      'id_number': idNumber,
      if (country != null) 'country': country,
      'guest_type': guestType,
      if (specialRequests != null) 'special_requests': specialRequests,
      if (roomId != null) 'room_id': roomId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Helper methods
  String get fullName => '$firstName $lastName';
  bool get isVip => guestType == 'vip';
  bool get isCorporate => guestType == 'corporate';

  GuestModel copyWith({
    int? guestId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? idType,
    String? idNumber,
    String? country,
    String? guestType,
    String? specialRequests,
    int? roomId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GuestModel(
      guestId: guestId ?? this.guestId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      country: country ?? this.country,
      guestType: guestType ?? this.guestType,
      specialRequests: specialRequests ?? this.specialRequests,
      roomId: roomId ?? this.roomId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<GuestModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => GuestModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}

