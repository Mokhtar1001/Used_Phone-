import 'package:supabase_flutter/supabase_flutter.dart';

class LoyaltyService {
  final _client = Supabase.instance.client;

  Future<int> getPoints(String customerId) async {
    final data = await _client.from('profiles').select('loyalty_points').eq('id', customerId).single();
    return (data['loyalty_points'] as int?) ?? 0;
  }

  /// بيستبدل نقاط بكود خصم (كل 100 نقطة = 50 جنيه خصم)، وبيرجع كود الخصم
  /// نفس الدالة بترمي exception لو الرصيد مش كافي
  Future<String> redeemPoints({required String customerId, required int points}) async {
    final result = await _client.rpc('redeem_loyalty_points', params: {
      'p_customer_id': customerId,
      'p_points': points,
    });
    return result as String;
  }

  Future<List<Map<String, dynamic>>> getMyRedemptions(String customerId) async {
    final data = await _client
        .from('loyalty_redemptions')
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}
