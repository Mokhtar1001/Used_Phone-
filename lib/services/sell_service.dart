import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../models/sell_models.dart';

class SellService {
  final _client = Supabase.instance.client;
  final _uuid = const Uuid();

  // ---------------- القراءة (زوار + عملاء + أدمن) ----------------

  Future<List<SellModel>> getModels({bool includeInactive = false}) async {
    final base = _client.from('sell_models').select('*, sell_model_storages(*)');
    final filtered = includeInactive ? base : base.eq('is_active', true);
    final data = await filtered.order('sort_order').order('created_at');
    return (data as List).map((e) => SellModel.fromJson(e)).toList();
  }

  Future<List<SellQuestion>> getQuestions({bool includeInactive = false}) async {
    final base = _client.from('sell_questions').select('*, sell_question_options(*)');
    final filtered = includeInactive ? base : base.eq('is_active', true);
    final data = await filtered.order('sort_order').order('created_at');
    return (data as List).map((e) => SellQuestion.fromJson(e)).toList();
  }

  Future<SellSettings> getSettings() async {
    final data = await _client.from('sell_settings').select().eq('id', 1).maybeSingle();
    return data == null ? const SellSettings() : SellSettings.fromJson(data);
  }

  // ---------------- السوبر أدمن: الموديلات ----------------

  /// صورة الموديل بتتخزن في نفس bucket صور المنتجات جوه فولدر sell/
  Future<String> uploadModelImage(XFile file) async {
    final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    final path = 'sell/${_uuid.v4()}.$ext';
    final bytes = await file.readAsBytes();
    await _client.storage.from(AppConstants.productImagesBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: file.mimeType ?? 'image/jpeg'),
        );
    return _client.storage.from(AppConstants.productImagesBucket).getPublicUrl(path);
  }

  Future<void> saveModel({
    String? id,
    required String name,
    String? imageUrl,
    required bool isActive,
    required List<SellStorage> storages,
  }) async {
    final payload = {'name': name, 'image_url': imageUrl, 'is_active': isActive};
    String modelId;

    if (id == null) {
      final row = await _client.from('sell_models').insert(payload).select('id').single();
      modelId = row['id'];
    } else {
      await _client.from('sell_models').update(payload).eq('id', id);
      modelId = id;
      await _client.from('sell_model_storages').delete().eq('model_id', modelId);
    }

    await _client.from('sell_model_storages').insert([
      for (var i = 0; i < storages.length; i++)
        {
          'model_id': modelId,
          'storage': storages[i].storage,
          'base_price': storages[i].basePrice,
          'sort_order': i,
        },
    ]);
  }

  Future<void> deleteModel(String id) async {
    await _client.from('sell_models').delete().eq('id', id);
  }

  // ---------------- السوبر أدمن: الأسئلة ----------------

  Future<void> saveQuestion({
    String? id,
    required String textEn,
    String? textAr,
    required String type,
    required bool isActive,
    required List<SellOption> options,
  }) async {
    final payload = {
      'text_en': textEn,
      'text_ar': (textAr == null || textAr.trim().isEmpty) ? null : textAr.trim(),
      'type': type,
      'is_active': isActive,
    };
    String questionId;

    if (id == null) {
      final last = await _client.from('sell_questions').select('sort_order').order('sort_order', ascending: false).limit(1);
      final next = (last as List).isEmpty ? 0 : ((last.first['sort_order'] as int?) ?? 0) + 1;
      final row = await _client.from('sell_questions').insert({...payload, 'sort_order': next}).select('id').single();
      questionId = row['id'];
    } else {
      await _client.from('sell_questions').update(payload).eq('id', id);
      questionId = id;
      await _client.from('sell_question_options').delete().eq('question_id', questionId);
    }

    await _client.from('sell_question_options').insert([
      for (var i = 0; i < options.length; i++) options[i].toInsert(questionId, i),
    ]);
  }

  Future<void> deleteQuestion(String id) async {
    await _client.from('sell_questions').delete().eq('id', id);
  }

  /// ترتيب الأسئلة (بتتسأل للزبون بنفس الترتيب)
  Future<void> reorderQuestions(List<String> idsInOrder) async {
    for (var i = 0; i < idsInOrder.length; i++) {
      await _client.from('sell_questions').update({'sort_order': i}).eq('id', idsInOrder[i]);
    }
  }

  Future<void> updateSpread(double percent) async {
    await _client.from('sell_settings').update({'range_spread_percent': percent}).eq('id', 1);
  }

  // ---------------- طلبات البيع ----------------

  Future<void> createRequest({
    required String customerId,
    required SellModel model,
    required SellStorage storage,
    required List<SellAnswerLine> lines,
    required double low,
    required double high,
  }) async {
    await _client.from('sell_requests').insert({
      'customer_id': customerId,
      'model_id': model.id,
      'model_name': model.name,
      'storage': storage.storage,
      'base_price': storage.basePrice,
      'answers': lines.map((e) => e.toJson()).toList(),
      'estimate_low': low,
      'estimate_high': high,
    });
  }

  /// كل طلبات البيع (للأدمن)
  Future<List<SellRequest>> getAllRequests() async {
    final data = await _client
        .from('sell_requests')
        .select('*, profiles!sell_requests_customer_id_fkey(full_name, phone)')
        .order('created_at', ascending: false);
    return (data as List).map((e) => SellRequest.fromJson(e)).toList();
  }

  Future<void> updateRequest({required String id, required String status, String? note}) async {
    await _client.from('sell_requests').update({
      'status': status,
      'admin_note': (note == null || note.trim().isEmpty) ? null : note.trim(),
      'handled_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}
