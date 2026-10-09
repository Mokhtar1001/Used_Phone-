import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import '../../widgets/customer_nav_actions.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/product_service.dart';
import '../../services/inspection_service.dart';
import '../../services/favorites_service.dart';
import '../../services/reviews_service.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/guest_guard.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import 'checkout_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final _productService = ProductService();
  final _inspectionService = InspectionService();
  final _favoritesService = FavoritesService();
  final _reviewsService = ReviewsService();

  Product? _product;
  List<Review> _reviews = [];
  double? _avgRating;
  bool _isFavorite = false;
  bool _isRequestingInspection = false;
  bool _hasError = false;
  bool _viewCounted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _hasError = false);
    try {
      final product = await _productService.getProductById(widget.productId);
      final reviews = await _reviewsService.getProductReviews(widget.productId);
      final avg = await _reviewsService.getAverageRating(widget.productId);

      final userId = context.read<AuthProvider>().profile?.id;
      bool isFav = false;
      if (userId != null) {
        final favIds = await _favoritesService.getMyFavoriteIds(userId);
        isFav = favIds.contains(widget.productId);
      }

      // زوّد عداد المشاهدات مرة واحدة بس لكل مرة تفتح فيها الشاشة
      if (!_viewCounted) {
        _viewCounted = true;
        _productService.incrementViews(widget.productId);
      }

      setState(() {
        _product = product;
        _reviews = reviews;
        _avgRating = avg;
        _isFavorite = isFav;
      });
    } catch (e) {
      setState(() => _hasError = true);
    }
  }

  Future<void> _toggleFavorite() async {
    if (!await requireLogin(
      context,
      messageAr: 'محتاج تسجل دخول عشان تضيف المنتج للمفضلة',
      messageEn: 'You need to log in to add this to favorites',
    )) return;
    if (!mounted) return;

    final userId = context.read<AuthProvider>().profile?.id;
    if (userId == null) return;
    final newState = await _favoritesService.toggleFavorite(userId, widget.productId);
    if (mounted) setState(() => _isFavorite = newState);
  }

  /// "معاينة في المحل": بيسجّل طلب فحص للمنتج ده (نفس نظام طلبات الفحص الموجود) والأدمن بيتواصل مع العميل.
  /// ⚠️ الشات مخفي مؤقتًا. لإرجاعه: رجّع ChatService/ChatScreen وزرار "شات عن هذا المنتج" من تاريخ git.
  Future<void> _requestInspection() async {
    if (!await requireLogin(
      context,
      messageAr: 'محتاج تسجل دخول عشان تطلب معاينة في المحل',
      messageEn: 'You need to log in to request an in-store inspection',
    )) return;
    if (!mounted) return;

    final customerId = context.read<AuthProvider>().profile?.id;
    if (customerId == null) return;
    final isArabic = context.read<LocaleProvider>().isArabic;

    setState(() => _isRequestingInspection = true);
    try {
      await _inspectionService.createRequest(productId: widget.productId, customerId: customerId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, size: 40, color: AppTheme.successColor),
          content: Text(
            isArabic
                ? 'تم إرسال طلب المعاينة! هنتواصل معاك لتحديد ميعاد في المحل.'
                : "Inspection request sent! We'll contact you to arrange a time at the store.",
            textAlign: TextAlign.center,
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(isArabic ? 'تمام' : 'OK'))],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isArabic ? 'حصل خطأ، حاول تاني' : 'Something went wrong, please try again')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRequestingInspection = false);
    }
  }

  void _showReviewDialog() {
    final isArabic = context.read<LocaleProvider>().isArabic;
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isArabic ? 'قيّم المنتج' : 'Rate this product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                      icon: Icon(i < rating ? Icons.star : Icons.star_border, color: const Color(0xFFFFC107)),
                      onPressed: () => setDialogState(() => rating = i + 1),
                    )),
              ),
              TextField(
                controller: commentController,
                decoration: InputDecoration(hintText: isArabic ? 'تعليق (اختياري)' : 'Comment (optional)'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(isArabic ? 'إلغاء' : 'Cancel')),
            TextButton(
              onPressed: () async {
                final customerId = context.read<AuthProvider>().profile?.id;
                if (customerId != null) {
                  await _reviewsService.addOrUpdateReview(
                    productId: widget.productId,
                    customerId: customerId,
                    rating: rating,
                    comment: commentController.text.trim().isEmpty ? null : commentController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    _load();
                  }
                }
              },
              child: Text(isArabic ? 'إرسال' : 'Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    if (_hasError) {
      return Scaffold(
        appBar: _appBar(isArabic),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(isArabic ? 'حصل خطأ أثناء تحميل المنتج' : 'Something went wrong loading this product'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: Text(isArabic ? 'حاول تاني' : 'Retry')),
            ],
          ),
        ),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: _appBar(context.read<LocaleProvider>().isArabic),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final product = _product!;
    final isDesktop = Responsive.isDesktop(context);

    // ───────── موبايل/تطبيق: نفس الشكل القديم (صور بالسحب + بار سفلي) ─────────
    final mobileBody = RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImageGallery(images: product.images, height: 280, showArrows: false, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(product, isArabic),
                  const SizedBox(height: 20),
                  _buildDescription(product, isArabic),
                  const SizedBox(height: 24),
                  _buildReviews(isArabic),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // ───────── ويب/ديسكتوب: عمودين - الصور بسهم من الجنب + التفاصيل والأزرار جنبها ─────────
    final desktopBody = RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _ImageGallery(
                      images: product.images,
                      height: 540,
                      showArrows: true,
                      fit: BoxFit.contain,
                      framed: true,
                    ),
                  ),
                  const SizedBox(width: 56),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderInfo(product, isArabic),
                        const SizedBox(height: 24),
                        _buildActions(product, isArabic),
                        const SizedBox(height: 28),
                        _buildDescription(product, isArabic),
                        const SizedBox(height: 28),
                        _buildReviews(isArabic),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: _appBar(isArabic),
      body: isDesktop ? desktopBody : mobileBody,
      // على الديسكتوب الأزرار جوه العمود الأيمن، فمفيش بار سفلي
      bottomNavigationBar: isDesktop
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildActions(product, isArabic),
              ),
            ),
    );
  }

  /// ديسكتوب/ويب: الهيدر العلوي بس (من غير شريط "Product Details" تحته).
  /// موبايل/تطبيق: شريط عادي بزرار الرجوع والعنوان.
  /// المفضلة بقت جنب اسم التليفون، والمشاركة اتشالت.
  PreferredSizeWidget _appBar(bool isArabic) {
    if (Responsive.isDesktop(context)) return customerTopNav();
    return AppBar(title: Text(isArabic ? 'تفاصيل المنتج' : 'Product Details'));
  }

  /// الاسم + المفضلة + السعر + التقييم + المواصفات + الجريد والضمان
  Widget _buildHeaderInfo(Product product, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(product.name(isArabic), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              tooltip: isArabic ? 'المفضلة' : 'Favorite',
              onPressed: _toggleFavorite,
              icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : AppTheme.charcoal),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '${product.price.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
              style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
            ),
            if (_avgRating != null) ...[
              const SizedBox(width: 12),
              const Icon(Icons.star, size: 18, color: Color(0xFFFFC107)),
              const SizedBox(width: 2),
              Text('${_avgRating!.toStringAsFixed(1)} (${_reviews.length})'),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (product.brand != null && product.brand!.isNotEmpty) _InfoChip(icon: Icons.branding_watermark, label: product.brand!),
            if (product.storage != null && product.storage!.isNotEmpty) _InfoChip(icon: Icons.sd_storage, label: product.storage!),
            if (product.color != null && product.color!.isNotEmpty) _InfoChip(icon: Icons.color_lens, label: product.color!),
          ],
        ),
        const SizedBox(height: 16),
        _GradeWarrantyBlock(
          gradeLetter: product.gradeLetter,
          gradeLabel: product.condition == null ? null : _conditionLabel(product.condition!, isArabic),
          warrantyLabel: product.warrantyMonths > 0 ? product.warrantyLabel(isArabic) : null,
          isArabic: isArabic,
        ),
      ],
    );
  }

  Widget _buildDescription(Product product, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isArabic ? 'الوصف' : 'Description', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text(product.description(isArabic), style: const TextStyle(height: 1.5)),
      ],
    );
  }

  Widget _buildReviews(bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(isArabic ? 'التقييمات (${_reviews.length})' : 'Reviews (${_reviews.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton.icon(
              onPressed: _showReviewDialog,
              icon: const Icon(Icons.star_border, size: 18),
              label: Text(isArabic ? 'قيّم' : 'Rate'),
            ),
          ],
        ),
        if (_reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(isArabic ? 'لا يوجد تقييمات بعد' : 'No reviews yet', style: TextStyle(color: Colors.grey.shade500)),
          )
        else
          ..._reviews.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(r.customerName ?? (isArabic ? 'عميل' : 'Customer'), style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        ...List.generate(5, (i) => Icon(i < r.rating ? Icons.star : Icons.star_border, size: 13, color: const Color(0xFFFFC107))),
                      ],
                    ),
                    if (r.comment != null) Text(r.comment!, style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              )),
      ],
    );
  }

  /// زرار الشراء + "معاينة في المحل" (مكان زرار الشات المخفي مؤقتًا)
  Widget _buildActions(Product product, bool isArabic) {
    final sold = product.status == 'sold';
    return Row(
      children: [
        if (!sold)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                if (!await requireLogin(context)) return;
                if (!context.mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutScreen(product: product)));
              },
              icon: const Icon(Icons.credit_card, size: 18),
              label: Text(isArabic ? 'شراء' : 'Buy'),
            ),
          ),
        if (!sold) const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: (sold || _isRequestingInspection) ? null : _requestInspection,
            icon: _isRequestingInspection
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.storefront_outlined, size: 18),
            label: Text(
              isArabic ? 'معاينة في المحل' : 'Inspection in the store',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  String _conditionLabel(String condition, bool isArabic) {
    switch (condition) {
      case 'excellent':
        return isArabic ? 'ممتازة' : 'Excellent';
      case 'good':
        return isArabic ? 'جيدة' : 'Good';
      case 'fair':
        return isArabic ? 'مقبولة' : 'Fair';
      default:
        return condition;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

/// معرض الصور: سحب (موبايل) + أسهم من الجنب وعدّاد (ويب).
class _ImageGallery extends StatefulWidget {
  final List<String> images;
  final double height;
  final bool showArrows;
  final BoxFit fit;
  final bool framed; // إطار بحواف دايرة وخلفية فاتحة (للويب)

  const _ImageGallery({
    required this.images,
    required this.height,
    required this.showArrows,
    required this.fit,
    this.framed = false,
  });

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int page) {
    _controller.animateToPage(page, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;

    if (images.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.framed ? AppTheme.offWhite : Colors.grey.shade200,
          borderRadius: widget.framed ? BorderRadius.circular(16) : null,
        ),
        child: const Center(child: Icon(Icons.phone_android, size: 80)),
      );
    }

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final canGoPrev = _index > 0;
    final canGoNext = _index < images.length - 1;
    final showControls = widget.showArrows && images.length > 1;

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.framed ? 16 : 0),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: widget.framed ? AppTheme.offWhite : null,
                // يسمح بالسحب بالماوس على الويب كمان
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) => CachedNetworkImage(
                      imageUrl: images[i],
                      fit: widget.fit,
                    ),
                  ),
                ),
              ),
            ),
            if (showControls && canGoPrev)
              PositionedDirectional(
                start: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _GalleryArrow(
                    icon: isRtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                    onTap: () => _go(_index - 1),
                  ),
                ),
              ),
            if (showControls && canGoNext)
              PositionedDirectional(
                end: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _GalleryArrow(
                    icon: isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                    onTap: () => _go(_index + 1),
                  ),
                ),
              ),
            if (showControls)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.charcoal.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_index + 1} / ${images.length}',
                      style: const TextStyle(color: AppTheme.pureWhite, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GalleryArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GalleryArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.pureWhite.withValues(alpha: 0.92),
      shape: const CircleBorder(side: BorderSide(color: AppTheme.lightGray)),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 28, color: AppTheme.charcoal),
        ),
      ),
    );
  }
}

