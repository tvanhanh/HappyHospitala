class Profile {
  final String phone;
  final String avatar;
  final String specialty;
  final String experience;
  final String degree;
  final String description;
  final String workShift;
  final String price;

  Profile({
    required this.phone,
    required this.avatar,
    required this.specialty,
    required this.experience,
    required this.degree,
    required this.description,
    required this.workShift,
    required this.price,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      phone: json['phone'] ?? '',
      avatar: json['avatar'] ?? '',
      specialty: json['specialty'] ?? '',
      experience: json['experience'] ?? '',
      degree: json['degree'] ?? '',
      description: json['description'] ?? '',
      workShift: json['workShift'] ?? '',
      price: (json['price'] ?? json['prince'] ?? '')
          .toString(), // 🔥 fix lỗi của bạn
    );
  }
}
