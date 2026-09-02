import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/loyalty_service.dart';
import '../../core/theme.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  final _service = LoyaltyService();
  int? _points;
  bool _isRedeeming = false;
  List<Map<String, dynamic>> _redemptions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final customerId = context.read<AuthProvider>().profile?.id;
    if (customerId == null) return;
    final points = await _service.getPoints(customerId);
    final redemptions = await _service.getMyRedemptions(customerId);
    if (mounted) setState(() { _points = points; _redemptions = redemptions; });
  }

  Future<void> _redeem(int points) async {
    final customerId = context.read<AuthProvider>().profile?.id;
    if (customerId == null) return;
    final isArabic = context.read<LocaleProvider>().isArabic;

    setState(() => _isRedeeming = true);
    try {
      final code = await _service.redeemPoints(customerId: customerId, points: points);
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(isArabic ? 'تم الاستبدال بنجاح' : 'Redeemed successfully'),
            content: Text(
              isArabic
                  ? 'كود الخصم بتاعك: $code\nقوله للأدمن وقت الدفع.'
                  : 'Your discount code: $code\nShow it to the seller at checkout.',
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(isArabic ? 'تمام' : 'OK'))],
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isArabic ? 'حصل خطأ، جرب تاني' : 'Something went wrong, try again')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRedeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final points = _points ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(isArabic ? 'نقاط الولاء' : 'Loyalty Points')),
      body: _points == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        Text(isArabic ? 'رصيدك الحالي' : 'Your balance', style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text('$points', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                        Text(isArabic ? 'نقطة' : 'points', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isArabic
                        ? 'كل 10 جنيه تشتريهم = نقطة. كل 100 نقطة تقدر تستبدلها بخصم 50 جنيه على أي عملية شراء.'
                        : 'Every 10 EGP you spend = 1 point. Every 100 points can be redeemed for a 50 EGP discount.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: (points >= 100 && !_isRedeeming) ? () => _redeem(100) : null,
                    icon: _isRedeeming
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.redeem),
                    label: Text(isArabic ? 'استبدل 100 نقطة بخصم 50 ج.م' : 'Redeem 100 points for 50 EGP off'),
                  ),
                  if (points < 100)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        isArabic ? 'محتاج ${100 - points} نقطة كمان' : 'You need ${100 - points} more points',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (_redemptions.isNotEmpty) ...[
                    Text(isArabic ? 'أكواد الخصم بتاعتك' : 'Your discount codes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ..._redemptions.map((r) => Card(
                          child: ListTile(
                            leading: Icon(r['used'] == true ? Icons.check_circle : Icons.local_offer, color: r['used'] == true ? Colors.grey : AppTheme.primaryColor),
                            title: Text(r['discount_code']),
                            subtitle: Text('${r['discount_amount']} ${isArabic ? 'ج.م' : 'EGP'}'),
                            trailing: r['used'] == true ? Text(isArabic ? 'مستخدم' : 'Used', style: const TextStyle(color: Colors.grey)) : null,
                          ),
                        )),
                  ],
                ],
              ),
            ),
    );
  }
}
