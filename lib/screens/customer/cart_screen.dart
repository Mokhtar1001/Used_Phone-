import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/address.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/address_service.dart';
import '../../services/cart_order_service.dart';
import '../../services/favorites_service.dart';
import '../../utils/grade_text.dart';
import '../../widgets/address_form.dart';
import '../../widgets/customer_nav_actions.dart';
import '../../widgets/desktop_top_nav.dart';
import '../../widgets/guest_guard.dart';
import '../../widgets/site_footer.dart';
import 'product_details_screen.dart';

/// سلة المشتريات (مبنية على Merchnt_Cart_Page_Mockup.html).
/// الـ Checkout بيبعت IDs المنتجات بس لدالة place_cart_order في Supabase، والسيرفر هو اللي بيتأكد
/// إنها متاحة وبيحسب الأسعار والخصم وبيحجزها (supabase/migration_cart_checkout.sql).
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _money = NumberFormat('#,##0');
  final _orders = CartOrderService();
  final _promoController = TextEditingController();

  bool _ar = false;
  bool _placing = false;
  String _zone = 'cairo'; // cairo | outside

  // عناوين العميل (لحد عنوانين). الأول إجباري وقت الشراء، التاني اختياري.
  final _addressService = AddressService();
  List<Address> _addresses = [];
  String? _addressId;
  bool _addressesLoaded = false;

  String? _promoCode; // الكود المطبّق
  double _discount = 0;
  bool _promoBusy = false;
  String? _promoError;

  String _t(String ar, String en) => _ar ? ar : en;
  String _price(num v) => _ar ? '${_money.format(v)} ج.م' : 'EGP ${_money.format(v)}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAddresses());
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  // ───────────────────────── العناوين ─────────────────────────

  /// بيجيب عناوين العميل (لو مسجل دخول). [selectId] لو عايز تختار عنوان بعينه بعد الحفظ.
  Future<void> _loadAddresses({String? selectId}) async {
    final userId = context.read<AuthProvider>().profile?.id;
    if (userId == null) return;
    try {
      final list = await _addressService.getMyAddresses(userId);
      if (!mounted) return;
      setState(() {
        _addresses = list;
        _addressesLoaded = true;
        final wanted = selectId ?? _addressId;
        final exists = list.any((a) => a.id == wanted);
        _addressId = exists ? wanted : (list.isEmpty ? null : list.first.id);
      });
      if (selectId != null || _addresses.length == 1) _syncZoneToAddress();
    } catch (_) {
      // لو فشل التحميل، Checkout هيحاول تاني
    }
  }

  Address? get _selectedAddress {
    for (final a in _addresses) {
      if (a.id == _addressId) return a;
    }
    return null;
  }

  /// القاهرة/الجيزة = Inside Cairo، غير كده Outside Cairo (العميل يقدر يغيّرها بعدها)
  void _syncZoneToAddress() {
    final a = _selectedAddress;
    if (a != null && mounted) setState(() => _zone = a.isGreaterCairo ? 'cairo' : 'outside');
  }

  Future<void> _addAddress({String defaultLabel = 'Home'}) async {
    final result = await showAddressFormDialog(context, defaultLabel: defaultLabel);
    if (result?.saved != null) await _loadAddresses(selectId: result!.saved!.id);
  }

  Future<void> _editAddress(Address address) async {
    final result = await showAddressFormDialog(context, existing: address);
    if (result == null) return;
    await _loadAddresses(selectId: result.deleted ? null : result.saved?.id);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ───────────────────────── الإجراءات ─────────────────────────

  Future<void> _remove(CartProvider cart, Product product) async {
    await cart.remove(product.id);
    await _revalidatePromo(cart);
  }

  Future<void> _moveToWishlist(CartProvider cart, Product product) async {
    final ok = await requireLogin(
      context,
      messageAr: 'سجّل دخولك عشان تنقل للمفضلة',
      messageEn: 'Sign in to save to your wishlist',
    );
    if (!ok || !mounted) return;
    final userId = context.read<AuthProvider>().profile?.id;
    if (userId == null) return;

    try {
      final favorites = FavoritesService();
      final ids = await favorites.getMyFavoriteIds(userId);
      if (!ids.contains(product.id)) await favorites.toggleFavorite(userId, product.id);
      await _remove(cart, product);
      if (mounted) _snack(_t('اتنقل للمفضلة', 'Moved to your wishlist'));
    } catch (_) {
      if (mounted) _snack(_t('حصل خطأ، حاول تاني', 'Something went wrong, please try again'));
    }
  }

  Future<void> _applyPromo(CartProvider cart) async {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _promoBusy = true;
      _promoError = null;
    });
    try {
      final discount = await _orders.validatePromo(code, cart.total);
      if (!mounted) return;
      setState(() {
        _promoCode = code;
        _discount = discount;
      });
    } on PromoException catch (e) {
      if (mounted) setState(() => _promoError = _promoMessage(e.reason));
    } catch (_) {
      if (mounted) setState(() => _promoError = _t('مقدرناش نتحقق من الكود، حاول تاني', "Couldn't check the code, please try again"));
    } finally {
      if (mounted) setState(() => _promoBusy = false);
    }
  }

  String _promoMessage(String reason) {
    switch (reason) {
      case 'promo_expired':
        return _t('الكود ده منتهي', 'This code has expired');
      case 'promo_min_subtotal':
        return _t('إجمالي الطلب أقل من الحد الأدنى للكود ده', "Your order doesn't reach this code's minimum");
      default:
        return _t('الكود غير صحيح', 'Invalid promo code');
    }
  }

  void _clearPromo({bool keepText = false}) {
    setState(() {
      _promoCode = null;
      _discount = 0;
      _promoError = null;
      if (!keepText) _promoController.clear();
    });
  }

  /// لو السلة اتغيرت والكود مطبّق: نحسب الخصم من جديد (أو نشيله لو بقى مش صالح)
  Future<void> _revalidatePromo(CartProvider cart) async {
    final code = _promoCode;
    if (code == null) return;
    if (cart.items.isEmpty) return _clearPromo();
    try {
      final discount = await _orders.validatePromo(code, cart.total);
      if (mounted) setState(() => _discount = discount);
    } on PromoException catch (e) {
      if (!mounted) return;
      _clearPromo(keepText: true);
      setState(() => _promoError = _promoMessage(e.reason));
    } catch (_) {
      // مشكلة شبكة: نسيب الخصم زي ما هو، والسيرفر هيتحقق وقت الطلب
    }
  }

  Future<void> _checkout(CartProvider cart) async {
    final ok = await requireLogin(
      context,
      messageAr: 'سجّل دخولك عشان تكمّل الطلب',
      messageEn: 'Sign in to place your order',
    );
    if (!ok || !mounted) return;

    // العنوان إجباري: لو العميل مسجلش عنوان نطلعله بوب أب يضيفه الأول
    await _loadAddresses();
    if (!mounted) return;
    if (_addresses.isEmpty) {
      final wantsToAdd = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.location_on_outlined, size: 36),
          title: Text(_t('مفيش عنوان متسجل', 'No delivery address yet')),
          content: Text(
            _t('محتاجين عنوانك عشان نوصّل طلبك. ضيف عنوان التوصيل وبعدها كمّل الطلب.',
                'We need your address to deliver your order. Add a delivery address, then continue.'),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(_t('إلغاء', 'Cancel'))),
            ElevatedButton(onPressed: () => Navigator.pop(c, true), child: Text(_t('إضافة عنوان', 'Add address'))),
          ],
        ),
      );
      if (wantsToAdd == true && mounted) {
        await _addAddress();
        if (mounted && _selectedAddress != null) {
          _snack(_t('اتحفظ العنوان. راجع الطلب وداس إتمام الطلب.', 'Address saved. Review your order and press Checkout.'));
        }
      }
      return;
    }
    final address = _selectedAddress;
    if (address?.id == null) return;

    setState(() => _placing = true);
    try {
      await _orders.placeOrder(
        productIds: [for (final p in cart.items) p.id],
        zone: _zone,
        addressId: address!.id!,
        promo: _promoCode,
      );
      await cart.clear();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, size: 40, color: AppTheme.successColor),
          content: Text(
            _zone == 'outside'
                ? _t('تم تسجيل طلبك! هنتواصل معاك لترتيب العربون والتوصيل.', "Your order is placed! We'll contact you to arrange the courier deposit and delivery.")
                : _t('تم تسجيل طلبك! هنتواصل معاك لتأكيد الدفع عند الاستلام.', "Your order is placed! We'll contact you to confirm payment on delivery."),
            textAlign: TextAlign.center,
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(_t('تمام', 'OK')))],
        ),
      );
      if (mounted) Navigator.pop(context);
    } on UnavailableProductsException catch (e) {
      // منتج اتباع/اتحجز وهو في السلة: نشيله ونكمّل بالباقي
      for (final id in e.ids) {
        await cart.remove(id);
      }
      await _revalidatePromo(cart);
      if (mounted) {
        _snack(_t('بعض الموبايلات مبقتش متاحة واتشالت من السلة. راجع السلة وكمّل.',
            'Some phones are no longer available and were removed from your cart. Review it and try again.'));
      }
    } on AddressRequiredException {
      await _loadAddresses();
      if (mounted) _snack(_t('اختار عنوان توصيل صحيح', 'Please choose a valid delivery address'));
    } on PromoException catch (e) {
      _clearPromo(keepText: true);
      if (mounted) {
        setState(() => _promoError = _promoMessage(e.reason));
        _snack(_t('كود الخصم مبقاش صالح', 'The promo code is no longer valid'));
      }
    } on PostgrestException catch (_) {
      if (mounted) _snack(_t('حصل خطأ، حاول تاني', 'Something went wrong, please try again'));
    } catch (_) {
      if (mounted) _snack(_t('حصل خطأ، حاول تاني', 'Something went wrong, please try again'));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  // ───────────────────────── الشكل ─────────────────────────

  @override
  Widget build(BuildContext context) {
    _ar = context.watch<LocaleProvider>().isArabic;
    final cart = context.watch<CartProvider>();
    final isDesktop = Responsive.isDesktop(context);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final PreferredSizeWidget appBar = isDesktop
        ? DesktopTopNav(selectedIndex: 0, onDestinationSelected: (_) {}, items: const [], trailing: const CustomerNavActions())
        : AppBar(title: Text(_t('السلة', 'Your Cart')));

    return Scaffold(
      appBar: appBar,
      body: SingleChildScrollView(
        child: Column(
          children: [
            cart.items.isEmpty ? _empty() : _content(cart, wide: wide, desktop: isDesktop),
            const SiteFooter(),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 56, color: AppTheme.lightGray),
            const SizedBox(height: 14),
            Text(_t('السلة فاضية', 'Your cart is empty'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(_t('ضيف موبايلات وهتلاقيها هنا', 'Add phones and they will show up here'), style: const TextStyle(color: AppTheme.midGray)),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: Text(_t('تصفح الموبايلات', 'Browse phones')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(CartProvider cart, {required bool wide, required bool desktop}) {
    final items = _itemsColumn(cart);
    final summary = _summaryCard(cart);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(wide ? 32 : 16, 0, wide ? 32 : 16, 72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (desktop) _breadcrumb(),
              Padding(
                padding: EdgeInsets.only(top: desktop ? 20 : 24, bottom: wide ? 36 : 24),
                child: Text(_t('سلتك', 'Your Cart'), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
              ),
              wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: items),
                        const SizedBox(width: 48),
                        SizedBox(width: 360, child: summary),
                      ],
                    )
                  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [items, const SizedBox(height: 32), summary]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _breadcrumb() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: Text(_t('الرئيسية', 'Home'), style: const TextStyle(fontSize: 13.5, color: AppTheme.midGray)),
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('/', style: TextStyle(fontSize: 13.5, color: AppTheme.midGray))),
          Text(_t('سلتك', 'Your Cart'), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _itemsColumn(CartProvider cart) {
    final items = cart.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          _CartItem(
            product: items[i],
            isArabic: _ar,
            first: i == 0,
            priceText: _price,
            onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: items[i].id))),
            onWishlist: () => _moveToWishlist(cart, items[i]),
            onRemove: () => _remove(cart, items[i]),
          ),
        // كل موبايل قطعة واحدة: مفيش كمية
        Container(
          margin: const EdgeInsets.only(top: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: AppTheme.offWhite, borderRadius: BorderRadius.circular(10)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.info_outline, size: 16, color: AppTheme.gold)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _t(
                    'كل موبايل في Merchnt قطعة واحدة متقيّمة لوحدها، مش صنف بيتعاد توريده. عشان كده مفيش اختيار للكمية. كمّل الطلب عشان تأمّنه.',
                    "Each phone on Merchnt is a single, individually graded unit — not a restockable item. That's why there's no quantity selector here. Place your order to secure it.",
                  ),
                  style: const TextStyle(fontSize: 13, color: AppTheme.deepGray, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: Container(
              padding: const EdgeInsets.only(bottom: 2),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.gold, width: 2))),
              child: Text(
                _ar ? 'متابعة التسوق ←' : '← Continue shopping',
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// "Deliver to": العنوان الأول إجباري، والتاني اختياري. بيظهر لو العميل مسجل دخول.
  Widget _addressSection() {
    final loggedIn = context.read<AuthProvider>().profile != null;
    if (!loggedIn || !_addressesLoaded) return const SizedBox.shrink();

    final children = <Widget>[
      Text(_t('التوصيل إلى', 'Deliver to'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
    ];

    if (_addresses.isEmpty) {
      children.add(
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.pureWhite, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.lightGray, width: 1.5)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_t('لسه مسجلتش عنوان توصيل. العنوان مطلوب لإتمام الطلب.', "You haven't saved a delivery address yet. It's required to place your order."),
                  style: const TextStyle(fontSize: 13, color: AppTheme.deepGray)),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _addAddress(),
                icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                label: Text(_t('إضافة عنوان', 'Add address')),
              ),
            ],
          ),
        ),
      );
    } else {
      for (final a in _addresses) {
        children.add(_AddressOption(
          address: a,
          isArabic: _ar,
          selected: a.id == _addressId,
          onTap: () {
            setState(() => _addressId = a.id);
            _syncZoneToAddress();
          },
          onEdit: () => _editAddress(a),
        ));
        children.add(const SizedBox(height: 10));
      }
      if (_addresses.length < 2) {
        children.add(
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => _addAddress(defaultLabel: 'Work'),
              icon: const Icon(Icons.add, size: 18),
              label: Text(_t('إضافة عنوان تاني (اختياري)', 'Add another address (optional)')),
            ),
          ),
        );
      }
    }

    children.add(const SizedBox(height: 14));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  Widget _summaryCard(CartProvider cart) {
    final subtotal = cart.total;
    final discount = _promoCode != null ? _discount : 0.0;
    final total = (subtotal - discount).clamp(0, double.infinity);

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(label, style: const TextStyle(fontSize: 14.5, color: AppTheme.deepGray))),
              const SizedBox(width: 12),
              Text(value, style: const TextStyle(fontSize: 14.5, color: AppTheme.deepGray)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: AppTheme.offWhite, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_t('ملخص الطلب', 'Order summary'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _addressSection(),
          _DeliveryOption(
            selected: _zone == 'cairo',
            title: _t('داخل القاهرة', 'Inside Cairo'),
            subtitle: _t('توصيل بمندوبينا — 1–2 يوم عمل', 'In-house delivery — 1–2 business days'),
            onTap: () => setState(() => _zone = 'cairo'),
          ),
          const SizedBox(height: 10),
          _DeliveryOption(
            selected: _zone == 'outside',
            title: _t('خارج القاهرة', 'Outside Cairo'),
            subtitle: _t('شركة شحن — مطلوب عربون عند إتمام الطلب', 'Courier partner — deposit required at checkout'),
            onTap: () => setState(() => _zone = 'outside'),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  enabled: _promoCode == null,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _applyPromo(cart),
                  decoration: InputDecoration(
                    hintText: _t('كود الخصم', 'Promo code'),
                    filled: true,
                    fillColor: AppTheme.pureWhite,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.lightGray, width: 1.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.lightGray, width: 1.5)),
                    disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.lightGray, width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gold, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _promoBusy ? null : (_promoCode != null ? () => _clearPromo() : () => _applyPromo(cart)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppTheme.pureWhite,
                    foregroundColor: AppTheme.charcoal,
                    side: const BorderSide(color: AppTheme.charcoal, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  child: _promoBusy
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_promoCode != null ? _t('إزالة', 'Remove') : _t('تطبيق', 'Apply')),
                ),
              ),
            ],
          ),
          if (_promoError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_promoError!, style: const TextStyle(fontSize: 12.5, color: AppTheme.errorColor)),
            ),
          if (_promoCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_t('تم تطبيق الكود $_promoCode', 'Code $_promoCode applied'),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.successColor)),
            ),
          const SizedBox(height: 22),
          row(_t('المجموع الفرعي (${cart.count} منتج)', 'Subtotal (${cart.count} ${cart.count == 1 ? 'item' : 'items'})'), _price(subtotal)),
          if (discount > 0) row(_t('خصم الكود', 'Promo discount'), '− ${_price(discount)}'),
          row(_t('التوصيل', 'Delivery'), _zone == 'cairo' ? _t('مجاني', 'Free') : _t('يتحدد عند إتمام الطلب', 'Calculated at checkout')),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _t('خارج القاهرة: عربون الشحن بيتحدد عند إتمام الطلب', 'Outside Cairo: courier deposit calculated at checkout'),
              style: const TextStyle(fontSize: 12, color: AppTheme.midGray),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.lightGray))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_t('الإجمالي', 'Total'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(_price(total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.pureWhite, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined, size: 20, color: AppTheme.charcoal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _t('الدفع عند الاستلام — من غير كارت أو بوابة دفع', 'Pay on delivery — no card or gateway needed'),
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _placing ? null : () => _checkout(cart),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.charcoal,
              foregroundColor: AppTheme.pureWhite,
              disabledBackgroundColor: AppTheme.lightGray,
              elevation: 0,
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            child: _placing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_t('إتمام الطلب', 'Checkout')),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.gold)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _t('كل موبايل متقيّم ومتفحوص وعليه ضمان', 'Every phone graded, verified & warrantied'),
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.midGray),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── عناصر السلة ─────────────────────────

