import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final _service = ProductService();

  List<Product> _products = [];
  List<ProductCategory> _categories = [];
  String? _selectedCategoryId;
  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;
  String? _condition;
  bool _isLoading = false;
  bool _hasError = false;

  Timer? _searchDebounce;
  int _requestId = 0; // رقم آخر طلب - عشان نتجاهل أي رد قديم وصل متأخر

  List<Product> get products => _products;
  List<ProductCategory> get categories => _categories;
  String? get selectedCategoryId => _selectedCategoryId;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  String? get condition => _condition;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  Future<void> loadCategories() async {
    _categories = await _service.getCategories();
    notifyListeners();
  }

  Future<void> loadProducts({String? statusFilter}) async {
    final requestId = ++_requestId;
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final result = await _service.getProducts(
        categoryId: _selectedCategoryId,
        searchQuery: _searchQuery,
        status: statusFilter,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        condition: _condition,
      );
      // لو فيه طلب أحدث اتبعت وإحنا مستنيين، رد الطلب ده قديم - نتجاهله
      if (requestId != _requestId) return;
      _products = result;
    } catch (e) {
      if (requestId != _requestId) return;
      _hasError = true;
    }
    _isLoading = false;
    notifyListeners();
  }

  void setPriceRange(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    loadProducts();
  }

  void setCondition(String? condition) {
    _condition = condition;
    loadProducts();
  }

  void setCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    loadProducts();
  }

  /// البحث بيتم في الداتابيز (Supabase) مش في التطبيق.
  /// بنستنى 350ms بعد آخر حرف قبل ما نبعت الطلب، عشان مانبعتش طلب لكل حرف.
  void search(String query) {
    final q = query.trim();
    if (q == _searchQuery) return;
    _searchQuery = q;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), loadProducts);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> deleteProduct(String id) async {
    await _service.deleteProduct(id);
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> updateStatus(String id, String status) async {
    await _service.updateProductStatus(id, status);
    await loadProducts();
  }
}