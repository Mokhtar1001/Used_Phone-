class Product {
  final String id;
  final String? categoryId;
  final String nameAr;
  final String nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final double price;
  final String? condition;
  final String? brand;
  final String? storage;
  final String? color;
  final String status;
  final DateTime createdAt;
  final DateTime? soldAt;
  final int viewsCount;
  final List<String> images;

  Product({
    required this.id,
    this.categoryId,
    required this.nameAr,
    required this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    required this.price,
    this.condition,
    this.brand,
    this.storage,
    this.color,
    required this.status,
    required this.createdAt,
    this.soldAt,
    this.viewsCount = 0,
    this.images = const [],
  });

  String name(bool isArabic) => isArabic ? nameAr : nameEn;
  String description(bool isArabic) => (isArabic ? descriptionAr : descriptionEn) ?? '';
  String get mainImage => images.isNotEmpty ? images.first : '';

  factory Product.fromJson(Map<String, dynamic> json) {
    final imagesJson = json['product_images'] as List<dynamic>? ?? [];
    final images = imagesJson.map((e) => e['image_url'] as String).toList();

    return Product(
      id: json['id'],
      categoryId: json['category_id'],
      nameAr: json['name_ar'] ?? '',
      nameEn: json['name_en'] ?? '',
      descriptionAr: json['description_ar'],
      descriptionEn: json['description_en'],
      price: (json['price'] as num).toDouble(),
      condition: json['condition'],
      brand: json['brand'],
      storage: json['storage'],
      color: json['color'],
      status: json['status'] ?? 'available',
      createdAt: DateTime.parse(json['created_at']),
      soldAt: json['sold_at'] != null ? DateTime.parse(json['sold_at']) : null,
      viewsCount: json['views_count'] ?? 0,
      images: images,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'category_id': categoryId,
        'name_ar': nameAr,
        'name_en': nameEn,
        'description_ar': descriptionAr,
        'description_en': descriptionEn,
        'price': price,
        'condition': condition,
        'brand': brand,
        'storage': storage,
        'color': color,
        'status': status,
      };
}
