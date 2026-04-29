class Doctor {
  final String id;
  final String name;
  final String avatar;
  final String specialty;
  final String experience;
  final String price;

  Doctor({
    required this.id,
    required this.name,
    required this.avatar,
    required this.specialty,
    required this.experience,
    required this.price,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      specialty: json['specialty'] ?? '',
      experience: json['experience'] ?? '',
      price: json['price']?.toString() ?? '',
    );
  }
}
