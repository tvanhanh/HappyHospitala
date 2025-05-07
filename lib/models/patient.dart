class Patient {
  final String name;
  final int age;
  final String phone;
  final String gender;
  final String department;
  final int severity;
  final String medicalId;
  final DateTime createdDate;
  final DateTime updatedDate;
  final String status;

  Patient({
    required this.name,
    required this.age,
    required this.phone,
    required this.gender,
    required this.department,
    required this.severity,
    required this.medicalId,
    required this.createdDate,
    required this.updatedDate,
    required this.status,
  });

  String get id => name + phone;
}
