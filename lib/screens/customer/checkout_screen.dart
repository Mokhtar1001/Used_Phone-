import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';

/// شاشة الدفع - مبنية على مبدأ عام يشتغل مع أي بوابة دفع (Stripe / Paymob)
/// ملحوظة مهمة: عملية الدفع الفعلية لازم تتم عن طريق Edge Function على السيرفر
/// (متتحطش مفاتيح الدفع السرية جوه التطبيق أبدًا). الكود ده بيوضح التدفق (flow) بس.
class CheckoutScreen extends StatefulWidget {
  final Product product;
  const CheckoutScreen({super.key, required this.product});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _client = Supabase.instance.client;
  bool _isProcessing = false;

  Future<void> _pay() async {
    setState(() => _isProcessing = true);
    final customerId = context.read<AuthProvider>().profile?.id;
    if (customerId == null) return;

    try {
      // 1. سجل الطلب في الداتابيز بحالة "pending"
      final order = await _client.from('orders').insert({
        'product_id': widget.product.id,
        'customer_id': customerId,
        'amount': widget.product.price,
        'status': 'pending',
      }).select().single();

      // 2. نادِ على Edge Function بتاعتك اللي بتتكلم مع Stripe/Paymob
      // مثال (لازم تستبدله بالـ Edge Function الحقيقية بتاعتك):
      // final response = await _client.functions.invoke('create-payment', body: {
      //   'order_id': order['id'],
      //   'amount': widget.product.price,
      // });
      // بعد نجاح الدفع، الـ Edge Function هي اللي تحدث حالة الطلب لـ 'paid'

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.read<LocaleProvider>().isArabic
              ? 'تم تسجيل الطلب، جاري التوجيه لصفحة الدفع...'
              : 'Order created, redirecting to payment...')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(isArabic ? 'إتمام الشراء' : 'Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                title: Text(widget.product.name(isArabic)),
                trailing: Text(
                  '${widget.product.price.toStringAsFixed(0)} ${isArabic ? 'ج.م' : 'EGP'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isArabic
                  ? 'ملحوظة: تفعيل الدفع الفعلي يحتاج حساب Stripe أو Paymob وربطه بـ Supabase Edge Function.'
                  : 'Note: Real payment needs a Stripe/Paymob account connected via a Supabase Edge Function.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pay,
              icon: _isProcessing
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.credit_card),
              label: Text(isArabic ? 'الدفع بالفيزا' : 'Pay with Card'),
            ),
          ],
        ),
      ),
    );
  }
}
