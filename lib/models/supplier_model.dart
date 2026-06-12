class SupplierModel {
  final String? id;
  final String supplierName;
  final String? contactName;
  final String phone;
  final String? email;
  final String supplierType; // 🟢 THÊM MỚI: Loại hình cung cấp
  final String status;       // 🟢 THÊM MỚI: Trạng thái hợp tác
  final String? address;
  final String? note;

  SupplierModel({
    this.id,
    required this.supplierName,
    this.contactName,
    required this.phone,
    this.email,
    required this.supplierType, // 🟢 Bắt buộc truyền vào khi tạo instance
    required this.status,       // 🟢 Bắt buộc truyền vào khi tạo instance
    this.address,
    this.note,
  });

  // Chuyển từ JSON (API trả về) sang Object Dart
  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['_id'],
      supplierName: json['supplierName'] ?? '',
      contactName: json['contactName'],
      phone: json['phone'] ?? '',
      email: json['email'],
      // 🟢 Đọc dữ liệu từ JSON, nếu null sẽ tự gán giá trị mặc định hệ thống
      supplierType: json['supplierType'] ?? 'medicine_local', 
      status: json['status'] ?? 'active',
      address: json['address'],
      note: json['note'],
    );
  }

  // Chuyển từ Object Dart sang JSON để gửi lên Backend
  Map<String, dynamic> toJson() {
    return {
      "supplierName": supplierName,
      "contactName": contactName ?? "",
      "phone": phone,
      "email": email ?? "",
      "supplierType": supplierType, 
      "status": status,             
      "address": address ?? "",
      "note": note ?? "",
    };
  }
}