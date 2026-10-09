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

  /// مدة الضمان بالشهور (الافتراضي 3 شهور)
  final int warrantyMonths;

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
    this.warrantyMonths = 3,
  });

  String name(bool isArabic) => isArabic ? nameAr : nameEn;
  String description(bool isArabic) => (isArabic ? descriptionAr : descriptionEn) ?? '';
  /// "3 months" / "3 شهور"
  String warrantyLabel(bool isArabic) {
    final m = warrantyMonths;
    if (isArabic) {
      if (m == 1) return 'شهر';
      if (m == 2) return 'شهرين';
      if (m >= 3 && m <= 10) return '$m شهور';
      return '$m شهر';
    }
    return '$m ${m == 1 ? 'month' : 'months'}';
  }

  String get mainImage => images.isNotEmpty ? images.first : '';

  /// تحويل الـ condition (excellent/good/fair) لحرف Grade مختصر (A/B/C) لعرضه في البادچ
  String? get gradeLetter {
    switch (condition) {
      case 'excellent':
        return 'A';
      case 'good':
        return 'B';
      case 'fair':
        return 'C';
      default:
        return condition != null && condition!.isNotEmpty ? condition![0].toUpperCase() : null;
    }
  }

  /// الاسم المعروض للحالة بالكامل (للفلاتر وتفاصيل المنتج)
  String conditionLabel(bool isArabic) {
    switch (condition) {
      case 'excellent':
        return isArabic ? 'ممتازة (Grade A)' : 'Excellent (Grade A)';
      case 'good':
        return isArabic ? 'جيدة (Grade B)' : 'Good (Grade B)';
      case 'fair':
        return isArabic ? 'مقبولة (Grade C)' : 'Fair (Grade C)';
      default:
        return condition ?? '';
    }
  }

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
      warrantyMonths: (json['warranty_months'] as num?)?.toInt() ?? 3,
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
        'warranty_months': warrantyMonths,
      };
}