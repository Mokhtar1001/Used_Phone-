import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../core/theme.dart';

/// كارت المنتج - "List Card" حسب براند بوك Merchnt:
/// صورة مربعة صغيرة على الشمال (فيها Grade chip أعلى يسارها)،
/// وعلى اليمين: العنوان، سطر مواصفات Mid Gray، السعر Bold، وسطر التوفر الدلالي.
/// مستخدم في: المفضلة (Saved items) وأي قائمة نتائج طولية بدل الشبكة.
class ProductListCard extends StatelessWidget {
  final Product product;
  final bool isArabic;
  final VoidCallback onTap;
  final Widget? trailing;

  const ProductListCard({
    super.key,
    required this.product,
    required this.isArabic,
    required this.onTap,
    this.trailing,
  });

  String? get _gradeLabel => product.gradeLetter;

  String get _specLine {
    final parts = <String>[
      if (product.brand != null && product.brand!.isNotEmpty) product.brand!,
      if (product.storage != null && product.storage!.isNotEmpty) product.storage!,
      if (product.color != null && product.color!.isNotEmpty) product.color!,
    ];
    return parts.join(' · ');
  }

  String get _titleLine {
    final storage = product.storage;
    final name = product.name(isArabic);
    if (storage != null && storage.isNotEmpty && !name.contains(storage)) {
      return '$name — $storage';
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final isSold = product.status == 'sold';
    final isReserved = product.status == 'reserved';
    final isAvailable = !isSold && !isReserved;

    return Material(
      color: AppTheme.pureWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.lightGray),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصورة + الـ Grade chip
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 84,
                      height: 84,
                      child: product.mainImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.mainImage,
                              fit: BoxFit.cover,
                              placeholder: (c, u) => Container(color: AppTheme.offWhite),
                              errorWidget: (c, u, e) =>
                                  const Icon(Icons.phone_android, size: 28, color: AppTheme.midGray),
                            )
                          : Container(
                              color: AppTheme.offWhite,
                              child: const Icon(Icons.phone_android, size: 28, color: AppTheme.midGray),
                            ),
                    ),
                  ),
                  if (_gradeLabel != null)
                    PositionedDirectional(
                      start: 4,
                      top: 4,
                      child: Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: AppTheme.charcoal, shape: BoxShape.circle),
                        child: Text(
                          _gradeLabel!,
                          style: const TextStyle(color: AppTheme.pureWhite, fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // التفاصيل
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                    ),
                    if (_specLine.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        _specLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppTheme.midGray, fontWeight: FontWeight.w400),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${product.price.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                      style: const TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isAvailable ? AppTheme.successColor : AppTheme.midGray,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isAvailable
                              ? (isArabic ? 'متاح — جاهز للشحن' : 'In Stock — ready to ship')
                              : isReserved
                                  ? (isArabic ? 'محجوز' : 'Reserved')
                                  : (isArabic ? 'تم البيع' : 'Sold'),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isAvailable ? AppTheme.successColor : AppTheme.midGray,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
