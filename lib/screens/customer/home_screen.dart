import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/product_card.dart';
import '../../core/theme.dart';
import 'product_details_screen.dart';
import 'my_chats_screen.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

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

    final pages = [
      _ProductsTab(isArabic: isArabic),
      const MyChatsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.storefront_outlined), selectedIcon: const Icon(Icons.storefront), label: isArabic ? 'الرئيسية' : 'Home'),
          NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), selectedIcon: const Icon(Icons.chat_bubble), label: isArabic ? 'محادثاتي' : 'Chats'),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: isArabic ? 'الإعدادات' : 'Settings'),
        ],
      ),
    );
  }
}

class _ProductsTab extends StatelessWidget {
  final bool isArabic;
  const _ProductsTab({required this.isArabic});

  void _openFilterSheet(BuildContext context) {
    final provider = context.read<ProductProvider>();
    final minController = TextEditingController(text: provider.minPrice?.toStringAsFixed(0) ?? '');
    final maxController = TextEditingController(text: provider.maxPrice?.toStringAsFixed(0) ?? '');

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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final min = double.tryParse(minController.text);
                final max = double.tryParse(maxController.text);
                context.read<ProductProvider>().setPriceRange(min, max);
                Navigator.pop(context);
              },
              child: Text(isArabic ? 'تطبيق' : 'Apply'),
            ),
            TextButton(
              onPressed: () {
                context.read<ProductProvider>().setPriceRange(null, null);
                Navigator.pop(context);
              },
              child: Text(isArabic ? 'مسح الفلتر' : 'Clear filter'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return SafeArea(
      child: Column(
        children: [
          // رأس الصفحة: زي "Discover Your New House" - موقع + جرس + أفتار
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                const CircleAvatar(radius: 18, backgroundColor: AppTheme.primaryColor, child: Icon(Icons.person, size: 18, color: Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Align(
              alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                isArabic ? 'اكتشف موبايلك الجديد' : 'Discover Your\nNew Phone',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => context.read<ProductProvider>().search(v),
                    decoration: InputDecoration(
                      hintText: isArabic ? 'ابحث عن موبايل...' : 'Search phones...',
                      prefixIcon: const Icon(Icons.search, size: 20),
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
                      color: (productProvider.minPrice != null || productProvider.maxPrice != null)
                          ? const Color(0xFFFFD54F)
                          : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _CategoryChip(
                  label: isArabic ? 'الكل' : 'All',
                  selected: productProvider.selectedCategoryId == null,
                  onTap: () => context.read<ProductProvider>().setCategory(null),
                ),
                const SizedBox(width: 8),
                ...productProvider.categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CategoryChip(
                        label: c.name(isArabic),
                        selected: productProvider.selectedCategoryId == c.id,
                        onTap: () => context.read<ProductProvider>().setCategory(c.id),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: productProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : productProvider.hasError
                    ? Center(
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
                      )
                    : productProvider.products.isEmpty
                        ? Center(child: Text(isArabic ? 'لا يوجد منتجات' : 'No products found'))
                        : RefreshIndicator(
                            onRefresh: () => context.read<ProductProvider>().loadProducts(),
                            child: GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.68,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
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
                          ),
          ),
        ],
      ),
    );
  }
}

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
    );
  }
}