/// بلوك الجريد + الضمان (الضمان تحت الجريد)
class _GradeWarrantyBlock extends StatelessWidget {
  final String? gradeLetter;
  final String? gradeLabel;
  final String? warrantyLabel;
  final bool isArabic;

  const _GradeWarrantyBlock({
    required this.gradeLetter,
    required this.gradeLabel,
    required this.warrantyLabel,
    required this.isArabic,
  });

  Widget _badge(String letter) {
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
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: border),
      child: Text(letter, style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }

  Widget _row({required Widget leading, required String caption, required String value}) {
    return Row(
      children: [
        SizedBox(width: 34, height: 34, child: Center(child: leading)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(caption, style: const TextStyle(fontSize: 12.5, color: AppTheme.midGray)),
              const SizedBox(height: 1),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (gradeLabel != null)
        _row(
          leading: _badge(gradeLetter ?? '-'),
          caption: isArabic ? 'الحالة (Grade)' : 'Grade',
          value: gradeLabel!,
        ),
      if (warrantyLabel != null)
        _row(
          leading: const Icon(Icons.verified_user_outlined, size: 26, color: AppTheme.gold),
          caption: isArabic ? 'الضمان' : 'Warranty',
          value: warrantyLabel!,
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.offWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: AppTheme.lightGray)),
            rows[i],
          ],
        ],
      ),
    );
  }
}