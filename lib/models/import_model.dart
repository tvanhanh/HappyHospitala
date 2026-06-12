class ImportModel {
  final dynamic supplierId;
  final String? note;
  final double totalAmount;
  final List<ImportItem> products;
  final String status; 
  final String? createdBy;

  ImportModel({
    required this.supplierId,
    this.note,
    required this.totalAmount,
    required this.products,
    required this.status,
    this.createdBy
  });

  Map<String, dynamic> toJson() => {
    'supplierId': supplierId,
    'note': note,
    'totalAmount': totalAmount,
    'products': products.map((item) => item.toJson()).toList(),
    'status': status,
    'createdBy': createdBy
  };

  factory ImportModel.fromJson(Map<String, dynamic> json) {
    String? supplierNameResolved;
  dynamic rawSupplier = json['supplierId'];
  
  if (rawSupplier is Map) {
    supplierNameResolved = rawSupplier['supplierName'];
  }
    return ImportModel(
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
  final String? batchNumber;
  final DateTime? expiryDate;

  ImportItem({
    required this.medicineId,
    required this.medicineName,
    required this.quantity,
    required this.importPrice,
    this.batchNumber,
    this.expiryDate,
  });

  Map<String, dynamic> toJson() => {
    'medicineId': medicineId,
    'medicineName': medicineName,
    'quantity': quantity,
    'importPrice': importPrice,
    'batchNumber': batchNumber,
    'expiryDate': expiryDate?.toUtc().toIso8601String(),
  };

  factory ImportItem.fromJson(Map<String, dynamic> json) {
    return ImportItem(
      medicineId: json['medicineId'],
      medicineName: json['medicineName'] ?? '',
      quantity: json['quantity'] ?? 0,
      importPrice: (json['importPrice'] ?? 0).toDouble(),
      batchNumber: json['batchNumber'],
      // 🚀 Đảm bảo ép về Local Time sau khi parse từ chuỗi UTC của Server về cho chuẩn múi giờ hiển thị
      expiryDate: json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate'])?.toLocal() : null,
    );
  }
}