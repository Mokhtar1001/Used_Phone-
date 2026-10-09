import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/product_service.dart';

/// سلة المشتريات. كل موبايل مستعمل قطعة واحدة (مفيش كمية)، فالسلة مجرد قايمة منتجات.
/// بتتحفظ (IDs بس) على الجهاز، وبتتحدّث من الداتابيز عند الفتح عشان نشيل أي منتج اتباع.
class CartProvider extends ChangeNotifier {
  static const _prefsKey = 'cart_product_ids';

  final ProductService _service = ProductService();
  final List<Product> _items = [];

  CartProvider() {
    _restore();
  }

  List<Product> get items => List.unmodifiable(_items);
  int get count => _items.length;
  double get total => _items.fold(0.0, (sum, p) => sum + p.price);

  bool contains(String productId) => _items.any((p) => p.id == productId);

  Future<void> add(Product product) async {
    if (contains(product.id)) return;
    _items.add(product);
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String productId) async {
    _items.removeWhere((p) => p.id == productId);
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _items.map((p) => p.id).toList());
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_prefsKey) ?? [];
      if (ids.isEmpty) return;

      final products = await _service.getProductsByIds(ids);
      final byId = {for (final p in products) p.id: p};

      // نرجّع نفس ترتيب الإضافة، ونشيل المنتجات اللي اتباعت أو اتمسحت
      for (final id in ids) {
        final p = byId[id];
        if (p != null && p.status != 'sold') _items.add(p);
      }
      notifyListeners();
      if (_items.length != ids.length) await _persist();
    } catch (_) {
      // لو الاتصال فشل، السلة بتبدأ فاضية ومبنخسرش حاجة (الـ IDs لسه محفوظة)
    }
  }
}
