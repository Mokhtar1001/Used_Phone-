import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../core/theme.dart';

/// كارت المنتج - "Grid Card" حسب برand بوك Merchnt:
/// صورة بحواف دايرة + Grade chip (بادچ أسود) أعلى يسار،
/// العنوان (H3 SemiBold)، سطر مواصفات بلون Mid Gray، السعر Bold شاركول،
/// وسطر توفر بلون دلالي (أخضر/رمادي) - الاستثناء الوحيد من باليتة البراند.
class ProductCard extends StatelessWidget {
  final Product product;
  final bool isArabic;
  final VoidCallback onTap;
  final bool showCompare;
  final bool isCompareSelected;
  final VoidCallback? onCompareToggle;

  const ProductCard({
    super.key,
    required this.product,
    required this.isArabic,
    required this.onTap,
    this.showCompare = false,
    this.isCompareSelected = false,
    this.onCompareToggle,
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

  @override
  Widget build(BuildContext context) {
    final isSold = product.status == 'sold';
    final isReserved = product.status == 'reserved';
    final isAvailable = !isSold && !isReserved;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(8),
        side: const BorderSide(color: AppTheme.lightGray),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppTheme.pureWhite,
        alignment: Alignment.topLeft,
      ).copyWith(
        // الكارت نفسه مش زرار بالمعنى البصري - إلغاء أي حالة hover/pressed تلوّن الخلفية
        overlayColor: WidgetStateProperty.all(AppTheme.offWhite.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.expand(
                    child: product.mainImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.mainImage,
                            fit: BoxFit.cover,
                            placeholder: (c, u) => Container(color: AppTheme.offWhite),
                            errorWidget: (c, u, e) =>
                                const Icon(Icons.phone_android, size: 36, color: AppTheme.midGray),
                          )
                        : Container(
                            color: AppTheme.offWhite,
                            child: const Icon(Icons.phone_android, size: 36, color: AppTheme.midGray),
                          ),
                  ),
                ),
                // Grade chip - بادچ أسود دايري أعلى يسار الصورة
                if (_gradeLabel != null)
                  PositionedDirectional(
                    start: 6,
                    top: 6,
                    child: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppTheme.charcoal, shape: BoxShape.circle),
                      child: Text(
                        _gradeLabel!,
                        style: const TextStyle(color: AppTheme.pureWhite, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                // زرار إضافة للمقارنة - أعلى يمين
                if (showCompare)
                  PositionedDirectional(
                    end: 6,
                    top: 6,
                    child: GestureDetector(
                      onTap: onCompareToggle,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isCompareSelected ? AppTheme.charcoal : AppTheme.pureWhite.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompareSelected ? Icons.check : Icons.compare_arrows,
                          size: 14,
                          color: isCompareSelected ? AppTheme.pureWhite : AppTheme.midGray,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان - H3 مصغّر شوية عشان يتناسب مع مساحة الكارت
                Text(
                  product.name(isArabic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                ),
                if (_specLine.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _specLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppTheme.midGray, fontWeight: FontWeight.w400),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${product.price.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                  style: const TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 3),
                // سطر التوفر - الاستثناء الدلالي الوحيد (أخضر = متاح، رمادي = مش متاح)
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
                    const SizedBox(width: 4),
                    Text(
                      isAvailable
                          ? (isArabic ? 'متاح' : 'In Stock')
                          : isReserved
                              ? (isArabic ? 'محجوز' : 'Reserved')
                              : (isArabic ? 'تم البيع' : 'Sold'),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isAvailable ? AppTheme.successColor : AppTheme.midGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