class _CartItem extends StatelessWidget {
  final Product product;
  final bool isArabic;
  final bool first;
  final String Function(num) priceText;
  final VoidCallback onOpen;
  final VoidCallback onWishlist;
  final VoidCallback onRemove;

  const _CartItem({
    required this.product,
    required this.isArabic,
    required this.first,
    required this.priceText,
    required this.onOpen,
    required this.onWishlist,
    required this.onRemove,
  });

  String _title() {
    final name = product.name(isArabic);
    final storage = product.storage;
    if (storage == null || storage.isEmpty || name.toLowerCase().contains(storage.toLowerCase())) return name;
    return '$name — $storage';
  }

  @override
  Widget build(BuildContext context) {
    final p = product;
    final letter = p.gradeLetter;
    final unavailable = p.status != 'available';
    final hasOriginal = p.originalPrice != null && p.originalPrice! > p.price;
    final specs = [
      if (p.color != null && p.color!.isNotEmpty) p.color!,
      if (p.ramGb != null) '${p.ramGb}GB RAM',
      if (p.batteryHealth != null) '${isArabic ? 'البطارية' : 'Battery'} ${p.batteryHealth}%',
    ];

    final nowText = Text(priceText(p.price), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800));
    final wasText = hasOriginal
        ? Text(priceText(p.originalPrice!), style: const TextStyle(fontSize: 13, color: AppTheme.midGray, decoration: TextDecoration.lineThrough))
        : null;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onOpen,
          child: Text(_title(), style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)),
        ),
        if (specs.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(specs.join(' · '), style: const TextStyle(fontSize: 13.5, color: AppTheme.midGray)),
        ],
        if (letter != null) ...[
          const SizedBox(height: 4),
          Text(gradeLabel(letter, isArabic), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.deepGray)),
        ],
        if (unavailable) ...[
          const SizedBox(height: 6),
          Text(
            p.status == 'sold'
                ? (isArabic ? 'اتباع' : 'Sold')
                : (isArabic ? 'مبقاش متاح دلوقتي (محجوز)' : 'No longer available (reserved)'),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.errorColor),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 18,
          children: [
            _LinkButton(label: isArabic ? 'انقل للمفضلة' : 'Move to wishlist', onTap: onWishlist),
            _LinkButton(label: isArabic ? 'إزالة' : 'Remove', onTap: onRemove, danger: true),
          ],
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final image = GestureDetector(onTap: onOpen, child: _ItemImage(product: p, letter: letter));

        return Container(
          padding: EdgeInsets.fromLTRB(0, first ? 0 : 24, 0, 24),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.lightGray))),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [image, const SizedBox(width: 16), Expanded(child: info)]),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [nowText, if (wasText != null) wasText],
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    image,
                    const SizedBox(width: 20),
                    Expanded(child: info),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [nowText, if (wasText != null) ...[const SizedBox(height: 4), wasText]],
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _ItemImage extends StatelessWidget {
  final Product product;
  final String? letter;
  const _ItemImage({required this.product, required this.letter});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    Border? border;
    switch (letter) {
      case 'A':
        bg = AppTheme.charcoal;
        fg = AppTheme.pureWhite;
        break;
      case 'B':
        bg = AppTheme.pureWhite;
        fg = AppTheme.charcoal;
        border = Border.all(color: AppTheme.charcoal, width: 1.5);
        break;
      default:
        bg = AppTheme.pureWhite;
        fg = AppTheme.midGray;
        border = Border.all(color: AppTheme.midGray, width: 1.5);
    }

    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(color: AppTheme.offWhite, borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: product.images.isEmpty
                  ? const Icon(Icons.phone_android, size: 40, color: AppTheme.lightGray)
                  : CachedNetworkImage(imageUrl: product.images.first, fit: BoxFit.contain),
            ),
          ),
          if (letter != null)
            PositionedDirectional(
              top: 8,
              start: 8,
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: border),
                child: Text(letter!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
              ),
            ),
        ],
      ),
    );
  }
}

