class BillModel {
  final String? id;                // ID hóa đơn (nếu có)
  final String patientId;          // Mã bệnh nhân
  final String patientName;        // Tên bệnh nhân
  final String timeArrived;        // Thời gian đến phòng khám
  final List<BillServiceItem> services; // Danh sách dịch vụ thanh toán
  final List<BillMedicineItem> medicines; // Danh sách thuốc thanh toán
  final String paymentMethod;      // Phương thức thanh toán (Tiền mặt / Thẻ)
  final int cashGiven;             // Tiền khách đưa (nếu dùng tiền mặt)
  final int totalServicesPrice;    // Tổng tiền dịch vụ
  final int totalMedicinesPrice;   // Tổng tiền thuốc
  final int finalTotalPrice;       // TỔNG THANH TOÁN CHỐT cuối cùng
  final DateTime? createdAt;       // Thời gian lập hóa đơn

  BillModel({
    this.id,
    required this.patientId,
    required this.patientName,
    required this.timeArrived,
    required this.services,
    required this.medicines,
    required this.paymentMethod,
    required this.cashGiven,
    required this.totalServicesPrice,
    required this.totalMedicinesPrice,
    required this.finalTotalPrice,
    this.createdAt,
  });

  // Factory map dữ liệu an toàn từ API/Database hoặc khi bấm nút "Xác nhận"
  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['_id'] as String?,
      patientId: json['patientId']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? 'Vô danh',
      timeArrived: json['timeArrived']?.toString() ?? 'Hôm nay',
      
      // Map danh sách dịch vụ an toàn
      services: (json['services'] as List? ?? [])
          .map((item) => BillServiceItem.fromJson(item as Map<String, dynamic>))
          .toList(),
          
      // Map danh sách thuốc an toàn (bao gồm cả unit)
      medicines: (json['medicines'] as List? ?? [])
          .map((item) => BillMedicineItem.fromJson(item as Map<String, dynamic>))
          .toList(),
          
      paymentMethod: json['paymentMethod']?.toString() ?? 'Tiền mặt',
      cashGiven: int.tryParse(json['cashGiven']?.toString() ?? '0') ?? 0,
      totalServicesPrice: int.tryParse(json['totalServicesPrice']?.toString() ?? '0') ?? 0,
      totalMedicinesPrice: int.tryParse(json['totalMedicinesPrice']?.toString() ?? '0') ?? 0,
      finalTotalPrice: int.tryParse(json['finalTotalPrice']?.toString() ?? '0') ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  // Chuyển đối tượng sang Map/JSON để gửi lên Backend lưu vào Database
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'patientId': patientId,
      'patientName': patientName,
      'timeArrived': timeArrived,
      'services': services.map((x) => x.toJson()).toList(),
      'medicines': medicines.map((x) => x.toJson()).toList(),
      'paymentMethod': paymentMethod,
      'cashGiven': cashGiven,
      'totalServicesPrice': totalServicesPrice,
      'totalMedicinesPrice': totalMedicinesPrice,
      'finalTotalPrice': finalTotalPrice,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}

// --- Object con đại diện cho từng dịch vụ trong hóa đơn ---
class BillServiceItem {
  final String name;
  final int sellingPrice;

  BillServiceItem({required this.name, required this.sellingPrice});

  factory BillServiceItem.fromJson(Map<String, dynamic> json) {
    return BillServiceItem(
      name: json['name']?.toString() ?? 'Dịch vụ chỉ định',
      sellingPrice: int.tryParse(json['sellingPrice']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'sellingPrice': sellingPrice,
  };
}

// --- Object con đại diện cho từng loại thuốc trong hóa đơn (Đã map Unit an toàn) ---
class BillMedicineItem {
  final String id;
  final String name;
  final String quantity;
  final int sellingPrice;
  final String unit; // 🟢 Lưu trữ đơn vị thực tế (Hộp, viên, vỉ, chai...)

  BillMedicineItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.sellingPrice,
    required this.unit,
  });

  factory BillMedicineItem.fromJson(Map<String, dynamic> json) {
    return BillMedicineItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Tên thuốc',
      quantity: json['quantity']?.toString() ?? '0',
      sellingPrice: int.tryParse(json['sellingPrice']?.toString() ?? '0') ?? 0,
      // 🟢 Map đơn vị chuẩn như map giá, nếu lỗi/null lập tức trả về 'Đơn vị' dự phòng
      unit: (json['unit'] != null && json['unit'].toString().isNotEmpty) 
          ? json['unit'].toString() 
          : 'Đơn vị',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'sellingPrice': sellingPrice,
    'unit': unit,
  };
}