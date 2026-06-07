class Specialty {
  final String id;
  final String name;
  final String description;
  final String imageUrl;

  const Specialty({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
  });

  factory Specialty.fromJson(Map<String, dynamic> json) {
    return Specialty(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
      };
}
