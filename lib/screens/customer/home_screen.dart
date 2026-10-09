import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/product_card.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../widgets/desktop_top_nav.dart';
import '../../widgets/search_with_suggestions.dart';
import '../../widgets/customer_nav_actions.dart';
import '../../widgets/profile_menu_button.dart';
import 'product_details_screen.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';
import 'sell_phone_screen.dart';
import 'search_results_screen.dart';
// ⚠️ "محادثاتي" و"الإعدادات" متخفيين مؤقتًا (تابات + شريط النافيجيشن) بطلب الفريق.
// لإرجاعهم: رجّع الاستيرادات دي وارجع الـ pages[]/navItems[]/ModernNavBar زي ما كانوا:
// import '../../widgets/modern_nav_bar.dart';
// import '../../widgets/guest_guard.dart';
// import 'my_chats_screen.dart';
// import 'settings_screen.dart';

// ───────────── إعداد: مكان أيقونات كروت "Why MERCHNT" ─────────────
// top = الأيقونة فوق العنوان | inline = الأيقونة جنب العنوان
enum WhyIconLayout { top, inline }

const WhyIconLayout kWhyIconLayout = WhyIconLayout.top;

// ألوان من ملف الـ HTML مش موجودة في AppTheme
const Color _midGray = Color(0xFF8C8A85);
const Color _deepGray = Color(0xFF4A4846);
const Color _border = Color(0xFFE5E3DF);

TextStyle _t(double size, {FontWeight w = FontWeight.w400, Color? c, double? h, double? ls}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c ?? AppTheme.charcoal, height: h, letterSpacing: ls);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      provider.loadCategories();
      provider.loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final isDesktop = Responsive.isDesktop(context);

    const trailing = CustomerNavActions();

    // شاشة ديسكتوب/ويب: نافيجيشن علوي (لوجو + أيقونات) - مفيش روابط تابات دلوقتي (تاب واحد بس)
    if (isDesktop) {
      return Scaffold(
        appBar: DesktopTopNav(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          items: const [], // ⚠️ لو رجعنا المحادثات/الإعدادات، رجع عناصر النافيجيشن هنا
          trailing: trailing,
        ),
        body: _ProductsTab(isArabic: isArabic),
      );
    }

    // شاشة موبايل: مفيش شريط سفلي دلوقتي بما إن التاب المتاح واحد بس
    return Scaffold(body: _ProductsTab(isArabic: isArabic));
  }
}

class _ProductsTab extends StatefulWidget {
  final bool isArabic;
  const _ProductsTab({required this.isArabic});

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  final GlobalKey _browseKey = GlobalKey();

  bool get isArabic => widget.isArabic;

