/// Room Model
/// 
/// Represents room inventory and details

class RoomModel {
  final int? roomId;
  final String roomNumber;
  final int floor;
  final String roomType; // 'single', 'double', 'suite', 'deluxe'
  final int capacity;
  final double pricePerNight;
  final String status; // 'available', 'occupied', 'maintenance'
  final String? amenities;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RoomModel({
    this.roomId,
    required this.roomNumber,
    required this.floor,
    required this.roomType,
    required this.capacity,
    required this.pricePerNight,
    this.status = 'available',
    this.amenities,
    this.createdAt,
    this.updatedAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      roomId: json['room_id'] as int?,
      roomNumber: json['room_number'] as String,
      floor: (json['floor'] as num).toInt(),
      roomType: json['room_type'] as String,
      capacity: (json['capacity'] as num).toInt(),
      pricePerNight: (json['price_per_night'] as num).toDouble(),
      status: json['status'] as String? ?? 'available',
      amenities: json['amenities'] as String?,
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
      if (roomId != null) 'room_id': roomId,
      'room_number': roomNumber,
      'floor': floor,
      'room_type': roomType,
      'capacity': capacity,
      'price_per_night': pricePerNight,
      'status': status,
      if (amenities != null) 'amenities': amenities,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Helper methods
  bool get isAvailable => status == 'available';
  bool get isOccupied => status == 'occupied';
  bool get isMaintenance => status == 'maintenance';
  
  List<String> get amenitiesList {
    if (amenities == null || amenities!.isEmpty) return [];
    return amenities!.split(',').map((e) => e.trim()).toList();
  }

  RoomModel copyWith({
    int? roomId,
    String? roomNumber,
    int? floor,
    String? roomType,
    int? capacity,
    double? pricePerNight,
    String? status,
    String? amenities,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomModel(
      roomId: roomId ?? this.roomId,
      roomNumber: roomNumber ?? this.roomNumber,
      floor: floor ?? this.floor,
      roomType: roomType ?? this.roomType,
      capacity: capacity ?? this.capacity,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      status: status ?? this.status,
      amenities: amenities ?? this.amenities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<RoomModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => RoomModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}

