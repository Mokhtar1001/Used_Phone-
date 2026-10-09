import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/customer_nav_actions.dart';
import '../../widgets/desktop_top_nav.dart';
import '../../widgets/guest_guard.dart';
import 'product_details_screen.dart';

/// سلة المشتريات. الـ checkout بيسجّل طلب لكل منتج بحالة "pending"
/// بنفس طريقة شاشة الدفع الحالية (CheckoutScreen)، ودفع حقيقي لسه محتاج الـ Edge Function بتاعتك.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _money = NumberFormat('#,##0');
  bool _placing = false;
  bool _ar = false;

  String _t(String ar, String en) => _ar ? ar : en;
  String _price(double v) => _ar ? '${_money.format(v)} ج.م' : 'EGP ${_money.format(v)}';

  Future<void> _checkout(CartProvider cart) async {
    final ok = await requireLogin(
      context,
      messageAr: 'سجّل دخولك عشان تكمّل الطلب',
      messageEn: 'Sign in to place your order',
    );
    if (!ok || !mounted) return;

    final customerId = context.read<AuthProvider>().profile?.id;
    if (customerId == null) return;

    setState(() => _placing = true);
    try {
      await Supabase.instance.client.from('orders').insert([
        for (final p in cart.items)
          {'product_id': p.id, 'customer_id': customerId, 'amount': p.price, 'status': 'pending'},
      ]);
      await cart.clear();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, size: 40, color: AppTheme.successColor),
          content: Text(
            _t('تم تسجيل طلبك! هنتواصل معاك لإتمام الدفع والاستلام.', "Your order is placed! We'll contact you to complete payment and delivery."),
            textAlign: TextAlign.center,
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(_t('تمام', 'OK')))],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('حصل خطأ، حاول تاني', 'Something went wrong, please try again'))),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _ar = context.watch<LocaleProvider>().isArabic;
    final cart = context.watch<CartProvider>();
    final isDesktop = Responsive.isDesktop(context);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final PreferredSizeWidget appBar = isDesktop
        ? DesktopTopNav(selectedIndex: 0, onDestinationSelected: (_) {}, items: const [], trailing: const CustomerNavActions())
        : AppBar(title: Text(_t('السلة', 'Cart')));

    return Scaffold(
      appBar: appBar,
      body: cart.items.isEmpty
          ? _empty()
          : wide
              ? _wideBody(cart)
              : _narrowBody(cart),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 56, color: AppTheme.lightGray),
          const SizedBox(height: 14),
          Text(_t('السلة فاضية', 'Your cart is empty'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(_t('ضيف موبايلات وهتلاقيها هنا', 'Add phones and they will show up here'),
              style: const TextStyle(color: AppTheme.midGray)),
          const SizedBox(height: 18),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: Text(_t('تصفح الموبايلات', 'Browse phones'))),
        ],
      ),
    );
  }

  Widget _heading(CartProvider cart) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        '${_t('السلة', 'Cart')} (${cart.count})',
        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.4),
      ),
    );
  }

  Widget _wideBody(CartProvider cart) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heading(cart),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _itemsList(cart)),
                    const SizedBox(width: 32),
                    SizedBox(width: 340, child: _summary(cart)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _narrowBody(CartProvider cart) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [_itemsList(cart)],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.lightGray))),
          child: SafeArea(top: false, child: _summary(cart, boxed: false)),
        ),
      ],
    );
  }

  Widget _itemsList(CartProvider cart) {
    return Column(
      children: [for (final p in cart.items) _CartItem(product: p, isArabic: _ar, priceText: _price(p.price), onRemove: () => cart.remove(p.id))],
    );
  }

  Widget _summary(CartProvider cart, {bool boxed = true}) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (boxed) ...[
          Text(_t('ملخص الطلب', 'Order summary'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_t('عدد المنتجات', 'Items')} (${cart.count})', style: const TextStyle(color: AppTheme.deepGray)),
            if (!boxed) Text(_price(cart.total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        if (boxed) ...[
          const SizedBox(height: 12),
          const Divider(color: AppTheme.lightGray, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_t('الإجمالي', 'Total'), style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(_price(cart.total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _placing ? null : () => _checkout(cart),
          child: _placing
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_t('إتمام الطلب', 'Checkout')),
        ),
      ],
    );

    if (!boxed) return content;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.offWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: content,
    );
  }
}

class _CartItem extends StatelessWidget {
  final Product product;
  final bool isArabic;
  final String priceText;
  final VoidCallback onRemove;
  const _CartItem({required this.product, required this.isArabic, required this.priceText, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final spec = [product.storage, product.color].where((e) => e != null && e.isNotEmpty).join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: product.id))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 84,
                  height: 84,
                  color: AppTheme.offWhite,
                  child: product.mainImage.isEmpty
                      ? const Icon(Icons.phone_iphone, color: AppTheme.lightGray, size: 32)
                      : CachedNetworkImage(imageUrl: product.mainImage, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name(isArabic),
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                    if (spec.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(spec, style: const TextStyle(fontSize: 13, color: AppTheme.midGray)),
                    ],
                    const SizedBox(height: 8),
                    Text(priceText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              IconButton(
                tooltip: isArabic ? 'إزالة' : 'Remove',
                icon: const Icon(Icons.close, size: 20, color: AppTheme.midGray),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
