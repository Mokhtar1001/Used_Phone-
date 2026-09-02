import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../core/theme.dart';

/// كارت منتج مأخوذ من ستايل template "Shoplon": صورة بحواف دايرة،
/// بادچ حالة أعلى يمين، اسم الماركة UPPERCASE صغير، العنوان، والسعر بلون مميز.
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

  @override
  Widget build(BuildContext context) {
    final isSold = product.status == 'sold';
    final isReserved = product.status == 'reserved';

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(8),
        side: const BorderSide(color: AppTheme.blackColor10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.topLeft,
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
                            placeholder: (c, u) => Container(color: AppTheme.greyBg),
                            errorWidget: (c, u, e) => const Icon(Icons.phone_android, size: 36),
                          )
                        : Container(color: AppTheme.greyBg, child: const Icon(Icons.phone_android, size: 36)),
                  ),
                ),
                // بادچ الحالة - زي بادچ "% off" بالظبط في التمبلت
                if (isSold || isReserved)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      height: 18,
                      decoration: BoxDecoration(
                        color: isSold ? AppTheme.errorColor : Colors.orange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          isSold ? (isArabic ? 'تم البيع' : 'Sold') : (isArabic ? 'محجوز' : 'Reserved'),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                // زرار إضافة للمقارنة
                if (showCompare)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: GestureDetector(
                      onTap: onCompareToggle,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isCompareSelected ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompareSelected ? Icons.check : Icons.compare_arrows,
                          size: 14,
                          color: isCompareSelected ? Colors.white : AppTheme.blackColor60,
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
                if (product.brand != null && product.brand!.isNotEmpty)
                  Text(
                    product.brand!.toUpperCase(),
                    style: const TextStyle(fontSize: 10, color: AppTheme.blackColor40, fontWeight: FontWeight.w500),
                  ),
                const SizedBox(height: 4),
                Text(
                  product.name(isArabic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.blackColor),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.price.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                  style: const TextStyle(color: AppTheme.priceColor, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
