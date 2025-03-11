class Doctor {
  final String name;
  final String specialty;
  final String imageUrl;
  final String hospital;
  final int experience;
  final String description;
  final String phone;
  final String email;
  final String address;
  final String workingHours;
  final String bookingLink; // Link Google Form đặt lịch

  Doctor({
    required this.name,
    required this.specialty,
    required this.imageUrl,
    required this.hospital,
    required this.experience,
    required this.description,
    required this.phone,
    required this.email,
    required this.address,
    required this.workingHours,
    required this.bookingLink,
  });
}
