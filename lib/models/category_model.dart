class CategoryModel {
  final String? id;
  final String categoryname; 
  final String? description; 

  CategoryModel({
    this.id,
    required this.categoryname,
    this.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] as String?,
      categoryname: json['categoryname'] as String? ?? '', // Khớp với Backend
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'categoryname': categoryname,
      if (description != null) 'description': description,
    };
  }
}