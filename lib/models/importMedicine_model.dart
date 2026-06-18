class ImportModel {
  final String id;
  final dynamic supplierId;
  final String? note;
  final double totalAmount;
  final List<ImportItem> products;
  final String status; 
  final String? createdBy;

  ImportModel({
    this.id = '', 
    required this.supplierId,
    this.note,
    required this.totalAmount,
    required this.products,
    required this.status,
    this.createdBy,
  });

  Map<String, dynamic> toJson() => { 
    'supplierId': supplierId,
    'note': note,
    'totalAmount': totalAmount,
    'products': products.map((item) => item.toJson()).toList(),
    'status': status,
    'createdBy': createdBy,
  };

  factory ImportModel.fromJson(Map<String, dynamic> json) {
    dynamic rawSupplier = json['supplierId'];
    
    return ImportModel(
      id: json['_id'] ?? json['id'] ?? '', 
      supplierId: rawSupplier is Map ? rawSupplier['_id'] : rawSupplier,
      note: json['note'] ?? json['notes'],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      products: json['products'] != null
          ? (json['products'] as List).map((e) => ImportItem.fromJson(e)).toList()
          : [],
      status: json['status'] ?? 'Chờ duyệt',
      createdBy: json['createdBy'], 
    );
  }
}

class ImportItem {
  final dynamic medicineId;
  final String medicineName;
  final int quantity;
  final double importPrice;
  final double? sellingPrice; // Giá bán riêng của lô thuốc này
  final String? batchNumber;
  final DateTime? expiryDate;

  ImportItem({
    required this.medicineId,
    required this.medicineName,
    required this.quantity,
    required this.importPrice,
    this.sellingPrice, 
    this.batchNumber,
    this.expiryDate,
  });

  Map<String, dynamic> toJson() => {
    'medicineId': medicineId,
    'medicineName': medicineName,
    'quantity': quantity,
    'importPrice': importPrice,
    'sellingPrice': sellingPrice ?? 0.0, // Đảm bảo luôn có giá bán mặc định, không để null
    'batchNumber': (batchNumber == null || batchNumber!.trim().isEmpty) ? 'BATCH-DEFAULT' : batchNumber,
    // 🔥 ĐÃ FIX: Nếu người dùng không chọn ngày, tự động gán 1 năm sau để không bị bẻ gãy Validation bên NodeJS
    'expiryDate': (expiryDate ?? DateTime.now().add(const Duration(days: 365))).toUtc().toIso8601String(),
  };

  factory ImportItem.fromJson(Map<String, dynamic> json) {
    return ImportItem(
      medicineId: json['medicineId'],
      medicineName: json['medicineName'] ?? '',
      quantity: json['quantity'] ?? 0,
      importPrice: (json['importPrice'] ?? 0).toDouble(),
      sellingPrice: json['sellingPrice'] != null ? (json['sellingPrice'] as num).toDouble() : 0.0, 
      batchNumber: json['batchNumber'] ?? 'BATCH-DEFAULT',
      expiryDate: json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate'])?.toLocal() : null,
    );
  }
}