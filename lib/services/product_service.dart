import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../core/constants.dart';

class ProductService {
  final _client = Supabase.instance.client;
  final _uuid = const Uuid();

  // ---------- CATEGORIES ----------
  Future<List<ProductCategory>> getCategories() async {
    final data = await _client.from('categories').select().order('name_en');
    return (data as List).map((e) => ProductCategory.fromJson(e)).toList();
  }

  // ---------- PRODUCTS ----------
  Future<List<Product>> getProducts({
    String? categoryId,
    String? searchQuery,
    String? status,
    double? minPrice,
    double? maxPrice,
  }) async {
    var query = _client.from('products').select('*, product_images(*)');

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }
    if (minPrice != null) {
      query = query.gte('price', minPrice);
    }
    if (maxPrice != null) {
      query = query.lte('price', maxPrice);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or(
        'name_ar.ilike.%$searchQuery%,name_en.ilike.%$searchQuery%,brand.ilike.%$searchQuery%',
      );
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  /// المنتجات المباعة فقط (سجل المبيعات للأدمن)
  Future<List<Product>> getSoldProducts() async {
    final data = await _client
        .from('products')
        .select('*, product_images(*)')
        .eq('status', 'sold')
        .order('sold_at', ascending: false);
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  /// يزود عداد المشاهدات - بينادى عليه لما حد يفتح تفاصيل المنتج
  Future<void> incrementViews(String productId) async {
    await _client.rpc('increment_product_views', params: {'p_id': productId});
  }

  Future<Product> getProductById(String id) async {
    final data = await _client
        .from('products')
        .select('*, product_images(*)')
        .eq('id', id)
        .single();
    return Product.fromJson(data);
  }

  Future<String> createProduct(Product product) async {
    final data = await _client
        .from('products')
        .insert(product.toInsertJson())
        .select()
        .single();
    return data['id'] as String;
  }

  Future<void> updateProduct(String id, Product product) async {
    await _client.from('products').update(product.toInsertJson()).eq('id', id);
  }

  Future<void> updateProductStatus(String id, String status) async {
    await _client.from('products').update({'status': status}).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  // ---------- IMAGES ----------
  Future<String> uploadProductImage(String productId, XFile file) async {
    final fileExt = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    final fileName = '${_uuid.v4()}.$fileExt';
    final path = '$productId/$fileName';
    final bytes = await file.readAsBytes();

    await _client.storage.from(AppConstants.productImagesBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: file.mimeType ?? 'image/jpeg'),
        );
    final publicUrl = _client.storage.from(AppConstants.productImagesBucket).getPublicUrl(path);

    await _client.from('product_images').insert({
      'product_id': productId,
      'image_url': publicUrl,
    });

    return publicUrl;
  }

  Future<void> deleteProductImage(String imageId) async {
    await _client.from('product_images').delete().eq('id', imageId);
  }
}


