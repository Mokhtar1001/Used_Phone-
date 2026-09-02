import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inspection_request.dart';

class InspectionService {
  final _client = Supabase.instance.client;

  Future<void> createRequest({
    required String productId,
    required String customerId,
  }) async {
    await _client.from('inspection_requests').insert({
      'product_id': productId,
      'customer_id': customerId,
    });
  }

  /// طلبات الفحص الخاصة بعميل معيّن
  Future<List<InspectionRequest>> getMyRequests(String customerId) async {
    final data = await _client
        .from('inspection_requests')
        .select('*, products(name_ar, name_en)')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => InspectionRequest.fromJson(e)).toList();
  }

  /// كل طلبات الفحص (للأدمن)
  Future<List<InspectionRequest>> getAllRequests() async {
    final data = await _client
        .from('inspection_requests')
        .select('*, products(name_ar, name_en), profiles!inspection_requests_customer_id_fkey(full_name)')
        .order('created_at', ascending: false);
    return (data as List).map((e) => InspectionRequest.fromJson(e)).toList();
  }

  /// الأدمن بيرد بتقرير حالة الجهاز ويقفل الطلب
  Future<void> submitReport({
    required String requestId,
    required String report,
  }) async {
    await _client.from('inspection_requests').update({
      'report': report,
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }
}