  void _scrollToBrowse() {
    final ctx = _browseKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _openFilterSheet(BuildContext context) {
    final provider = context.read<ProductProvider>();
    final minController = TextEditingController(text: provider.minPrice?.toStringAsFixed(0) ?? '');
    final maxController = TextEditingController(text: provider.maxPrice?.toStringAsFixed(0) ?? '');
    String? selectedCondition = provider.condition;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isArabic ? 'فلترة بالسعر' : 'Filter by Price', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: isArabic ? 'من' : 'Min'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: isArabic ? 'إلى' : 'Max'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(isArabic ? 'الحالة (Grade)' : 'Grade', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setSheetState) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _GradeChip(
                      label: isArabic ? 'الكل' : 'All',
                      selected: selectedCondition == null,
                      onTap: () => setSheetState(() => selectedCondition = null),
                    ),
                    _GradeChip(
                      label: isArabic ? 'ممتازة (A)' : 'Excellent (A)',
                      selected: selectedCondition == 'excellent',
                      onTap: () => setSheetState(() => selectedCondition = 'excellent'),
                    ),
                    _GradeChip(
                      label: isArabic ? 'جيدة (B)' : 'Good (B)',
                      selected: selectedCondition == 'good',
                      onTap: () => setSheetState(() => selectedCondition = 'good'),
                    ),
                    _GradeChip(
                      label: isArabic ? 'مقبولة (C)' : 'Fair (C)',
                      selected: selectedCondition == 'fair',
                      onTap: () => setSheetState(() => selectedCondition = 'fair'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final min = double.tryParse(minController.text);
                final max = double.tryParse(maxController.text);
                context.read<ProductProvider>().setPriceRange(min, max);
                context.read<ProductProvider>().setCondition(selectedCondition);
                Navigator.pop(context);
              },
              child: Text(isArabic ? 'تطبيق' : 'Apply'),
            ),
            TextButton(
              onPressed: () {
                context.read<ProductProvider>().setPriceRange(null, null);
                context.read<ProductProvider>().setCondition(null);
                Navigator.pop(context);
              },
              child: Text(isArabic ? 'مسح الفلتر' : 'Clear filter'),
            ),
          ],
        ),
      ),
    );
  }

  /// السيرش + زرار الفلتر: فوق الصفحة (تحت الهيدر مباشرة).
  /// النتايج بتظهر في قسم "Browse phones".
  Widget _buildSearchBar(BuildContext context, ProductProvider productProvider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        border: const Border(bottom: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: _Constrained(
        child: Row(
          children: [
            Expanded(
              child: SearchWithSuggestions(
                isArabic: isArabic,
                hintText: isArabic ? 'ابحث عن موبايل...' : 'Search phones...',
                // اختيار اسم موديل (أو Enter) -> صفحة نتايج الاسم ده من الداتابيز
                onSelectName: (name) => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SearchResultsScreen(query: name)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => _openFilterSheet(context),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.tune,
                  color: (productProvider.minPrice != null || productProvider.maxPrice != null || productProvider.condition != null)
                      ? AppTheme.gold
                      : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// قسم "Browse phones": العنوان + فلاتر الأقسام (All + الأقسام من الداتابيز) + الجريد.
  /// فلاتر Grade A / Grade B اتشالت من صف الفلاتر.
  Widget _buildBrowseSection(BuildContext context, ProductProvider productProvider) {
    Widget gridOrState() {
      // أول تحميل بس: سبينر. بعد كده (بحث/فلتر) بنسيب النتايج القديمة ظاهرة لحد ما الجديدة توصل
      if (productProvider.isLoading && productProvider.products.isEmpty) {
        return const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()));
      }
      if (productProvider.hasError) {
        return SizedBox(
          height: 240,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40, color: Colors.grey),
                const SizedBox(height: 8),
                Text(isArabic ? 'حصل خطأ، حاول تاني' : 'Something went wrong'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.read<ProductProvider>().loadProducts(),
                  child: Text(isArabic ? 'حاول تاني' : 'Retry'),
                ),
              ],
            ),
          ),
        );
      }
      if (productProvider.products.isEmpty) {
        return SizedBox(
          height: 240,
          child: Center(child: Text(isArabic ? 'لا يوجد منتجات' : 'No products found')),
        );
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          final columns = Responsive.productGridColumns(constraints.maxWidth);
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: productProvider.isLoading ? 0.5 : 1,
            child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisExtent: ProductCard.gridExtent((constraints.maxWidth - 24 * (columns - 1)) / columns),
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
            ),
            itemCount: productProvider.products.length,
            itemBuilder: (context, i) {
              final product = productProvider.products[i];
              return ProductCard(
                product: product,
                isArabic: isArabic,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: product.id)),
                ),
              );
            },
            ),
          );
        },
      );
    }

    return _Section(
      key: _browseKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            runSpacing: 20,
            children: [
              Text('Browse phones', style: _t(26, w: FontWeight.w700)),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _CategoryChip(
                    label: isArabic ? 'الكل' : 'All',
                    selected: productProvider.selectedCategoryId == null,
                    onTap: () => context.read<ProductProvider>().setCategory(null),
                  ),
                  ...productProvider.categories.map((c) => _CategoryChip(
                        label: c.name(isArabic),
                        selected: productProvider.selectedCategoryId == c.id,
                        onTap: () => context.read<ProductProvider>().setCategory(c.id),
                      )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          gridOrState(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final isDesktop = Responsive.isDesktop(context);

    final page = RefreshIndicator(
      onRefresh: () => context.read<ProductProvider>().loadProducts(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // رأس الصفحة للموبايل (زي ما كان): موقع + جرس + مفضلة + أفتار
            // على الديسكتوب: الجرس/المفضلة/الأفتار في التوب نافيجيشن
            if (!isDesktop)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 15),
                          const SizedBox(width: 4),
                          Text(isArabic ? 'القاهرة' : 'Cairo', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF2F2F3)),
                        child: const Icon(Icons.notifications_none_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF2F2F3)),
                        child: const Icon(Icons.favorite_border, size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const CartNavButton(padding: 8, iconSize: 20, background: Color(0xFFF2F2F3), horizontalMargin: 0),
                    const SizedBox(width: 10),
                    const ProfileMenuButton(),
                  ],
                ),
              ),
            _buildSearchBar(context, productProvider),
            _Hero(
              onBrowse: _scrollToBrowse,
              onSell: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellPhoneScreen())),
            ),
            const _WhySection(),
            _buildBrowseSection(context, productProvider),
            const _GradingSection(),
            const _Footer(),
          ],
        ),
      ),
    );

    return SafeArea(child: page);
  }
}

