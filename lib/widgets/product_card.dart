import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../screens/customer/cart_screen.dart';

/// كارت المنتج - مطابق لكارت صفحة الـ HTML (.product-card):
/// صورة على خلفية off-white بنسبة 1:0.95، بادچ الجريد (A/B/C) أعلى الشمال،
/// العنوان 15.5/700، المواصفات 13 بلون mid-gray، السعر 17/700، وسطر التوفر بالأخضر.
/// + زرار Add to cart تحت.
class ProductCard extends StatefulWidget {
  final Product product;
  final bool isArabic;
  final VoidCallback onTap;
  final bool showCompare;
  final bool isCompareSelected;
  final VoidCallback? onCompareToggle;

  /// زرار الإضافة للسلة (بيتقفل في شاشات الأدمن)
  final bool showAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.isArabic,
    required this.onTap,
    this.showCompare = false,
    this.isCompareSelected = false,
    this.onCompareToggle,
    this.showAddToCart = true,
  });

  /// ارتفاع الكارت في الجريد حسب عرضه (الصورة 0.95 من العرض + المعلومات + الزرار).
  /// استخدمه في SliverGridDelegateWithFixedCrossAxisCount(mainAxisExtent: ...)
  static double gridExtent(double cardWidth, {bool withCart = true}) => cardWidth * 0.95 + (withCart ? 196 : 142);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hover = false;

  Product get product => widget.product;
  bool get isArabic => widget.isArabic;

  String get _specLine {
    final parts = <String>[
      if (product.storage != null && product.storage!.isNotEmpty) product.storage!,
      if (product.color != null && product.color!.isNotEmpty) product.color!,
    ];
    return parts.join(' · ');
  }

  String get _price {
    final n = NumberFormat('#,##0').format(product.price);
    return isArabic ? '$n ج.م' : 'EGP $n';
  }

  void _addToCart() {
    context.read<CartProvider>().add(product);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'تمت الإضافة للسلة' : 'Added to cart'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: isArabic ? 'عرض السلة' : 'View cart',
            onPressed: _openCart,
          ),
        ),
      );
  }

  void _openCart() => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));

  @override
  Widget build(BuildContext context) {
    final isSold = product.status == 'sold';
    final isReserved = product.status == 'reserved';
    final isAvailable = !isSold && !isReserved;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.lightGray),
          boxShadow: _hover
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 4))]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ───── منطقة الصورة ─────
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: AppTheme.offWhite,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                          child: product.mainImage.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: product.mainImage,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                  placeholder: (c, u) => const SizedBox.shrink(),
                                  errorWidget: (c, u, e) => const _PhoneIcon(),
                                )
                              : const _PhoneIcon(),
                        ),
                        if (product.gradeLetter != null)
                          PositionedDirectional(start: 12, top: 12, child: _GradeChip(letter: product.gradeLetter!)),
                        if (widget.showCompare)
                          PositionedDirectional(
                            end: 10,
                            top: 10,
                            child: GestureDetector(
                              onTap: widget.onCompareToggle,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: widget.isCompareSelected
                                      ? AppTheme.charcoal
                                      : AppTheme.pureWhite.withValues(alpha: 0.92),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.isCompareSelected ? Icons.check : Icons.compare_arrows,
                                  size: 16,
                                  color: widget.isCompareSelected ? AppTheme.pureWhite : AppTheme.midGray,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ───── المعلومات ─────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name(isArabic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppTheme.charcoal),
                      ),
                      const SizedBox(height: 4),
                      if (_specLine.isNotEmpty)
                        Text(
                          _specLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppTheme.midGray),
                        ),
                      const SizedBox(height: 10),
                      Text(_price, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.charcoal)),
                      const SizedBox(height: 6),
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
                                ? (isArabic ? 'متاح' : 'In stock')
                                : isReserved
                                    ? (isArabic ? 'محجوز' : 'Reserved')
                                    : (isArabic ? 'تم البيع' : 'Sold'),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isAvailable ? AppTheme.successColor : AppTheme.midGray,
                            ),
                          ),
                        ],
                      ),
                      if (widget.showAddToCart) ...[
                        const SizedBox(height: 14),
                        _cartButton(isAvailable, isSold),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cartButton(bool isAvailable, bool isSold) {
    final inCart = context.watch<CartProvider>().contains(product.id);
    const compact = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600);

    if (!isAvailable) {
      return SizedBox(
        width: double.infinity,
        height: 40,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, textStyle: compact),
          child: Text(isSold ? (isArabic ? 'تم البيع' : 'Sold') : (isArabic ? 'محجوز' : 'Reserved')),
        ),
      );
    }

    if (inCart) {
      return SizedBox(
        width: double.infinity,
        height: 40,
        child: OutlinedButton.icon(
          onPressed: _openCart,
          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, textStyle: compact),
          icon: const Icon(Icons.check, size: 17),
          label: Text(isArabic ? 'في السلة' : 'In cart'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton.icon(
        onPressed: _addToCart,
        style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, textStyle: compact),
        icon: const Icon(Icons.shopping_cart_outlined, size: 17),
        label: Text(isArabic ? 'أضف للسلة' : 'Add to cart'),
      ),
    );
  }
}

/// بادچ الجريد: A = شاركول مليان | B = أبيض بحد شاركول | C = أبيض بحد رمادي (زي .grade-chip)
class _GradeChip extends StatelessWidget {
  final String letter;
  const _GradeChip({required this.letter});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;
    switch (letter) {
      case 'A':
        bg = AppTheme.charcoal;
        fg = AppTheme.pureWhite;
        break;
      case 'B':
        bg = AppTheme.pureWhite;
        fg = AppTheme.charcoal;
        border = Border.all(color: AppTheme.charcoal, width: 1.5);
        break;
      default:
        bg = AppTheme.pureWhite;
        fg = AppTheme.midGray;
        border = Border.all(color: AppTheme.midGray, width: 1.5);
    }
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: border),
      child: Text(letter, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

/// أيقونة الموبايل المفرّغة لما مفيش صورة (زي .phone-icon: 46x82)
class _PhoneIcon extends StatelessWidget {
  const _PhoneIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 82,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.lightGray, width: 3),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 6, left: 5, right: 5),
      child: Container(height: 2, color: AppTheme.lightGray),
    );
  }
}