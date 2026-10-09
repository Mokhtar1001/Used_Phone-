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

  /// بيجهّز كلمة البحث لفلتر ilike جوه or(...):
  /// 1) بيهرّب % و _ و \ عشان يتعاملوا كحروف عادية مش wildcards.
  /// 2) بيحط القيمة بين "" عشان الفاصلة والأقواس (اللي PostgREST بيعتبرها فواصل) ما يبوّظوش الفلتر.
  String _likePattern(String input) {
    final like = input.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
    final quoted = '%$like%'.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return '"$quoted"';
  }

  /// الأرقام العربية/الفارسية (١٣) -> إنجليزي (13)
  String _westernDigits(String s) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final b = StringBuffer();
    for (final ch in s.runes.map(String.fromCharCode)) {
      final a = arabic.indexOf(ch);
      final p = persian.indexOf(ch);
      b.write(a >= 0 ? '$a' : (p >= 0 ? '$p' : ch));
    }
    return b.toString();
  }

  /// فلتر البحث: الاسم العربي/الإنجليزي/الماركة، بالكلمة زي ما اتكتبت وبالأرقام الإنجليزي كمان
  String _orFilter(String q) {
    final variants = {q, _westernDigits(q)};
    const columns = ['name_ar', 'name_en', 'brand'];
    return [
      for (final v in variants)
        for (final c in columns) '$c.ilike.${_likePattern(v)}',
    ].join(',');
  }

  // ---------- PRODUCTS ----------
  Future<List<Product>> getProducts({
    String? categoryId,
    String? searchQuery,
    String? status,
    double? minPrice,
    double? maxPrice,
    String? condition,
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
    if (condition != null) {
      query = query.eq('condition', condition);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      query = query.or(_orFilter(searchQuery.trim()));
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  /// منتجات بالـ IDs (للسلة)
  Future<List<Product>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final data = await _client.from('products').select('*, product_images(*)').inFilter('id', ids);
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  /// اقتراحات أسماء الموديلات للسيرش (نص بس، من غير منتجات): أسماء مختلفة مطابقة للكلمة.
  Future<List<String>> searchModelNames(String text, {required bool isArabic, int limit = 8}) async {
    final q = text.trim();
    if (q.isEmpty) return [];
    final data = await _client
        .from('products')
        .select('name_en, name_ar')
        .or(_orFilter(q))
        .order('created_at', ascending: false)
        .limit(60);

    final seen = <String>{};
    final names = <String>[];
    for (final row in data as List) {
      final name = ((isArabic ? row['name_ar'] : row['name_en']) as String?)?.trim() ?? '';
      if (name.isEmpty) continue;
      if (seen.add(name.toLowerCase())) names.add(name);
      if (names.length >= limit) break;
    }
    return names;
  }

  /// اقتراحات البحث (القايمة اللي بتنزل تحت السيرش): أحدث N منتج مطابق، من الداتابيز مباشرة.
  Future<List<Product>> searchSuggestions(String text, {int limit = 6}) async {
    final q = text.trim();
    if (q.isEmpty) return [];
    final data = await _client
        .from('products')
        .select('*, product_images(*)')
        .or(_orFilter(q))
        .order('created_at', ascending: false)
        .limit(limit);
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