// ───────────────────────── مساعدات التخطيط ─────────────────────────

bool _isWide(BuildContext c) => MediaQuery.of(c).size.width >= 900;
bool _isNarrow(BuildContext c) => MediaQuery.of(c).size.width < 520;

/// يحصر المحتوى في أقصى عرض (Responsive.maxContentWidth) ويوسّطه.
class _Constrained extends StatelessWidget {
  final Widget child;
  const _Constrained({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _isNarrow(context) ? 20 : 32),
          child: child,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final Color? color;
  final Widget child;
  const _Section({super.key, this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color ?? AppTheme.pureWhite,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 72),
      child: _Constrained(child: child),
    );
  }
}

class _SectionHead extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHead({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          children: [
            Text(title, textAlign: TextAlign.center, style: _t(30, w: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(subtitle, textAlign: TextAlign.center, style: _t(17, c: _deepGray, h: 1.6)),
          ],
        ),
      ),
    );
  }
}

/// جريد بعدد أعمدة متغير، وكل صف بنفس الارتفاع.
class _ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int Function(double width) columns;
  final double spacing;
  const _ResponsiveGrid({required this.children, required this.columns, this.spacing = 24});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final cols = columns(box.maxWidth);
      final rows = <Widget>[];
      for (var i = 0; i < children.length; i += cols) {
        final slice = children.skip(i).take(cols).toList();
        rows.add(IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < cols; j++) ...[
                if (j > 0) SizedBox(width: spacing),
                Expanded(child: j < slice.length ? slice[j] : const SizedBox()),
              ],
            ],
          ),
        ));
      }
      return Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            rows[i],
          ],
        ],
      );
    });
  }
}

// ───────────────────────── Hero ─────────────────────────

class _Hero extends StatelessWidget {
  final VoidCallback onBrowse;
  final VoidCallback onSell;
  const _Hero({required this.onBrowse, required this.onSell});

  @override
  Widget build(BuildContext context) {
    final wide = _isWide(context);

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: _t(wide ? 42 : 32, w: FontWeight.w800, h: 1.12, ls: -0.5),
            children: [
              const TextSpan(text: 'A premium phone, without the '),
              TextSpan(text: 'premium price.', style: TextStyle(color: AppTheme.gold)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(
            'Every phone on MERCHNT is graded, verified, and backed by a real warranty — so you buy with confidence, not hope.',
            style: _t(18, c: _deepGray, h: 1.6),
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: onBrowse,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.charcoal,
                foregroundColor: AppTheme.pureWhite,
                elevation: 0,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              child: const Text('Browse phones'),
            ),
            OutlinedButton(
              onPressed: onSell,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppTheme.pureWhite,
                foregroundColor: AppTheme.charcoal,
                side: BorderSide(color: AppTheme.charcoal, width: 2),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              child: const Text('Sell your phone'),
            ),
          ],
        ),
      ],
    );

    final visual = AspectRatio(
      aspectRatio: 4 / 3.1,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.charcoal,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: AppTheme.gold, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text('Verified & warrantied', style: _t(12, w: FontWeight.w700, c: AppTheme.pureWhite)),
                  ],
                ),
              ),
            ),
            const Center(child: _PhoneOutline(width: 108, height: 190)),
          ],
        ),
      ),
    );

    return Container(
      width: double.infinity,
      color: AppTheme.offWhite,
      padding: const EdgeInsets.fromLTRB(0, 72, 0, 80),
      child: _Constrained(
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 11, child: text),
                  const SizedBox(width: 60),
                  Expanded(flex: 9, child: visual),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [text, const SizedBox(height: 40), visual],
              ),
      ),
    );
  }
}

