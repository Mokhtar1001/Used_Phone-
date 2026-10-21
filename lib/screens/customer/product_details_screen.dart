import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import '../../widgets/customer_nav_actions.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../services/product_service.dart';
import '../../services/favorites_service.dart';
import '../../models/product.dart';
import '../../models/product_overview.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/guest_guard.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../core/constants.dart';
import 'book_store_visit_sheet.dart';
import 'checkout_screen.dart';
import 'my_inspection_requests_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final _productService = ProductService();
  final _favoritesService = FavoritesService();

  Product? _product;
  bool _isFavorite = false;
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

  /// "معاينة في المحل": العميل بيختار ميعاد (يوم + وقت) وممكن يطلب نحجزله التليفون لحد ما يجي،
  /// والأدمن بيأكد الميعاد من لوحة التحكم.
  /// ⚠️ الشات مخفي مؤقتًا. لإرجاعه: رجّع ChatService/ChatScreen وزرار "شات عن هذا المنتج" من تاريخ git.
  Future<void> _requestInspection() async {
    if (!await requireLogin(
      context,
      messageAr: 'محتاج تسجل دخول عشان تحجز معاينة في المحل',
      messageEn: 'You need to log in to book a store visit',
    )) return;
    if (!mounted) return;

    final product = _product;
    if (product == null) return;
    final isArabic = context.read<LocaleProvider>().isArabic;

    final booked = await showBookStoreVisitSheet(context, product);
    if (booked == null || !mounted) return;

    final locale = isArabic ? 'ar' : 'en';
    final visitTime = DateFormat('EEEE d MMM · h:mm a', locale).format(booked.at);

    final openVisits = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, size: 40, color: AppTheme.successColor),
        content: Text(
          isArabic
              ? 'تم إرسال طلب الميعاد: $visitTime.\nهنأكدلك قريب${booked.hold ? ' وهنحاول نحجزلك التليفون لمدة ${AppConstants.holdHours} ساعة' : ''}.'
              : 'Visit requested for $visitTime.\nWe\'ll confirm shortly${booked.hold ? " and try to hold the phone for you for ${AppConstants.holdHours} hours" : ''}.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(isArabic ? 'مواعيدي' : 'My visits')),
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(isArabic ? 'تمام' : 'OK')),
        ],
      ),
    );

    if (openVisits == true && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MyInspectionRequestsScreen()));
    }
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
    final overview = product.overview;

    // ───────── موبايل/تطبيق: صور بالسحب + التفاصيل + الـ Overview تحت + بار سفلي ─────────
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
                  if (overview != null) ...[
                    const SizedBox(height: 24),
                    _OverviewPanel(overview: overview, isArabic: isArabic),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // ───────── ويب/ديسكتوب: 3 أجزاء ─────────
    // [الصور] [بيانات التليفون: الاسم/السعر/المساحة/الأزرار/الوصف] [Overview]
    // لو العرض أقل من 1200 الـ Overview بينزل تحت الجزأين بعرض كامل.
    final threeColumns = overview != null && MediaQuery.sizeOf(context).width >= 1200;

    final desktopBody = RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      SizedBox(width: threeColumns ? 40 : 56),
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
                          ],
                        ),
                      ),
                      if (threeColumns) ...[
                        const SizedBox(width: 40),
                        Expanded(flex: 4, child: _OverviewPanel(overview: overview!, isArabic: isArabic)),
                      ],
                    ],
                  ),
                  if (overview != null && !threeColumns) ...[
                    const SizedBox(height: 32),
                    _OverviewPanel(overview: overview, isArabic: isArabic),
                  ],
                  const SizedBox(height: 40),
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
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (product.brand != null && product.brand!.isNotEmpty) _InfoChip(icon: Icons.branding_watermark, label: product.brand!),
            if (product.storage != null && product.storage!.isNotEmpty) _InfoChip(icon: Icons.sd_storage, label: product.storage!),
            if (product.ramGb != null) _InfoChip(icon: Icons.memory, label: '${product.ramGb} GB RAM'),
            if (product.color != null && product.color!.isNotEmpty) _InfoChip(icon: Icons.color_lens, label: product.color!),
          ],
        ),
        const SizedBox(height: 16),
        _GradeWarrantyBlock(
          gradeLetter: product.gradeLetter,
          gradeLabel: product.condition == null ? null : _conditionLabel(product.condition!, isArabic),
          warrantyLabel: product.warrantyMonths > 0 ? product.warrantyLabel(isArabic) : null,
          batteryHealth: product.batteryHealth,
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
            onPressed: sold ? null : _requestInspection,
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: Text(
              isArabic ? 'احجز معاينة في المحل' : 'Book a store visit',
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

/// الـ Overview: بيتعرض من اللي الأدمن كتبه للمنتج (عنوان + مقدمة + أقسام + أسئلة شائعة).
/// أي جزء فاضي بيتخطى من غير ما يسيب فراغ.
class _OverviewPanel extends StatelessWidget {
  final ProductOverview overview;
  final bool isArabic;
  const _OverviewPanel({required this.overview, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final o = overview;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isArabic ? 'نظرة عامة' : 'Overview', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          if (o.title.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(o.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
          if (o.intro.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(o.intro, style: const TextStyle(height: 1.55, color: AppTheme.deepGray)),
          ],
          for (final section in o.sections) ...[
            const SizedBox(height: 20),
            if (section.title.isNotEmpty)
              Text(section.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            if (section.title.isNotEmpty && section.body.isNotEmpty) const SizedBox(height: 6),
            if (section.body.isNotEmpty) Text(section.body, style: const TextStyle(height: 1.6)),
          ],
          if (o.faqs.isNotEmpty) ...[
            const SizedBox(height: 24),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 16),
            Text(
              o.faqTitle.isNotEmpty ? o.faqTitle : (isArabic ? 'الأسئلة الشائعة' : 'FAQs'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            for (var i = 0; i < o.faqs.length; i++) ...[
              const SizedBox(height: 14),
              if (o.faqs[i].question.isNotEmpty)
                Text('${i + 1}. ${o.faqs[i].question}', style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4)),
              if (o.faqs[i].answer.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(o.faqs[i].answer, style: const TextStyle(height: 1.6, color: AppTheme.deepGray)),
              ],
            ],
          ],
        ],
      ),
    );
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

    final isRtl = Directionality.of(context) == TextDirection.RTL;
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
  final int? batteryHealth;
  final bool isArabic;

  const _GradeWarrantyBlock({
    required this.gradeLetter,
    required this.gradeLabel,
    required this.warrantyLabel,
    this.batteryHealth,
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
      if (batteryHealth != null)
        _row(
          leading: const Icon(Icons.battery_charging_full_outlined, size: 26, color: AppTheme.gold),
          caption: isArabic ? 'صحة البطارية' : 'Battery health',
          value: '$batteryHealth%',
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