

class PrescriptionModel {
  final String? id;
  final String appointmentId;
  final String diagnosis;
  final String status;
 
  final String patientId;        
  final String patientName;      
  final String? patientPhone;    
  final String? birthDate;       
  final String? gender;          
  final String? healthInsurance; 

  final List<PrescribedMedicine> medicines;
  final List<PrescribedService> services;
  final String doctorId;
  final String doctorName;
  final DateTime? createdAt;
  final String? paymentMethod;
  final int? totalPrice;

  PrescriptionModel({
    this.id,
    required this.appointmentId,
    required this.diagnosis,
    required this.status,
    required this.patientId,
    required this.patientName,
    this.patientPhone,
    this.birthDate,
    this.gender,
    this.healthInsurance,
    required this.medicines,
    required this.services,
    required this.doctorId,
    required this.doctorName,
    this.createdAt,
    this.paymentMethod,
    this.totalPrice
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['_id'] ?? json['id'],
      appointmentId: json['appointmentId']?.toString() ?? '',
      diagnosis: json['diagnosis']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      patientId: json['patientId']?.toString() ?? json['idBN']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? '',
      patientPhone: json['patientPhone'] ?? json['phone'],
      birthDate: json['birthDate'],
      gender: json['gender']?.toString(),
      healthInsurance: json['healthInsurance'] ?? json['bhyt'],
      doctorId: json['doctorId']?.toString() ?? json['idBS']?.toString() ?? '',
      doctorName: json['doctorName']?.toString() ?? '',
      medicines: json['medicines'] != null
          ? List<PrescribedMedicine>.from(
              json['medicines'].map((x) => PrescribedMedicine.fromJson(x)),
            )
          : [],
      services: json['services'] != null
          ? List<PrescribedService>.from(
              json['services'].map((x) => PrescribedService.fromJson(x)),
            )
          : [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      paymentMethod: json['paymentMethod'] ?? json['payment_method'],
      totalPrice: json['totalPrice'] ?? json['total_price'] ?? json['total'] ?? json['amount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'appointmentId': appointmentId,
      'diagnosis': diagnosis,
      'status': status,
      'patientId': patientId,
      'patientName': patientName,
      'patientPhone': patientPhone, 
      'birthDate': birthDate,
      'gender': gender,
      'healthInsurance': healthInsurance,
      'medicines': medicines.map((x) => x.toJson()).toList(),
      'services': services.map((x) => x.toJson()).toList(),
      'doctorId': doctorId,
      'doctorName': doctorName,
    };
  }
}

class PrescribedMedicine {
  final String medicineId;
  final String name;
  final String quantity;
  final String usage;
  final int sellingPrice;
  final String unit;
  PrescribedMedicine({
    required this.medicineId,
    required this.name,
    required this.quantity,
    required this.usage,
    required this.sellingPrice,
    required this.unit,
  });

  factory PrescribedMedicine.fromJson(Map<String, dynamic> json) {
    return PrescribedMedicine(
      medicineId: json['id']?.toString() ?? json['medicineId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity: json['quantity']?.toString() ?? '1',
      usage: json['usage']?.toString() ?? '',
      sellingPrice: json['sellingPrice'] is int ? json['sellingPrice'] : (int.tryParse(json['sellingPrice']?.toString() ?? '0') ?? 0),
      unit: json['unit']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': medicineId,
      'name': name,
      'quantity': quantity,
      'usage': usage,
      'sellingPrice': sellingPrice,
      'unit': unit,
    };
  }
}

class PrescribedService {
  final String serviceId;
  final String name;
  final int price;

  PrescribedService({
    required this.serviceId,
    required this.name,
    required this.price,
  });

  factory PrescribedService.fromJson(Map<String, dynamic> json) {
    return PrescribedService(
      serviceId: json['id']?.toString() ?? json['serviceId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: json['price'] is int ? json['price'] : (int.tryParse(json['price']?.toString() ?? '0') ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': serviceId,
      'name': name,
      'price': price,
    };
  }
}