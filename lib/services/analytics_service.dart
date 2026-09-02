import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class AnalyticsService {
  final _client = Supabase.instance.client;

  /// أكتر المنتجات مشاهدة (يشمل المباع والمتاح، الأدمن محتاج يشوف الاتنين)
  Future<List<Product>> getMostViewedProducts({int limit = 5}) async {
    final data = await _client
        .from('products')
        .select('*, product_images(*)')
        .order('views_count', ascending: false)
        .limit(limit);
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  /// إجمالي الإيرادات من كل المنتجات اللي اتباعت (sold)
  Future<double> getTotalRevenue() async {
    final data = await _client.from('products').select('price').eq('status', 'sold');
    double total = 0;
    for (final row in (data as List)) {
      total += (row['price'] as num).toDouble();
    }
    return total;
  }

  /// إيرادات كل شهر آخر 6 شهور - المفتاح بصيغة "YYYY-MM"
  Future<Map<String, double>> getMonthlyRevenue({int months = 6}) async {
    final since = DateTime.now().subtract(Duration(days: months * 31));
    final data = await _client
        .from('products')
        .select('price, sold_at')
        .eq('status', 'sold')
        .gte('sold_at', since.toIso8601String());

    final Map<String, double> result = {};
    // نجهز آخر N شهر بالصفر مقدمًا، عشان الرسم البياني يبان مرتب حتى لو مفيش مبيعات في شهر معين
    final now = DateTime.now();
    for (int i = months - 1; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      result[key] = 0;
    }

    for (final row in (data as List)) {
      if (row['sold_at'] == null) continue;
      final soldAt = DateTime.parse(row['sold_at']);
      final key = '${soldAt.year}-${soldAt.month.toString().padLeft(2, '0')}';
      if (result.containsKey(key)) {
        result[key] = (result[key] ?? 0) + (row['price'] as num).toDouble();
      }
    }
    return result;
  }

  Future<int> getTotalSoldCount() async {
    final data = await _client.from('products').select('id').eq('status', 'sold').count(CountOption.exact);
    return data.count;
  }
}
