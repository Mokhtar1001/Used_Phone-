import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/compare_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/theme.dart';

class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  String _conditionLabel(String? condition, bool isArabic) {
    switch (condition) {
      case 'excellent':
        return isArabic ? 'ممتازة' : 'Excellent';
      case 'good':
        return isArabic ? 'جيدة' : 'Good';
      case 'fair':
        return isArabic ? 'مقبولة' : 'Fair';
      default:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final products = context.watch<CompareProvider>().items;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'مقارنة المنتجات' : 'Compare Products'),
        actions: [
          TextButton(
            onPressed: () => context.read<CompareProvider>().clear(),
            child: Text(isArabic ? 'مسح الكل' : 'Clear all'),
          ),
        ],
      ),
      body: products.length < 2
          ? Center(
              child: Text(
                isArabic ? 'اختار منتجين على الأقل عشان تقارن' : 'Pick at least 2 products to compare',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                columns: [
                  const DataColumn(label: SizedBox(width: 90, child: Text(''))),
                  ...products.map((p) => DataColumn(
                        label: SizedBox(
                          width: 140,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: p.mainImage.isNotEmpty
                                    ? CachedNetworkImage(imageUrl: p.mainImage, width: 60, height: 60, fit: BoxFit.cover)
                                    : Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.phone_android)),
                              ),
                              const SizedBox(height: 6),
                              Text(p.name(isArabic), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            ],
                          ),
                        ),
                      )),
                ],
                rows: [
                  _row(isArabic ? 'السعر' : 'Price', products.map((p) => '${p.price.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}').toList()),
                  _row(isArabic ? 'الماركة' : 'Brand', products.map((p) => p.brand ?? '-').toList()),
                  _row(isArabic ? 'التخزين' : 'Storage', products.map((p) => p.storage ?? '-').toList()),
                  _row(isArabic ? 'اللون' : 'Color', products.map((p) => p.color ?? '-').toList()),
                  _row(isArabic ? 'الحالة' : 'Condition', products.map((p) => _conditionLabel(p.condition, isArabic)).toList()),
                  _row(isArabic ? 'المشاهدات' : 'Views', products.map((p) => '${p.viewsCount}').toList()),
                  _row(
                    isArabic ? 'التوفر' : 'Availability',
                    products.map((p) => p.status == 'sold' ? (isArabic ? 'تم البيع' : 'Sold') : (isArabic ? 'متاح' : 'Available')).toList(),
                  ),
                ],
              ),
            ),
    );
  }

  DataRow _row(String label, List<String> values) {
    return DataRow(cells: [
      DataCell(Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.blackColor60))),
      ...values.map((v) => DataCell(Text(v))),
    ]);
  }
}
