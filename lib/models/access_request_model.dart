class AccessRequestModel {
  final String id;
  final String requestId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String? doctorDepartment;
  // 🎯 THÊM VÀO ĐÂY: Cho phép null để tránh lỗi crash nếu backend chưa kịp map xong
  final String? doctorName; 

  
  final String reason;
  final String requestedRecordId;
  final String status;
  final String? time;
  final DateTime? createdAt;

  AccessRequestModel({
    required this.id,
    required this.requestId,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    
    this.doctorName, 
    this.doctorDepartment,
    
    required this.reason,
    required this.requestedRecordId,
    required this.status,
    this.time,
    this.createdAt,
  });

  factory AccessRequestModel.fromJson(Map<String, dynamic> json) {
    return AccessRequestModel(
      id: (json['_id'] ?? json['id']).toString(),
      requestId: json['requestId']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? 'Bệnh nhân hệ thống',
      doctorId: json['doctorId']?.toString() ?? '',
   
      doctorName: json['doctorName'],            
      doctorDepartment: json['doctorDepartment'],
      reason: json['reason']?.toString() ?? '',
      requestedRecordId: json['requestedRecordId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      time: json['time']?.toString() ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}