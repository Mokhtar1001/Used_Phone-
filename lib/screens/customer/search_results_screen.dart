import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../providers/locale_provider.dart';
import '../../services/product_service.dart';
import '../../widgets/customer_nav_actions.dart';
import '../../widgets/desktop_top_nav.dart';
import '../../widgets/product_card.dart';
import '../../widgets/search_with_suggestions.dart';
import 'product_details_screen.dart';

/// صفحة نتايج البحث: كل المنتجات اللي ليها نفس اسم الموديل اللي العميل اختاره.
/// البحث بيتم في الداتابيز (مش فلترة في التطبيق).
class SearchResultsScreen extends StatefulWidget {
  final String query;
  const SearchResultsScreen({super.key, required this.query});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final _service = ProductService();
  List<Product> _products = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final result = await _service.getProducts(searchQuery: widget.query);
      if (mounted) setState(() => _products = result);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final isDesktop = Responsive.isDesktop(context);
    String t(String ar, String en) => isArabic ? ar : en;

    final PreferredSizeWidget appBar = isDesktop
        ? DesktopTopNav(selectedIndex: 0, onDestinationSelected: (_) {}, items: const [], trailing: const CustomerNavActions())
        : AppBar(title: Text(t('نتايج البحث', 'Search results')));

    return Scaffold(
      appBar: appBar,
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(MediaQuery.sizeOf(context).width < 520 ? 20 : 32, 24, MediaQuery.sizeOf(context).width < 520 ? 20 : 32, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // بحث جديد من نفس الصفحة
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: SearchWithSuggestions(
                        isArabic: isArabic,
                        hintText: t('ابحث عن موبايل...', 'Search phones...'),
                        onSelectName: (name) => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => SearchResultsScreen(query: name)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text('${t('نتايج', 'Results for')} "${widget.query}"',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                    if (!_loading && !_error) ...[
                      const SizedBox(height: 4),
                      Text(
                        t('${_products.length} موبايل', '${_products.length} ${_products.length == 1 ? 'phone' : 'phones'}'),
                        style: const TextStyle(color: AppTheme.midGray),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _content(isArabic, t),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(bool isArabic, String Function(String, String) t) {
    if (_loading) {
      return const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()));
    }
    if (_error) {
      return SizedBox(
        height: 240,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.grey),
              const SizedBox(height: 8),
              Text(t('حصل خطأ، حاول تاني', 'Something went wrong')),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: Text(t('حاول تاني', 'Retry'))),
            ],
          ),
        ),
      );
    }
    if (_products.isEmpty) {
      return SizedBox(
        height: 240,
        child: Center(child: Text(t('مفيش موبايلات مطابقة', 'No phones found'))),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final columns = Responsive.productGridColumns(constraints.maxWidth);
      const spacing = 24.0;
      final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisExtent: ProductCard.gridExtent(cardWidth),
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
        ),
        itemCount: _products.length,
        itemBuilder: (context, i) {
          final product = _products[i];
          return ProductCard(
            product: product,
            isArabic: isArabic,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: product.id)),
            ),
          );
        },
      );
    });
  }
}
