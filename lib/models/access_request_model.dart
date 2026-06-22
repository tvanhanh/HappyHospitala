class AccessRequestModel {
  final String id;
  final String requestId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String? doctorDepartment;
  final String? doctorName; 
  final String reason;
  final String requestedRecordId;
  final String status;
  final String? time;
  final DateTime? createdAt;
  
  // 🎯 THÊM VÀO ĐÂY: Lưu danh sách ID các nhân viên được phép truy cập hồ sơ này
  final List<String> allowedStaffs; 

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
    required this.allowedStaffs, // Bắt buộc truyền vào (hoặc để mặc định)
  });

  factory AccessRequestModel.fromJson(Map<String, dynamic> json) {
    // Xử lý chuyển đổi mảng từ JSON (dynamic) sang List<String> một cách an toàn
    var staffsFromJson = json['allowedStaffs'];
    List<String> staffsList = staffsFromJson != null 
        ? List<String>.from(staffsFromJson.map((item) => item.toString().trim()))
        : [];

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
      
      // Gán mảng đã xử lý vào model
      allowedStaffs: staffsList, 
    );
  }
}