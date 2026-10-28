import '../core/egypt_governorates.dart';

/// عنوان توصيل للعميل (لحد عنوانين لكل عميل)
class Address {
  final String? id;
  final String label;
  final String governorate; // اسم المحافظة بالإنجليزي (Cairo, Giza...)
  final String? city;
  final String street;
  final String? building;
  final String? landmark;

  const Address({
    this.id,
    this.label = 'Home',
    required this.governorate,
    this.city,
    required this.street,
    this.building,
    this.landmark,
  });

  factory Address.fromJson(Map<dynamic, dynamic> json) => Address(
        id: json['id']?.toString(),
        label: (json['label'] ?? 'Home').toString(),
        governorate: (json['governorate'] ?? '').toString(),
        city: json['city']?.toString(),
        street: (json['street'] ?? '').toString(),
        building: json['building']?.toString(),
        landmark: json['landmark']?.toString(),
      );

  /// بدون id و user_id (بيتضافوا وقت الحفظ)
  Map<String, dynamic> toJson() => {
        'label': label,
        'governorate': governorate,
        'city': city,
        'street': street,
        'building': building,
        'landmark': landmark,
      };

  /// القاهرة والجيزة = "Inside Cairo" في السلة
  bool get isGreaterCairo => governorate == 'Cairo' || governorate == 'Giza';

  /// سطر واحد للعرض: الشارع، العمارة، المنطقة، المحافظة
  String summary(bool isArabic) => [
        street,
        building,
        city,
        governorateLabel(governorate, isArabic),
      ].where((e) => e != null && e.trim().isNotEmpty).join('، ');
}
