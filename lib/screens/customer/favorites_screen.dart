import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/favorites_service.dart';
import '../../models/product.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/product_card.dart';
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
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, i) {
                      final product = _products[i];
                      return ProductCard(
                        product: product,
                        isArabic: isArabic,
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: product.id)));
                          _load(); // ممكن يكون شال المنتج من المفضلة وهو جوه
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
