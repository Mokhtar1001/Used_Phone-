import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import '../../widgets/customer_nav_actions.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import '../../services/product_service.dart';
import '../../services/favorites_service.dart';
import '../../models/product.dart';
import '../../models/product_overview.dart';
import '../../models/condition_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/guest_guard.dart';
import '../../widgets/product_card.dart';
import '../../widgets/site_footer.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../core/constants.dart';
import 'book_store_visit_sheet.dart';
import 'cart_screen.dart';
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
  List<Product> _related = [];
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
      _loadRelated(product);
    } catch (e) {
      setState(() => _hasError = true);
    }
  }

  /// "You might also like": تليفونات متاحة مشابهة من الداتابيز.
  /// الترتيب: نفس الماركة الأول، وبعدين الأقرب في السعر. لو القسم فيه أقل من 4، بنكمّل من باقي المنتجات.
  Future<void> _loadRelated(Product product) async {
    try {
      var pool = (await _productService.getProducts(categoryId: product.categoryId, status: 'available'))
          .where((p) => p.id != product.id)
          .toList();

      if (pool.length < 4 && product.categoryId != null) {
        final all = await _productService.getProducts(status: 'available');
        final seen = pool.map((p) => p.id).toSet();
        pool = [...pool, ...all.where((p) => p.id != product.id && !seen.contains(p.id))];
      }

      final brand = product.brand?.toLowerCase();
      int brandRank(Product p) => (brand != null && p.brand?.toLowerCase() == brand) ? 0 : 1;
      pool.sort((a, b) {
        final byBrand = brandRank(a).compareTo(brandRank(b));
        if (byBrand != 0) return byBrand;
        return (a.price - product.price).abs().compareTo((b.price - product.price).abs());
      });

      if (mounted) setState(() => _related = pool.take(4).toList());
    } catch (_) {
      // قسم اختياري: لو فشل مبنوقفش الصفحة
    }
  }

  void _addToCart(Product product, bool isArabic) {
    context.read<CartProvider>().add(product);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'تمت الإضافة للسلة' : 'Added to cart'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(label: isArabic ? 'عرض السلة' : 'View cart', onPressed: _openCart),
        ),
      );
  }

  void _openCart() => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));

  /// زرار الشراء الرئيسي: "Add to cart" وبعد الإضافة بيتحول لـ "Checkout" (بيفتح السلة وفيها إتمام الطلب).
  /// مفيش زرار "Buy now" خلاص.
  Widget _cartButton(Product product, bool isArabic, {ButtonStyle? style}) {
    final unavailable = product.status == 'sold' || product.status == 'reserved';
    final inCart = context.watch<CartProvider>().contains(product.id);
    final label = product.status == 'sold'
        ? (isArabic ? 'تم البيع' : 'Sold')
        : product.status == 'reserved'
            ? (isArabic ? 'محجوز' : 'Reserved')
            : inCart
                ? (isArabic ? 'إتمام الطلب' : 'Checkout')
                : (isArabic ? 'أضف للسلة' : 'Add to cart');

    return ElevatedButton.icon(
      onPressed: unavailable ? null : (inCart ? _openCart : () => _addToCart(product, isArabic)),
      style: style,
      icon: Icon(inCart ? Icons.shopping_bag_outlined : Icons.shopping_cart_outlined, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
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
        appBar: _appBar(isArabic),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final product = _product!;
    final isDesktop = Responsive.isDesktop(context);
    final overview = product.overview;
    // 3 أجزاء (صور | بيانات | Overview) لو العرض 1200+، وإلا الـ Overview بينزل تحت بعرض كامل
    final threeColumns = isDesktop && overview != null && MediaQuery.sizeOf(context).width >= 1200;

    final Widget top = isDesktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: _Gallery(images: product.images, aspectRatio: 1, showArrows: true)),
              SizedBox(width: threeColumns ? 40 : 56),
              Expanded(flex: 5, child: _buildInfo(product, isArabic, desktop: true)),
              if (threeColumns) ...[
                const SizedBox(width: 40),
                Expanded(flex: 4, child: _OverviewPanel(overview: overview!, isArabic: isArabic)),
              ],
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Gallery(images: product.images, aspectRatio: 1.1, showArrows: false),
              const SizedBox(height: 20),
              _buildInfo(product, isArabic, desktop: false),
            ],
          );

    final body = RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isDesktop) _Breadcrumb(name: product.name(isArabic), isArabic: isArabic),
                      SizedBox(height: isDesktop ? 36 : 16),
                      top,
                      if (overview != null && !threeColumns) ...[
                        const SizedBox(height: 32),
                        _OverviewPanel(overview: overview, isArabic: isArabic),
                      ],
                      SizedBox(height: isDesktop ? 64 : 32),
                      ..._buildSections(product, isArabic, compact: !isDesktop),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SiteFooter(),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: _appBar(isArabic),
      body: body,
      // على الديسكتوب الأزرار جوه العمود الأيمن، فمفيش بار سفلي
      bottomNavigationBar: isDesktop
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildMobileActions(product, isArabic),
              ),
            ),
    );
  }

  /// ديسكتوب/ويب: الهيدر العلوي بس. موبايل/تطبيق: شريط عادي بزرار الرجوع والعنوان.
  PreferredSizeWidget _appBar(bool isArabic) {
    if (Responsive.isDesktop(context)) return customerTopNav();
    return AppBar(title: Text(isArabic ? 'تفاصيل المنتج' : 'Product Details'));
  }

  // ───────────────────────── عمود البيانات ─────────────────────────

  Widget _buildInfo(Product product, bool isArabic, {required bool desktop}) {
    final sold = product.status == 'sold';
    final letter = product.gradeLetter;
    final price = NumberFormat('#,###').format(product.price);
    final hasOriginal = product.originalPrice != null && product.originalPrice! > product.price;

    final specs = [
      if (product.color != null && product.color!.isNotEmpty) product.color!,
      if (product.ramGb != null) '${product.ramGb}GB RAM',
      if (product.batteryHealth != null) '${isArabic ? 'صحة البطارية' : 'Battery Health'} ${product.batteryHealth}%',
    ];

    final title = _displayTitle(product, isArabic);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (letter != null) ...[
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.charcoal,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.gold, width: 2),
                ),
                child: Text(letter, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.pureWhite)),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_gradeHeadline(letter, isArabic), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(_gradeSub(letter, isArabic), style: const TextStyle(fontSize: 13, color: AppTheme.midGray)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.25))),
            // على الموبايل القلب جنب الاسم (على الديسكتوب فيه زرار Add to wishlist)
            if (!desktop)
              IconButton(
                tooltip: isArabic ? 'المفضلة' : 'Favorite',
                onPressed: _toggleFavorite,
                icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : AppTheme.charcoal),
              ),
          ],
        ),
        if (specs.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(specs.join(' · '), style: const TextStyle(fontSize: 15, color: AppTheme.midGray)),
        ],
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              isArabic ? '$price ج.م' : 'EGP $price',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            ),
            if (hasOriginal) ...[
              const SizedBox(width: 14),
              Text(
                isArabic ? '${NumberFormat('#,###').format(product.originalPrice!)} ج.م' : 'EGP ${NumberFormat('#,###').format(product.originalPrice!)}',
                style: const TextStyle(fontSize: 17, color: AppTheme.midGray, decoration: TextDecoration.lineThrough),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        _StockLine(status: product.status, isArabic: isArabic),
        const SizedBox(height: 28),
        if (desktop) ...[
          _buildDesktopActions(product, isArabic, sold),
          const SizedBox(height: 32),
        ],
        _TrustRow(warrantyMonths: product.warrantyMonths, warrantyLabel: product.warrantyLabel(isArabic), isArabic: isArabic),
        if (product.description(isArabic).trim().isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(isArabic ? 'الوصف' : 'Description', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Text(product.description(isArabic), style: const TextStyle(height: 1.55, color: AppTheme.deepGray)),
        ],
      ],
    );
  }

  /// الاسم + المساحة لو مش مكتوبة في الاسم (زي "iPhone 13 Pro — 128GB")
  String _displayTitle(Product product, bool isArabic) {
    final name = product.name(isArabic);
    final storage = product.storage;
    if (storage == null || storage.isEmpty || name.toLowerCase().contains(storage.toLowerCase())) return name;
    return '$name — $storage';
  }

  ButtonStyle get _primaryPill => ElevatedButton.styleFrom(
        backgroundColor: AppTheme.charcoal,
        foregroundColor: AppTheme.pureWhite,
        elevation: 0,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      );

  ButtonStyle get _secondaryPill => OutlinedButton.styleFrom(
        backgroundColor: AppTheme.pureWhite,
        foregroundColor: AppTheme.charcoal,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        side: const BorderSide(color: AppTheme.charcoal, width: 2),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      );

  /// ديسكتوب: Add to cart / Checkout + Add to wishlist، وتحتهم Book a store visit
  Widget _buildDesktopActions(Product product, bool isArabic, bool sold) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _cartButton(product, isArabic, style: _primaryPill)),
            const SizedBox(width: 14),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _toggleFavorite,
                style: _secondaryPill,
                icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, size: 18, color: _isFavorite ? Colors.red : AppTheme.charcoal),
                label: Text(
                  _isFavorite ? (isArabic ? 'في المفضلة' : 'In wishlist') : (isArabic ? 'أضف للمفضلة' : 'Add to wishlist'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: sold ? null : _requestInspection,
          style: _secondaryPill,
          icon: const Icon(Icons.storefront_outlined, size: 18),
          label: Text(isArabic ? 'احجز معاينة في المحل' : 'Book a store visit'),
        ),
      ],
    );
  }

  /// موبايل: البار السفلي (شراء + معاينة في المحل)
  Widget _buildMobileActions(Product product, bool isArabic) {
    final sold = product.status == 'sold';
    return Row(
      children: [
        Expanded(child: _cartButton(product, isArabic)),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: sold ? null : _requestInspection,
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: Text(isArabic ? 'احجز معاينة' : 'Book a visit', maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── الأقسام اللي تحت ─────────────────────────

  List<Widget> _buildSections(Product product, bool isArabic, {required bool compact}) {
    // تفاصيل الحالة اللي الأدمن كتبها + صحة البطارية أوتوماتيك لو مش مكتوبة
    final items = [...product.conditionBreakdown];
    final hasBattery = items.any((e) => e.label.toLowerCase().contains('batter') || e.label.contains('بطار'));
    if (product.batteryHealth != null && !hasBattery) {
      items.add(ConditionItem(
        label: isArabic ? 'البطارية' : 'Battery',
        value: isArabic ? '${product.batteryHealth}% صحة' : '${product.batteryHealth}% Health',
      ));
    }

    final details = _detailRows(product, isArabic);

    return [
      if (items.isNotEmpty)
        _Section(
          title: isArabic ? 'تفاصيل الحالة' : 'Condition breakdown',
          compact: compact,
          child: _Grid(
            minItemWidth: 150,
            maxCols: 4,
            gap: 20,
            children: [for (final i in items) _ConditionCard(item: i)],
          ),
        ),
      _Section(
        title: isArabic ? 'نظام التقييم عندنا' : 'Our grading system',
        compact: compact,
        child: _Grid(
          minItemWidth: 180,
          maxCols: 3,
          gap: 20,
          children: [
            for (final l in const ['A', 'B', 'C'])
              _GradeCard(letter: l, isCurrent: product.gradeLetter == l, isArabic: isArabic),
          ],
        ),
      ),
      if (details.isNotEmpty)
        _Section(
          title: isArabic ? 'تفاصيل المنتج' : 'Product details',
          compact: compact,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(children: [for (final r in details) _DetailRow(label: r.$1, value: r.$2)]),
          ),
        ),
      if (_related.isNotEmpty)
        _Section(
          title: isArabic ? 'ممكن يعجبك كمان' : 'You might also like',
          compact: compact,
          child: _Grid(
            minItemWidth: compact ? 150 : 200,
            maxCols: 4,
            gap: compact ? 12 : 24,
            itemHeight: (w) => ProductCard.gridExtent(w),
            children: [
              for (final p in _related)
                ProductCard(
                  product: p,
                  isArabic: isArabic,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: p.id))),
                ),
            ],
          ),
        ),
    ];
  }

  List<(String, String)> _detailRows(Product product, bool isArabic) {
    return [
      if (product.brand != null && product.brand!.isNotEmpty) (isArabic ? 'الماركة' : 'Brand', product.brand!),
      if (product.storage != null && product.storage!.isNotEmpty) (isArabic ? 'المساحة' : 'Storage', product.storage!),
      if (product.ramGb != null) ('RAM', '${product.ramGb}GB'),
      if (product.color != null && product.color!.isNotEmpty) (isArabic ? 'اللون' : 'Color', product.color!),
      if (product.batteryHealth != null) (isArabic ? 'صحة البطارية' : 'Battery health', '${product.batteryHealth}%'),
      if (product.gradeLetter != null) (isArabic ? 'الحالة' : 'Grade', _gradeHeadline(product.gradeLetter!, isArabic)),
      if (product.warrantyMonths > 0)
        (
          isArabic ? 'الضمان' : 'Warranty',
          isArabic ? '${product.warrantyLabel(true)}، مضمون من Merchnt' : '${product.warrantyLabel(false)}, Merchnt-backed',
        ),
    ];
  }
}

