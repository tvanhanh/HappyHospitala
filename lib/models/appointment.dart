class Appointment {
  final String id;

  final String patientId;
  final String doctorId;

  // Thông tin bệnh nhân
  final String patientName;
  final String phone;
  final String gender;
  final String address;
  final String cccd; // 👈 MỚI THÊM
  final String birthDate; // 👈 MỚI THÊM
  final String patientEmail;
  final String patientAvatar;

  // Thông tin y tế
  final String medicalHistory;
  final String allergies;
  final String reason;
  final String imageUrl;

  // Thông tin lịch khám
  final String date;
  final String time;
  final String status;

  // Thông tin bác sĩ & phòng khám (Dữ liệu Populate)
  final String departmentName;
  final String doctorName;
  final String doctorAvatar;
  final String doctorSpecialty;

  // Thông tin thanh toán (Billing) 👈 MỚI THÊM
  final double originalFee;
  final double finalFee;
  final String paymentMethod;
  final bool isPaid;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    required this.phone,
    required this.gender,
    required this.address,
    required this.cccd,
    required this.birthDate,
    required this.patientEmail,
    required this.patientAvatar,
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
    required this.originalFee,
    required this.finalFee,
    required this.paymentMethod,
    required this.isPaid,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctor'];
    final department = json['departmentId'] ?? json['department'];

    final doctorUser = (doctor is Map) ? doctor['userId'] : null;

    // Hàm hỗ trợ parse số tiền an toàn
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return Appointment(
      id: json['_id']?.toString() ?? '',
      patientId: (json['patient'] is Map)
          ? (json['patient']['_id']?.toString() ?? '')
          : (json['patient']?.toString() ?? ''),
      doctorId: doctor is Map ? doctor['_id']?.toString() ?? '' : '',

      patientName: json['patientName'] ?? '',
      phone: json['phone'] ?? '',
      gender: json['gender'] ?? '',
      address: json['address'] ?? '',
      cccd: json['cccd'] ?? '', // 👈 Hứng dữ liệu
      birthDate: json['birthDate']?.toString() ??
          '', // 👈 Hứng dữ liệu (có thể chứa ký tự T trong ISO date)
      patientEmail: (json['patient'] is Map)
          ? (json['patient']['email']?.toString() ?? '')
          : (json['patientEmail']?.toString() ?? (json['email']?.toString() ?? (json['phone'] != null && json['phone'].toString().isNotEmpty ? "${json['phone']}@happyhospital.com" : 'patient@happyhospital.com'))),
      patientAvatar: (json['patient'] is Map)
          ? (json['patient']['avatar']?.toString() ?? '')
          : (json['patientAvatar']?.toString() ?? ''),

      medicalHistory: json['medicalHistory'] ?? '',
      allergies: json['allergies'] ?? '',
      reason: json['reason'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',

      doctorName: (doctorUser is Map)
          ? (doctorUser['fullName'] ?? doctorUser['name'] ?? '')
          : '',
      doctorAvatar: (doctorUser is Map) ? (doctorUser['avatar'] ?? '') : '',
      doctorSpecialty: (doctor is Map) ? (doctor['specialty'] ?? '') : '',

      imageUrl: json['imageUrl'] ?? json['imageUr'] ?? '',

      departmentName: (department is Map)
          ? (department['departmentName'] ?? department['name'] ?? '')
          : '',
      status: json['status'] ?? 'pending',

      // 👈 Hứng dữ liệu thanh toán
      originalFee: parseDouble(json['originalFee']),
      finalFee: parseDouble(json['finalFee']),
      paymentMethod: json['paymentMethod'] ?? 'cash',
      isPaid: json['isPaid'] == true,
    );
  }

  Appointment copyWith({
    String? status,
    bool? isPaid,
  }) {
    return Appointment(
      id: id,
      patientId: patientId,
      doctorId: doctorId,
      patientName: patientName,
      phone: phone,
      gender: gender,
      address: address,
      cccd: cccd,
      birthDate: birthDate,
      patientEmail: patientEmail,
      patientAvatar: patientAvatar,
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
      originalFee: originalFee,
      finalFee: finalFee,
      paymentMethod: paymentMethod,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}