/// زرار نصي صغير (Move to wishlist / Remove)، الـ Remove بيحمرّ مع الـ hover
class _LinkButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _LinkButton({required this.label, required this.onTap, this.danger = false});

  @override
  State<_LinkButton> createState() => _LinkButtonState();
}

class _LinkButtonState extends State<_LinkButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = _hover ? (widget.danger ? AppTheme.errorColor : AppTheme.charcoal) : AppTheme.deepGray;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(widget.label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: color)),
        ),
      ),
    );
  }
}

class _AddressOption extends StatelessWidget {
  final Address address;
  final bool isArabic;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  const _AddressOption({required this.address, required this.isArabic, required this.selected, required this.onTap, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppTheme.charcoal : AppTheme.lightGray, width: selected ? 2 : 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 20, color: AppTheme.charcoal),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(address.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(address.summary(isArabic), style: const TextStyle(fontSize: 12.5, color: AppTheme.midGray, height: 1.4)),
                  ],
                ),
              ),
              IconButton(
                tooltip: isArabic ? 'تعديل' : 'Edit',
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.midGray),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _DeliveryOption({required this.selected, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppTheme.charcoal : AppTheme.lightGray, width: selected ? 2 : 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 20, color: AppTheme.charcoal),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppTheme.midGray)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
