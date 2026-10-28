import 'package:supabase_flutter/supabase_flutter.dart';

/// منتجات في السلة بقت مش متاحة (اتباعت أو اتحجزت لحد تاني)
class UnavailableProductsException implements Exception {
  final List<String> ids;
  UnavailableProductsException(this.ids);
}

/// كود الخصم مش صالح: promo_invalid / promo_expired / promo_min_subtotal
class PromoException implements Exception {
  final String reason;
  PromoException(this.reason);
}

/// العنوان مش موجود أو مش بتاع العميل (address_required)
class AddressRequiredException implements Exception {}

class CartOrderResult {
  final double subtotal;
  final double discount;
  final double total;
  const CartOrderResult({required this.subtotal, required this.discount, required this.total});
}

/// إتمام طلب السلة وكود الخصم. الحساب كله على السيرفر (supabase/migration_cart_checkout.sql).
class CartOrderService {
  final _client = Supabase.instance.client;

  static PromoException? _promoError(String message) {
    for (final r in const ['promo_invalid', 'promo_expired', 'promo_min_subtotal']) {
      if (message.contains(r)) return PromoException(r);
    }
    return null;
  }

  /// بيرجّع قيمة الخصم، أو بيرمي [PromoException]
  Future<double> validatePromo(String code, double subtotal) async {
    try {
      final result = await _client.rpc('validate_promo', params: {'p_code': code, 'p_subtotal': subtotal});
      return (result as num).toDouble();
    } on PostgrestException catch (e) {
      throw _promoError(e.message) ?? e;
    }
  }

  /// بيسجل الطلب ويحجز المنتجات. بيرمي [UnavailableProductsException] أو [PromoException] أو [AddressRequiredException].
  Future<CartOrderResult> placeOrder({
    required List<String> productIds,
    required String zone,
    required String addressId,
    String? promo,
  }) async {
    try {
      final result = await _client.rpc('place_cart_order', params: {
        'p_product_ids': productIds,
        'p_zone': zone,
        'p_address_id': addressId,
        'p_promo': (promo == null || promo.isEmpty) ? null : promo,
      });
      final map = Map<String, dynamic>.from(result as Map);
      return CartOrderResult(
        subtotal: (map['subtotal'] as num).toDouble(),
        discount: (map['discount'] as num).toDouble(),
        total: (map['total'] as num).toDouble(),
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('address_required')) throw AddressRequiredException();
      final idx = e.message.indexOf('unavailable:');
      if (idx >= 0) {
        final ids = e.message.substring(idx + 'unavailable:'.length).split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        throw UnavailableProductsException(ids);
      }
      throw _promoError(e.message) ?? e;
    }
  }
}