class _PhoneOutline extends StatelessWidget {
  final double width;
  final double height;
  const _PhoneOutline({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.lightGray, width: 4),
        borderRadius: BorderRadius.circular(width * 0.17),
      ),
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(top: height * 0.1),
      child: Container(width: width * 0.6, height: 3, color: AppTheme.lightGray),
    );
  }
}

// ───────────────────────── Why MERCHNT ─────────────────────────

class _WhyItem {
  final String title;
  final String body;

  /// حط الأيقونة هنا لما تجهز، مثلًا:
  ///   Image.asset('assets/icons/verified.png')
  ///   Icon(Icons.verified_outlined)
  /// لو null بيظهر مربع منقط كـ placeholder.
  final Widget? icon;
  const _WhyItem(this.title, this.body, {this.icon});
}

class _WhySection extends StatelessWidget {
  const _WhySection();

  @override
  Widget build(BuildContext context) {
    const items = [
      _WhyItem(
        'Verified, not guessed',
        'Every phone is inspected and graded against the same honest standard, so you know its real condition before you buy.',
      ),
      _WhyItem(
        'Real warranty, no exceptions',
        'Every device, regardless of grade, is backed by a real warranty — not a vague promise.',
      ),
      _WhyItem(
        'See us in person, buy online',
        "MERCHNT isn't an anonymous account — it's a business with real stores you can actually visit.",
      ),
      _WhyItem(
        'Fair prices, honestly set',
        'Flagship phones, without the flagship price — priced on real condition, not inflated guesswork.',
      ),
    ];

    return _Section(
      child: Column(
        children: [
          const _SectionHead(
            title: 'Why MERCHNT?',
            subtitle: "A premium phone shouldn't come with a leap of faith.",
          ),
          const SizedBox(height: 44),
          _ResponsiveGrid(
            columns: (w) => w >= 840 ? 4 : (w >= 480 ? 2 : 1),
            children: [for (final i in items) _WhyCard(item: i)],
          ),
        ],
      ),
    );
  }
}

class _WhyCard extends StatelessWidget {
  final _WhyItem item;
  const _WhyCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final inline = kWhyIconLayout == WhyIconLayout.inline;
    final title = Text(item.title, style: _t(17, w: FontWeight.w700, h: 1.3));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppTheme.offWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (inline)
            Row(
              children: [
                _IconSlot(icon: item.icon, size: 44),
                const SizedBox(width: 14),
                Expanded(child: title),
              ],
            )
          else ...[
            _IconSlot(icon: item.icon, size: 52),
            const SizedBox(height: 18),
            title,
          ],
          const SizedBox(height: 10),
          Text(item.body, style: _t(14.5, c: _deepGray, h: 1.55)),
        ],
      ),
    );
  }
}

class _IconSlot extends StatelessWidget {
  final Widget? icon;
  final double size;
  const _IconSlot({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _DashedRRectPainter(AppTheme.lightGray)),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      alignment: Alignment.center,
      child: IconTheme(
        data: IconThemeData(color: AppTheme.gold, size: 26),
        child: SizedBox(width: 26, height: 26, child: icon),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  _DashedRRectPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14));
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
        d += 8;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) => old.color != color;
}

// ───────────────────────── Our grading system ─────────────────────────

class _GradingSection extends StatelessWidget {
  const _GradingSection();