// ───────────────────────── نصوص الجريد ─────────────────────────

String _gradeName(String letter, bool ar) {
  switch (letter) {
    case 'A':
      return ar ? 'ممتازة' : 'Excellent';
    case 'B':
      return ar ? 'جيدة' : 'Good';
    default:
      return ar ? 'مقبولة' : 'Fair';
  }
}

String _gradeHeadline(String letter, bool ar) => ar ? 'حالة ${_gradeName(letter, true)}' : '${_gradeName(letter, false)} condition';

String _gradeSub(String letter, bool ar) {
  switch (letter) {
    case 'A':
      return ar ? 'شكله وأداؤه زي الجديد' : 'Looks and performs like new';
    case 'B':
      return ar ? 'استعمال خفيف وواضح بأمانة' : 'Light, honest wear';
    default:
      return ar ? 'شغال بالكامل وعليه علامات استخدام' : 'Fully functional, visible signs of use';
  }
}

String _gradeBlurb(String letter, bool ar) {
  switch (letter) {
    case 'A':
      return ar
          ? 'شكله وأداؤه زي الجديد. من غير خدوش ظاهرة، علامات استخدام قليلة جدًا، وصحة بطارية 90%+.'
          : 'Looks and performs like new. No visible scratches, minimal signs of use, battery health 90%+.';
    case 'B':
      return ar
          ? 'استعمال خفيف وواضح بأمانة. خدوش بسيطة مش بتبان والشاشة شغالة، وصحة بطارية 85%+.'
          : "Light, honest wear. Minor scratches that won't show when the screen is on, battery health 85%+.";
    default:
      return ar
          ? 'شغال بالكامل وعليه علامات استخدام ظاهرة مبتأثرش على الأداء، وصحة بطارية 80%+.'
          : "Fully functional with visible signs of use that don't affect performance, battery health 80%+.";
  }
}

