class RoomModel {
  final String id;
  final String patientName;
  final String lastMessage;
  final DateTime updatedAt;
  final int unreadCount;
  final String? patientAvatar;
  final String? patientPhone;
  final String? patientAge;
  final String? patientGender;
  final String? patientStatus;

  RoomModel({
    required this.id,
    required this.patientName,
    required this.lastMessage,
    required this.updatedAt,
    this.unreadCount = 0,
    this.patientAvatar,
    this.patientPhone,
    this.patientAge,
    this.patientGender,
    this.patientStatus,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
  // 1. Tự động tính tuổi từ trường 'dateOfBirth' của database
  String calculatedAge = '--';
  if (json['dateOfBirth'] != null) {
    try {
      DateTime dob = DateTime.parse(json['dateOfBirth']);
      int age = DateTime.now().year - dob.year;
      calculatedAge = age.toString();
    } catch (_) {}
  }

  return RoomModel(
    id: json['_id'] ?? json['id'] ?? '',
    patientName: json['patientName'] ?? json['fullName'] ?? 'Bệnh nhân ẩn danh', 
    lastMessage: json['lastMessage'] ?? '',
    updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    unreadCount: json['unreadCount'] ?? 0,
    patientAvatar: json['patientAvatar'] ?? json['avatar'],               
    patientPhone: json['patientPhone'] ?? json['phoneNumber'],           
    patientAge: json['patientAge'] ?? calculatedAge,                  
    patientGender: json['patientGender'] ?? json['gender'],               
    patientStatus: json['patientStatus'] ?? json['status'],            
  );
}
}