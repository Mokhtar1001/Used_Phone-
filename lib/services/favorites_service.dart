import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class FavoritesService {
  final _client = Supabase.instance.client;

  Future<Set<String>> getMyFavoriteIds(String userId) async {
    final data = await _client.from('favorites').select('product_id').eq('user_id', userId);
    return (data as List).map((e) => e['product_id'] as String).toSet();
  }

  Future<List<Product>> getMyFavoriteProducts(String userId) async {
    final data = await _client
        .from('favorites')
        .select('products(*, product_images(*))')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List)
        .where((e) => e['products'] != null)
        .map((e) => Product.fromJson(e['products']))
        .toList();
  }

  Future<bool> toggleFavorite(String userId, String productId) async {
    final existing = await _client
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing != null) {
      await _client.from('favorites').delete().eq('id', existing['id']);
      return false; // بقى مش مفضل
    } else {
      await _client.from('favorites').insert({'user_id': userId, 'product_id': productId});
      return true; // بقى مفضل
    }
  }
}