// ───────────────────────── مكونات الصفحة ─────────────────────────

class _Breadcrumb extends StatelessWidget {
  final String name;
  final bool isArabic;
  const _Breadcrumb({required this.name, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    Widget link(String text) => MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: Text(text, style: const TextStyle(fontSize: 13.5, color: AppTheme.midGray)),
          ),
        );
    const sep = Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('/', style: TextStyle(fontSize: 13.5, color: AppTheme.midGray)));

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          link(isArabic ? 'الرئيسية' : 'Home'),
          sep,
          link(isArabic ? 'المتجر' : 'Shop'),
          sep,
          Text(name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StockLine extends StatelessWidget {
  final String status;
  final bool isArabic;
  const _StockLine({required this.status, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String text;
    switch (status) {
      case 'sold':
        color = AppTheme.errorColor;
        text = isArabic ? 'تم البيع' : 'Sold';
        break;
      case 'reserved':
        color = AppTheme.warningColor;
        text = isArabic ? 'محجوز' : 'Reserved';
        break;
      default:
        color = AppTheme.successColor;
        text = isArabic ? 'متوفر — جاهز للشحن' : 'In stock — ready to ship';
    }
    return Row(
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: color))),
      ],
    );
  }
}

class _TrustRow extends StatelessWidget {
  final int warrantyMonths;
  final String warrantyLabel;
  final bool isArabic;
  const _TrustRow({required this.warrantyMonths, required this.warrantyLabel, required this.isArabic});

