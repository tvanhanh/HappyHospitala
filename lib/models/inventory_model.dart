class InventoryModel {
  final String id;
  final dynamic medicineId; 
  final String medicineName;
  final String batchNumber;
  final double importPrice;
  final double exportPrice; // 🔥 Đây là giá bán riêng của từng lô hàng
  final DateTime? expiryDate;
  final int originalQuantity;
  final int currentQuantity;
  final String importReceiptId;
  final String status;

  // Các thuộc tính liên kết bổ sung từ bảng Medicine (khi dùng populate)
  String manufacturer;
  int minStock;
  String groupName;

  InventoryModel({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.batchNumber,
    required this.importPrice,
    required this.exportPrice,
    this.expiryDate,
    required this.originalQuantity,
    required this.currentQuantity,
    required this.importReceiptId,
    required this.status,
    this.manufacturer = 'N/A',
    this.minStock = 0,
    this.groupName = 'Khác',
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    var medIdData = json['medicineId'];
    String manufacturer = 'N/A';
    int minStock = 0;
    String groupName = 'Khác';

    // 1. Nếu medicineId đã được populate thành một Object/Map từ Backend
    if (medIdData is Map<String, dynamic>) {
      manufacturer = medIdData['manufacturer'] ?? 'N/A';
      minStock = medIdData['minStock'] ?? 0;
      
      // Nếu Backend trả về thông tin nhóm danh mục (CategoryId) dạng Object populated
      if (medIdData['categoryId'] is Map<String, dynamic>) {
        groupName = medIdData['categoryId']['name'] ?? 'Khác';
      }
    }

    return InventoryModel(
      id: json['id'] ?? json['_id'] ?? '',
      // Đảm bảo lấy ID gốc của thuốc cho dù có populate hay chưa
      medicineId: medIdData is Map ? (medIdData['_id'] ?? '') : medIdData.toString(),
      medicineName: json['medicineName'] ?? '',
      batchNumber: json['batchNumber'] ?? '',
      importPrice: (json['importPrice'] ?? 0).toDouble(),
      
      // 🔥 ĐÃ SỬA: Map chính xác giá bán của riêng lô này từ trường 'exportPrice' ở tầng ngoài JSON
      exportPrice: (json['exportPrice'] ?? json['sellingPrice'] ?? 0).toDouble(), 
      
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      originalQuantity: json['originalQuantity'] ?? 0,
      currentQuantity: json['currentQuantity'] ?? 0,
      importReceiptId: json['importReceiptId'] ?? '',
      status: json['status'] ?? 'active',
      manufacturer: manufacturer,
      minStock: minStock,
      groupName: groupName,
    );
  }
}