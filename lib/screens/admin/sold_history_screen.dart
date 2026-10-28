import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/product_service.dart';
import '../../services/sales_export_service.dart';
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
  bool _exporting = false;

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

  /// تصدير المبيعات لملف Excel (تنزيل على الويب، مشاركة على الموبايل، حفظ في Downloads على الديسكتوب)
  Future<void> _export(bool isArabic) async {
    setState(() => _exporting = true);
    try {
      final path = await SalesExportService.exportToExcel(_products, isArabic: isArabic);
      if (!mounted) return;
      final message = path != null
          ? (isArabic ? 'اتحفظ الملف في: $path' : 'Saved to: $path')
          : (kIsWeb ? (isArabic ? 'تم تنزيل ملف Excel' : 'Excel file downloaded') : null);
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'فشل التصدير: $e' : 'Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
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
                        child: Column(
                          children: [
                        Row(
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
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _exporting ? null : () => _export(isArabic),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white54),
                                ),
                                icon: _exporting
                                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.file_download_outlined, size: 18),
                                label: Text(isArabic ? 'تصدير إلى Excel' : 'Export to Excel'),
                              ),
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
