import 'package:flutter/material.dart';
import '../../core/egypt_governorates.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/locale_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _client
        .from('orders')
        .select('*, products(name_ar, name_en), profiles!orders_customer_id_fkey(full_name, phone)')
        .order('created_at', ascending: false);
    setState(() {
      _orders = List<Map<String, dynamic>>.from(data);
      _isLoading = false;
    });
  }

  /// تغيير حالة الطلب + أثره على المنتج (الطلب بيحجز المنتج وقت الإنشاء):
  /// - failed: نفك الحجز والمنتج يرجع متاح
  /// - paid: المنتج يتعلّم "تم البيع" (وبيظهر في سجل المبيعات وشيت جوجل)
  Future<void> _updateStatus(Map<String, dynamic> order, String newStatus) async {
    await _client.from('orders').update({'status': newStatus}).eq('id', order['id']);

    final productId = order['product_id'];
    if (productId != null) {
      try {
        if (newStatus == 'failed') {
          await _client.from('products').update({'status': 'available'}).eq('id', productId).eq('status', 'reserved');
        } else if (newStatus == 'paid') {
          await _client
              .from('products')
              .update({'status': 'sold', 'sold_at': DateTime.now().toUtc().toIso8601String()})
              .eq('id', productId);
        }
      } catch (_) {
        // الطلب اتحدّث؛ لو تحديث المنتج فشل الأدمن يعدّله يدوي من شاشة المنتجات
      }
    }
    _load();
  }

  /// عنوان الشحن المحفوظ مع الطلب (نسخة وقت الشراء)
  String _addressLine(dynamic raw, bool isArabic) {
    if (raw is! Map) return '';
    final parts = [
      raw['street'],
      raw['building'],
      raw['city'],
      raw['governorate'] != null ? governorateLabel(raw['governorate'].toString(), isArabic) : null,
    ].where((e) => e != null && e.toString().trim().isNotEmpty).map((e) => e.toString());
    final line = parts.join('، ');
    final landmark = raw['landmark']?.toString();
    return (landmark != null && landmark.isNotEmpty) ? '$line (${isArabic ? 'علامة' : 'near'}: $landmark)' : line;
  }

  String _zoneLabel(String? zone, bool isArabic) {
    switch (zone) {
      case 'cairo':
        return isArabic ? 'داخل القاهرة' : 'Inside Cairo';
      case 'outside':
        return isArabic ? 'خارج القاهرة' : 'Outside Cairo';
      default:
        return '';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(isArabic ? 'الطلبات' : 'Orders'), automaticallyImplyLeading: false),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
                ? Center(child: Text(isArabic ? 'لا يوجد طلبات بعد' : 'No orders yet'))
                : ListView.builder(
                    itemCount: _orders.length,
                    itemBuilder: (context, i) {
                      final order = _orders[i];
                      final product = order['products'];
                      final customer = order['profiles'];
                      final status = order['status'] as String;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          title: Text(isArabic ? (product?['name_ar'] ?? '') : (product?['name_en'] ?? '')),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${customer?['full_name'] ?? ''} • ${customer?['phone'] ?? ''}'),
                              if (order['delivery_zone'] != null)
                                Text(
                                  [
                                    _zoneLabel(order['delivery_zone'] as String?, isArabic),
                                    if (order['promo_code'] != null)
                                      '${order['promo_code']} (−${NumberFormat.decimalPattern().format(order['discount_amount'] ?? 0)})',
                                  ].where((e) => e.isNotEmpty).join(' • '),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              if (_addressLine(order['shipping_address'], isArabic).isNotEmpty)
                                Text(
                                  _addressLine(order['shipping_address'], isArabic),
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${NumberFormat.decimalPattern().format(order['amount'])} ${isArabic ? 'ج.م' : 'EGP'}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                child: PopupMenuButton<String>(
                                  onSelected: (v) => _updateStatus(order, v),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(value: 'pending', child: Text(isArabic ? 'قيد الانتظار' : 'Pending')),
                                    PopupMenuItem(value: 'paid', child: Text(isArabic ? 'تم الدفع' : 'Paid')),
                                    PopupMenuItem(value: 'failed', child: Text(isArabic ? 'فشل' : 'Failed')),
                                  ],
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(status, style: TextStyle(color: _statusColor(status), fontSize: 11)),
                                        const SizedBox(width: 2),
                                        Icon(Icons.arrow_drop_down, size: 14, color: _statusColor(status)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}