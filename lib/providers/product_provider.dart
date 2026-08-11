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
  bool _isLoading = false;
  bool _hasError = false;

  List<Product> get products => _products;
  List<ProductCategory> get categories => _categories;
  String? get selectedCategoryId => _selectedCategoryId;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  Future<void> loadCategories() async {
    _categories = await _service.getCategories();
    notifyListeners();
  }

  Future<void> loadProducts({String? statusFilter}) async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      _products = await _service.getProducts(
        categoryId: _selectedCategoryId,
        searchQuery: _searchQuery,
        status: statusFilter,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );
    } catch (e) {
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setPriceRange(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    loadProducts();
  }

  void setCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    loadProducts();
  }

  void search(String query) {
    _searchQuery = query;
    loadProducts();
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
