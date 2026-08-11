import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';
import '../../providers/locale_provider.dart';
import '../customer/product_details_screen.dart';

class SoldHistoryScreen extends StatefulWidget {
  const SoldHistoryScreen({super.key});

  @override
  State<SoldHistoryScreen> createState() => _SoldHistoryScreenState();
}

class _SoldHistoryScreenState extends State<SoldHistoryScreen> {
  final _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final products = await _productService.getSoldProducts();
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final totalSales = _products.fold<double>(0, (sum, p) => sum + p.price);

    return Scaffold(
      appBar: AppBar(title: Text(isArabic ? 'سجل المبيعات' : 'Sales History')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _products.isEmpty
                ? Center(child: Text(isArabic ? 'لسه معملتش أي عملية بيع' : 'No sales yet'))
                : ListView(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isArabic ? 'إجمالي المبيعات' : 'Total Sales', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                Text('${totalSales.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(isArabic ? 'عدد القطع' : 'Items Sold', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                Text('${_products.length}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ..._products.map((product) => Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: product.mainImage.isNotEmpty ? NetworkImage(product.mainImage) : null,
                                child: product.mainImage.isEmpty ? const Icon(Icons.phone_android) : null,
                              ),
                              title: Text(product.name(isArabic)),
                              subtitle: Text(product.soldAt != null ? DateFormat.yMMMd(isArabic ? 'ar' : 'en').format(product.soldAt!) : ''),
                              trailing: Text('${product.price.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: product.id))),
                            ),
                          )),
                      const SizedBox(height: 20),
                    ],
                  ),
      ),
    );
  }
}
