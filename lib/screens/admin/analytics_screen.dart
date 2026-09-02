import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/locale_provider.dart';
import '../../services/analytics_service.dart';
import '../../models/product.dart';
import '../../core/theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _service = AnalyticsService();
  List<Product> _mostViewed = [];
  Map<String, double> _monthlyRevenue = {};
  double _totalRevenue = 0;
  int _totalSold = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _service.getMostViewedProducts(limit: 5),
      _service.getMonthlyRevenue(months: 6),
      _service.getTotalRevenue(),
      _service.getTotalSoldCount(),
    ]);
    if (mounted) {
      setState(() {
        _mostViewed = results[0] as List<Product>;
        _monthlyRevenue = results[1] as Map<String, double>;
        _totalRevenue = results[2] as double;
        _totalSold = results[3] as int;
        _isLoading = false;
      });
    }
  }

  String _monthLabel(String key, bool isArabic) {
    final parts = key.split('-');
    final monthIndex = int.parse(parts[1]);
    const namesAr = ['', 'ينا', 'فبر', 'مار', 'أبر', 'مايو', 'يون', 'يول', 'أغس', 'سبت', 'أكت', 'نوف', 'ديس'];
    const namesEn = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return isArabic ? namesAr[monthIndex] : namesEn[monthIndex];
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(isArabic ? 'إحصائيات' : 'Analytics')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final months = _monthlyRevenue.keys.toList();
    final maxRevenue = _monthlyRevenue.values.isEmpty ? 100.0 : _monthlyRevenue.values.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: Text(isArabic ? 'إحصائيات' : 'Analytics')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(child: _StatCard(label: isArabic ? 'إجمالي الإيرادات' : 'Total Revenue', value: '${_totalRevenue.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}')),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: isArabic ? 'إجمالي المبيعات' : 'Total Sold', value: '$_totalSold')),
              ],
            ),
            const SizedBox(height: 24),
            Text(isArabic ? 'الإيرادات آخر 6 شهور' : 'Revenue - last 6 months', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxRevenue == 0 ? 100 : maxRevenue * 1.2,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= months.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(_monthLabel(months[i], isArabic), style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(months.length, (i) {
                    return BarChartGroupData(x: i, barRods: [
                      BarChartRodData(toY: _monthlyRevenue[months[i]] ?? 0, color: AppTheme.primaryColor, width: 18, borderRadius: BorderRadius.circular(4)),
                    ]);
                  }),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(isArabic ? 'أكتر المنتجات مشاهدة' : 'Most viewed products', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (_mostViewed.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(isArabic ? 'لا يوجد بيانات بعد' : 'No data yet', style: TextStyle(color: Colors.grey.shade500)),
              )
            else
              ..._mostViewed.map((p) => Card(
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: p.mainImage.isNotEmpty
                            ? CachedNetworkImage(imageUrl: p.mainImage, width: 44, height: 44, fit: BoxFit.cover)
                            : Container(width: 44, height: 44, color: Colors.grey.shade200, child: const Icon(Icons.phone_android, size: 20)),
                      ),
                      title: Text(p.name(isArabic), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text('${p.viewsCount}'),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: AppTheme.blackColor10), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
} 