  Widget _item(IconData icon, String t1, String t2) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.charcoal),
          child: Icon(icon, size: 18, color: AppTheme.gold),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t1, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
              Text(t2, style: const TextStyle(fontSize: 12, color: AppTheme.midGray)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.offWhite, borderRadius: BorderRadius.circular(16)),
      child: Wrap(
        spacing: 28,
        runSpacing: 16,
        children: [
          if (warrantyMonths > 0)
            _item(
              Icons.verified_user_outlined,
              isArabic ? 'ضمان $warrantyLabel' : '${warrantyLabel[0].toUpperCase()}${warrantyLabel.substring(1)} warranty',
              isArabic ? 'على كل جهاز' : 'On every device',
            ),
          _item(
            Icons.task_alt,
            isArabic ? 'متفحوص بالكامل' : 'Fully Verified',
            isArabic ? 'بيتفحص قبل ما يتعرض' : 'Inspected before listing',
          ),
        ],
      ),
    );
  }
}

/// قسم بعنوان وخط فاصل فوقه (.section في الـ HTML)
class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final bool compact;
  const _Section({required this.title, required this.child, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: compact ? 36 : 48),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.lightGray))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

/// جريد متجاوب: عدد الأعمدة بيتحدد من العرض المتاح (زي flex-wrap في الـ HTML)
class _Grid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final int maxCols;
  final double gap;

  /// ارتفاع كل عنصر بدلالة عرضه. لازم للكروت اللي جواها Expanded (زي ProductCard) لأن الـ Wrap مبيدّيهاش ارتفاع.
  final double Function(double itemWidth)? itemHeight;
  const _Grid({required this.children, required this.minItemWidth, required this.maxCols, required this.gap, this.itemHeight});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = ((width + gap) / (minItemWidth + gap)).floor().clamp(1, maxCols);
        final itemWidth = (width - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final c in children) SizedBox(width: itemWidth, height: itemHeight?.call(itemWidth), child: c),
          ],
        );
      },
    );
  }
}

