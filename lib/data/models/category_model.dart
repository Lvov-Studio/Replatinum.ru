class Category {
  final String id;
  final String name;
  final String image;
  final String code;

  Category({
    required this.id,
    required this.name,
    required this.image,
    this.code = '',
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }
}
