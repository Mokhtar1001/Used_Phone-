import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/favorites_service.dart';
import '../../models/product.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../widgets/product_list_card.dart';
import 'product_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _favoritesService = FavoritesService();
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final userId = context.read<AuthProvider>().profile?.id;
    if (userId == null) return;
    final products = await _favoritesService.getMyFavoriteProducts(userId);
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  Future<void> _removeFavorite(Product product) async {
    final userId = context.read<AuthProvider>().profile?.id;
    if (userId == null) return;
    setState(() => _products.removeWhere((p) => p.id == product.id));
    await _favoritesService.toggleFavorite(userId, product.id);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(isArabic ? 'المفضلة' : 'Favorites')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _products.isEmpty
                ? Center(child: Text(isArabic ? 'لسه معملتش أي منتج مفضل' : 'No favorites yet'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final product = _products[i];
                      return ProductListCard(
                        product: product,
                        isArabic: isArabic,
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: product.id)));
                          _load(); // ممكن يكون شال المنتج من المفضلة وهو جوه
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite, color: AppTheme.errorColor, size: 20),
                          onPressed: () => _removeFavorite(product),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