  @override
  Widget build(BuildContext context) {
    const grades = [
      ('A', 'Excellent', 'Looks and performs like new. No visible scratches, minimal signs of use, battery health 90%+.'),
      ('B', 'Good', "Light, honest wear. Minor scratches that won't show when the screen is on, battery health 85%+."),
      ('C', 'Fair', "Fully functional with visible signs of use that don't affect performance, battery health 80%+."),
    ];

    return _Section(
      color: AppTheme.offWhite,
      child: Column(
        children: [
          const _SectionHead(
            title: 'Our grading system',
            subtitle:
                "Every phone we sell is graded using the same honest standard — so you always know exactly what you're getting, before you buy.",
          ),
          const SizedBox(height: 44),
          _ResponsiveGrid(
            columns: (w) => w >= 700 ? 3 : 1,
            children: [
              for (final g in grades)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    children: [
                      _GradeBadge(grade: g.$1),
                      const SizedBox(height: 18),
                      Text(g.$2, style: _t(18, w: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Text(g.$3, textAlign: TextAlign.center, style: _t(14.5, c: _deepGray, h: 1.55)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 36),
          const _DisclaimerBox(),
        ],
      ),
    );
  }
}

/// دايرة الجريد الكبيرة (A / B / C) زي ما في الـ HTML.
class _GradeBadge extends StatelessWidget {
  final String grade;
  const _GradeBadge({required this.grade});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;
    switch (grade) {
      case 'A':
        bg = AppTheme.charcoal;
        fg = AppTheme.pureWhite;
        break;
      case 'B':
        bg = AppTheme.pureWhite;
        fg = AppTheme.charcoal;
        border = Border.all(color: AppTheme.charcoal, width: 2);
        break;
      default:
        bg = AppTheme.pureWhite;
        fg = _midGray;
        border = Border.all(color: _midGray, width: 2);
    }
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: border),
      child: Text(grade, style: _t(24, w: FontWeight.w800, c: fg)),
    );
  }
}

/// الصندوق الجديد (نفس الكلام): شريط داكن + أيقونة صح دهبية.
class _DisclaimerBox extends StatelessWidget {
  const _DisclaimerBox();

  @override
  Widget build(BuildContext context) {
    final narrow = _isNarrow(context);

    final icon = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.gold.withValues(alpha: 0.15),
        border: Border.all(color: AppTheme.gold, width: 1.5),
      ),
      child: Icon(Icons.check_rounded, color: AppTheme.gold, size: 24),
    );

    final text = Column(
      crossAxisAlignment: narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text('Function is never graded.',
            textAlign: narrow ? TextAlign.center : TextAlign.start,
            style: _t(16, w: FontWeight.w700, c: AppTheme.pureWhite)),
        const SizedBox(height: 2),
        Text(
          'Every phone — Excellent, Good, or Fair — passes the same full inspection and works exactly as it should.',
          textAlign: narrow ? TextAlign.center : TextAlign.start,
          style: _t(15, c: const Color(0xFFD6D3CD), h: 1.6),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: narrow ? 20 : 32, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.charcoal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: narrow
          ? Column(children: [icon, const SizedBox(height: 14), text])
          : Row(children: [icon, const SizedBox(width: 20), Expanded(child: text)]),
    );
  }
}

// ───────────────────────── Footer ─────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    const cols = {
      'SHOP': ['All phones', 'iPhone', 'Samsung'],
      'MERCHNT': ['Our grading system', 'Why MERCHNT', 'Sell your phone'],
      'SUPPORT': ['Contact us', 'Warranty', 'Delivery & returns'],
      'VISIT US': ['Store locations', 'Store hours'],
    };

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: _border))),
      padding: const EdgeInsets.fromLTRB(0, 48, 0, 32),
      child: _Constrained(
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 48,
              runSpacing: 32,
              children: [
                for (final e in cols.entries)
                  SizedBox(
                    width: 180,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.key, style: _t(13, w: FontWeight.w700, c: _midGray, ls: 0.5)),
                        const SizedBox(height: 14),
                        for (final l in e.value)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(l, style: _t(14.5, c: _deepGray)),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            const Divider(height: 1, color: _border),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 12,
              children: [
                Text('© 2026 MERCHNT. All rights reserved.', style: _t(13, c: _midGray)),
                Text('Trusted pre-owned phones — graded, verified, warrantied.', style: _t(13, c: _midGray)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── تشيبس الفلاتر ─────────────────────────

/// فلتر الأقسام (All / iPhone / Samsung ...): نفس ستايل أزرار الـ HTML (pill داكن لما يكون مختار)
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppTheme.charcoal,
      labelStyle: TextStyle(
        color: selected ? AppTheme.pureWhite : AppTheme.charcoal,
        fontWeight: FontWeight.w500,
        fontSize: 13.5,
      ),
      backgroundColor: AppTheme.pureWhite,
      side: BorderSide(color: selected ? AppTheme.charcoal : AppTheme.lightGray, width: 1.5),
      shape: const StadiumBorder(),
    );
  }
}

/// تشيب اختيار الـ Grade جوه بوتوم شيت الفلاتر (زي ما كان)
class _GradeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GradeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.charcoal,
      labelStyle: TextStyle(color: selected ? AppTheme.pureWhite : AppTheme.charcoal, fontWeight: FontWeight.w500),
      backgroundColor: AppTheme.offWhite,
      side: const BorderSide(color: AppTheme.lightGray),
      shape: const StadiumBorder(),
    );
  }
}