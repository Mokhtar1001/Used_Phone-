import 'package:flutter/material.dart';
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

  Future<void> _updateStatus(String orderId, String newStatus) async {
    await _client.from('orders').update({'status': newStatus}).eq('id', orderId);
    _load();
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
                          subtitle: Text('${customer?['full_name'] ?? ''} • ${customer?['phone'] ?? ''}'),
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
                                  onSelected: (v) => _updateStatus(order['id'], v),
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