class _ConditionCard extends StatelessWidget {
  final ConditionItem item;
  const _ConditionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.offWhite, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.gold, letterSpacing: 0.4),
          ),
          const SizedBox(height: 8),
          Text(item.value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  final String letter;
  final bool isCurrent;
  final bool isArabic;
  const _GradeCard({required this.letter, required this.isCurrent, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
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

    return Padding(
      padding: const EdgeInsets.only(top: 11),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isCurrent ? const Color(0xFFFFF8E7) : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isCurrent ? AppTheme.charcoal : AppTheme.lightGray, width: isCurrent ? 2 : 1.5),
            ),
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: border),
                  child: Text(letter, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: fg)),
                ),
                const SizedBox(height: 12),
                Text(_gradeName(letter, isArabic), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  _gradeBlurb(letter, isArabic),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, height: 1.5, color: AppTheme.deepGray),
                ),
              ],
            ),
          ),
          if (isCurrent)
            Positioned(
              top: -11,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(color: AppTheme.charcoal, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    isArabic ? 'هذا الجهاز' : 'This phone',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.pureWhite),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.lightGray))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14.5, color: AppTheme.midGray)),
          const SizedBox(width: 16),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600))),
        ],
      ),
    );
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

/// معرض الصور: صورة رئيسية مربعة + صور مصغّرة تحتها (زي .main-image و .thumb-row في الـ HTML).
/// سحب (موبايل/ماوس) + أسهم على الويب.
class _Gallery extends StatefulWidget {
  final List<String> images;
  final double aspectRatio;
  final bool showArrows;
  const _Gallery({required this.images, required this.aspectRatio, required this.showArrows});

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
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
    final frameDecoration = BoxDecoration(
      color: AppTheme.offWhite,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.lightGray),
    );

    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Container(
          decoration: frameDecoration,
          child: const Center(child: Icon(Icons.phone_android, size: 80, color: AppTheme.lightGray)),
        ),
      );
    }

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final showControls = widget.showArrows && images.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: Container(
            decoration: frameDecoration,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  Positioned.fill(
                    // يسمح بالسحب بالماوس على الويب كمان
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: images.length,
                        onPageChanged: (i) => setState(() => _index = i),
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.all(20),
                          child: CachedNetworkImage(imageUrl: images[i], fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                  if (showControls && _index > 0)
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
                  if (showControls && _index < images.length - 1)
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
                ],
              ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              final size = (constraints.maxWidth - gap * 3) / 4;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var i = 0; i < images.length; i++)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _go(i),
                        child: Container(
                          width: size,
                          height: size,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.offWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: i == _index ? AppTheme.charcoal : AppTheme.lightGray, width: i == _index ? 2 : 1.5),
                          ),
                          child: CachedNetworkImage(imageUrl: images[i], fit: BoxFit.contain),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
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
