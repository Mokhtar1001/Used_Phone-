class ProductCategory {
  final String id;
  final String nameAr;
  final String nameEn;
  final String? icon;

  ProductCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.icon,
  });

  String name(bool isArabic) => isArabic ? nameAr : nameEn;

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'],
      nameAr: json['name_ar'] ?? '',
      nameEn: json['name_en'] ?? '',
      icon: json['icon'],
    );
  }
}
