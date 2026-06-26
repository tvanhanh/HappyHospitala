class ClinicService {
  final String id;
  final String name;
  final String description;
  final String duration;
  final double price;

  const ClinicService({
    required this.id,
    required this.name,
    this.description = '',
    this.duration = '',
    this.price = 0.0,
  });

  factory ClinicService.fromJson(Map<String, dynamic> json) {
    return ClinicService(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'description': description,
        'duration': duration,
        'price': price,
      };
}
