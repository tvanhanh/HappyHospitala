class Room {
  final String id;
  final String roomNumber;
  final int floor;
  final String status;
  final String? specialtyId;

  const Room({
    required this.id,
    required this.roomNumber,
    required this.floor,
    required this.status,
    this.specialtyId,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['_id']?.toString() ?? '',
      roomNumber: json['roomNumber']?.toString() ?? '',
      floor: json['floor'] as int? ?? 0,
      status: json['status']?.toString() ?? 'Available',
      specialtyId: json['specialtyId'] is Map 
          ? json['specialtyId']['_id']?.toString() 
          : json['specialtyId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'roomNumber': roomNumber,
        'floor': floor,
        'status': status,
        if (specialtyId != null) 'specialtyId': specialtyId,
      };
}
