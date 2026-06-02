class Appointment {
  final String id;

  final String patientId;
  final String doctorId;

  final String patientName;
  final String phone;
  final String gender;
  final String address;
  final String medicalHistory;
  final String allergies;

  final String reason;
  final String date;
  final String time;
final String departmentName;
  final String doctorName;
  final String doctorAvatar;

  final String imageUrl; // 👈 ẢNH BỆNH
  final String status;
  final String doctorSpecialty;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    required this.phone,
    required this.gender,
    required this.address,
    required this.medicalHistory,
    required this.allergies,
    required this.reason,
    required this.date,
    required this.time,
    required this.doctorName,
    required this.doctorAvatar,
    required this.imageUrl,
    required this.status,
    required this.doctorSpecialty,
    required this.departmentName,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctor'];
    final department = json['departmentId'];

    return Appointment(
      id: json['_id']?.toString() ?? '',

      patientId: json['patient']?.toString() ?? '',
      doctorId: doctor is Map ? doctor['_id']?.toString() ?? '' : '',

      patientName: json['patientName'] ?? '',
      phone: json['phone'] ?? '',
      gender: json['gender'] ?? '',
      address: json['address'] ?? '',
      medicalHistory: json['medicalHistory'] ?? '',
      allergies: json['allergies'] ?? '',

      reason: json['reason'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      doctorName: (doctor is Map) ? (doctor['name'] ?? '') : '',
      doctorAvatar:
          (doctor is Map) ? ((doctor['profile'] as Map?)?['avatar'] ?? '') : '',
      // 👇 ảnh bệnh
      imageUrl: json['imageUrl'] ?? '',
     departmentName:  (department is Map) ? (department['departmentName'] ?? '') : '',
      status: json['status'] ?? 'pending',
      doctorSpecialty: (doctor is Map)
          ? ((doctor['profile'] as Map?)?['specialty'] ?? '')
          : '',
    );
  }
  Appointment copyWith({
    String? status,
  }) {
    return Appointment(
      id: id,
      patientId: patientId,
      doctorId: doctorId,
      patientName: patientName,
      phone: phone,
      gender: gender,
      address: address,
      medicalHistory: medicalHistory,
      allergies: allergies,
      reason: reason,
      date: date,
      time: time,
      doctorName: doctorName,
      departmentName: departmentName,
      doctorAvatar: doctorAvatar,
      imageUrl: imageUrl,
      status: status ?? this.status,
      doctorSpecialty: doctorSpecialty,
    );
  }
}
