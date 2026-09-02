import 'package:flutter/material.dart';
import '../models/product.dart';

/// بيدير قائمة المنتجات المختارة للمقارنة (لحد 3 منتجات في نفس الوقت)
class CompareProvider extends ChangeNotifier {
  static const maxItems = 3;
  final List<Product> _items = [];

  List<Product> get items => List.unmodifiable(_items);
  bool get isFull => _items.length >= maxItems;
  bool get hasEnoughToCompare => _items.length >= 2;

  bool isSelected(String productId) => _items.any((p) => p.id == productId);

  /// بيرجع false لو مقدرش يضيف (وصل الحد الأقصى)
  bool toggle(Product product) {
    if (isSelected(product.id)) {
      _items.removeWhere((p) => p.id == product.id);
      notifyListeners();
      return true;
    }
    if (isFull) return false;
    _items.add(product);
    notifyListeners();
    return true;
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
