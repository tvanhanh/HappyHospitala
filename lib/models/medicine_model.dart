class MedicineModel {
  final String? id;
  final String medicineCode;
  final String medicineName;
  final String categoryId;
  final String supplierId;
  final String dosage;
  final String unit;
  final String manufacturer;
  final double sellingPrice; 
  final int minStock;      
  final String? imageUrl;   
  final String? description;
  final String status;       

  MedicineModel({
    this.id,
    required this.medicineCode,
    required this.medicineName,
    required this.categoryId,
    required this.supplierId,
    required this.dosage,
    required this.unit,
    required this.manufacturer,
    required this.sellingPrice,
    required this.minStock,    
    this.imageUrl,            
    this.description,
    this.status = 'active',
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: json['_id'],
      medicineCode: json['medicineCode'] ?? '',
      medicineName: json['medicineName'] ?? '',
      
   
      categoryId: json['categoryId'] is Map 
          ? json['categoryId']['_id'] 
          : (json['categoryId'] ?? ''),
          
      supplierId: json['supplierId'] is Map 
          ? json['supplierId']['_id'] 
          : (json['supplierId'] ?? ''),
          
      dosage: json['dosage'] ?? '',
      unit: json['unit'] ?? 'Viên',
      manufacturer: json['manufacturer'] ?? '',
      
     
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      
      
      minStock: (json['minStock'] as num?)?.toInt() ?? 10,
      imageUrl: json['imageUrl'], 
      description: json['description'],
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "medicineName": medicineName,
      "categoryId": categoryId,
      "supplierId": supplierId,
      "dosage": dosage,
      "unit": unit,
      "manufacturer": manufacturer,
      "sellingPrice": sellingPrice,
      "minStock": minStock,
      "imageUrl": imageUrl ?? "",   
      "description": description ?? "",
      "status": status,
    };
  }
}