import 'package:flutter/foundation.dart' show debugPrint;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/inspection_request.dart';

/// معاينة في المحل بميعاد.
/// - العميل: بيحجز / بيلغي (عن طريق دوال Supabase عشان التحقق يتم على السيرفر).
/// - الأدمن: بيأكد / بيعدّل الميعاد / بيحجز التليفون للعميل / بيقفل الطلب.
class InspectionService {
  final _client = Supabase.instance.client;

  static const _customerSelect = '*, products(name_ar, name_en, status)';
  static const _adminSelect =
      '*, products(name_ar, name_en, status), profiles!inspection_requests_customer_id_fkey(full_name, phone)';

  // ======================= العميل =======================

  /// يحجز ميعاد معاينة. بيرمي PostgrestException برسالة زي active_visit_exists / invalid_time / product_sold
  Future<void> bookVisit({
    required String productId,
    required DateTime scheduledAt,
    required bool holdRequested,
    String? note,
  }) async {
    await _client.rpc('book_store_visit', params: {
      'p_product_id': productId,
      'p_scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'p_hold': holdRequested,
      'p_note': _clean(note),
    });
  }

  Future<void> cancelMyVisit(String requestId) async {
    await _client.rpc('cancel_store_visit', params: {'p_id': requestId});
  }

  Future<List<InspectionRequest>> getMyRequests(String customerId) async {
    final data = await _client
        .from('inspection_requests')
        .select(_customerSelect)
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => InspectionRequest.fromJson(e)).toList();
  }

  // ======================= الأدمن =======================

  /// الحجز أقصاه [AppConstants.holdHours] ساعة (التليفون ممكن يتباع في المحل)،
  /// فينفع نحجز بس لو ميعاد الزيارة جوه المدة دي.
  static bool withinHoldWindow(DateTime? when) =>
      when != null && when.isBefore(DateTime.now().add(const Duration(hours: AppConstants.holdHours)));

  static DateTime _newHoldExpiry() => DateTime.now().add(const Duration(hours: AppConstants.holdHours));

  /// يفك أي حجز عدّى مدته (بيرجّع التليفون available). مفيش مشكلة لو الدالة لسه متعملتش في Supabase.
  Future<void> releaseExpiredHolds() async {
    try {
      await _client.rpc('release_expired_holds');
    } catch (e) {
      debugPrint('release_expired_holds skipped: $e');
    }
  }

  Future<List<InspectionRequest>> getAllRequests() async {
    final data = await _client.from('inspection_requests').select(_adminSelect).order('created_at', ascending: false);
    return (data as List).map((e) => InspectionRequest.fromJson(e)).toList();
  }

  /// يأكد الميعاد. لو [hold] = true بيحجز التليفون (status = reserved) لمدة أقصاها 24 ساعة.
  /// بيرجّع false لو الأدمن طلب حجز بس مينفعش (التليفون مش متاح، أو الميعاد بعد أكتر من 24 ساعة) - الميعاد نفسه اتأكد برضه.
  Future<bool> confirmVisit(InspectionRequest r, {required bool hold, String? adminNote}) async {
    var held = r.productHeld;
    var expires = r.holdExpiresAt;

    if (hold && !held && withinHoldWindow(r.scheduledAt)) {
      held = await _holdProduct(r.productId);
      if (held) expires = _newHoldExpiry();
    }
    if (!hold && held) {
      await _releaseProduct(r.productId);
      held = false;
    }
    if (!held) expires = null;

    await _update(r.id, {
      'status': 'confirmed',
      'product_held': held,
      'hold_expires_at': expires?.toUtc().toIso8601String(),
      'admin_note': _clean(adminNote),
    });

    final when = r.scheduledAt;
    if (when != null) {
      await _notify(
        r,
        titleAr: 'تم تأكيد ميعاد المعاينة',
        titleEn: 'Your store visit is confirmed',
        bodyAr: 'ميعادك ${_fmt(when, 'ar')} في المحل${held ? ' وحجزنا لك التليفون لمدة ${AppConstants.holdHours} ساعة' : ''}.',
        bodyEn: 'See you ${_fmt(when, 'en')} at the store${held ? ". We're holding the phone for you for ${AppConstants.holdHours} hours" : ''}.',
      );
    }
    return !hold || held;
  }

  /// يعدّل الميعاد. لو التليفون محجوز والميعاد الجديد بعد انتهاء الحجز، الحجز بيتفك.
  /// بيرجّع true لو الحجز اتفك.
  Future<bool> rescheduleVisit(InspectionRequest r, DateTime newTime) async {
    final values = <String, dynamic>{'scheduled_at': newTime.toUtc().toIso8601String()};
    var released = false;

    if (r.productHeld) {
      final limit = r.holdExpiresAt ?? _newHoldExpiry();
      if (newTime.isAfter(limit)) {
        await _releaseProduct(r.productId);
        values['product_held'] = false;
        values['hold_expires_at'] = null;
        released = true;
      }
    }

    await _update(r.id, values);
    await _notify(
      r,
      titleAr: 'تم تعديل ميعاد المعاينة',
      titleEn: 'Your store visit time changed',
      bodyAr: 'الميعاد الجديد: ${_fmt(newTime, 'ar')}.${released ? ' اتفك حجز التليفون لأن الحجز بيستمر ${AppConstants.holdHours} ساعة بس.' : ''}',
      bodyEn: 'New time: ${_fmt(newTime, 'en')}.${released ? ' The phone hold was released because holds last ${AppConstants.holdHours} hours only.' : ''}',
    );
    return released;
  }

  /// يحجز أو يفك حجز التليفون لطلب متأكد. الحجز 24 ساعة بس.
  /// بيرجّع false لو الحجز مش ممكن (التليفون مش متاح، أو الميعاد بعد أكتر من 24 ساعة).
  Future<bool> setHold(InspectionRequest r, bool hold) async {
    if (hold) {
      if (r.productHeld) return true;
      if (!withinHoldWindow(r.scheduledAt)) return false;
      if (!await _holdProduct(r.productId)) return false;
      await _update(r.id, {
        'product_held': true,
        'hold_expires_at': _newHoldExpiry().toUtc().toIso8601String(),
      });
      return true;
    }
    if (r.productHeld) await _releaseProduct(r.productId);
    await _update(r.id, {'product_held': false, 'hold_expires_at': null});
    return true;
  }

  /// إلغاء من الأدمن (بيفك الحجز لو التليفون محجوز)
  Future<void> cancelVisit(InspectionRequest r) async {
    if (r.productHeld) await _releaseProduct(r.productId);
    await _update(r.id, {'status': 'cancelled', 'product_held': false, 'hold_expires_at': null});
    await _notify(
      r,
      titleAr: 'تم إلغاء ميعاد المعاينة',
      titleEn: 'Your store visit was cancelled',
      bodyAr: 'اتلغى ميعاد المعاينة. تقدر تحجز ميعاد جديد في أي وقت.',
      bodyEn: 'Your visit was cancelled. You can book a new time anytime.',
    );
  }

  /// العميل ماجاش (بيفك الحجز)
  Future<void> markNoShow(InspectionRequest r) async {
    if (r.productHeld) await _releaseProduct(r.productId);
    await _update(r.id, {'status': 'no_show', 'product_held': false, 'hold_expires_at': null});
  }

  /// العميل جه واتعملت المعاينة. [keepHeld] = يسيب التليفون محجوز (لو العميل هيشتريه).
  Future<void> completeVisit(InspectionRequest r, {String? report, bool keepHeld = false}) async {
    final releasing = r.productHeld && !keepHeld;
    if (releasing) await _releaseProduct(r.productId);
    await _update(r.id, {
      'status': 'completed',
      'completed_at': DateTime.now().toUtc().toIso8601String(),
      'report': _clean(report),
      'product_held': keepHeld ? r.productHeld : false,
      // لو سيبه محجوز (العميل هيشتريه) مبنحطش مدة، الأدمن هو اللي بيقفل بيعه
      'hold_expires_at': null,
    });
  }

  // ======================= داخلي =======================

  Future<void> _update(String id, Map<String, dynamic> values) async {
    await _client.from('inspection_requests').update(values).eq('id', id);
  }

  /// يحجز التليفون لو لسه متاح بس (عشان ما نكتبش فوق منتج اتباع أو اتحجز لحد تاني)
  Future<bool> _holdProduct(String productId) async {
    final rows = await _client
        .from('products')
        .update({'status': 'reserved'})
        .eq('id', productId)
        .eq('status', 'available')
        .select('id');
    return (rows as List).isNotEmpty;
  }

  Future<void> _releaseProduct(String productId) async {
    await _client.from('products').update({'status': 'available'}).eq('id', productId).eq('status', 'reserved');
  }

  /// إشعار داخل التطبيق للعميل. لو فشل (RLS مثلًا) مبنوقفش العملية الأساسية.
  Future<void> _notify(
    InspectionRequest r, {
    required String titleAr,
    required String titleEn,
    required String bodyAr,
    required String bodyEn,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': r.customerId,
        'title_ar': titleAr,
        'title_en': titleEn,
        'body_ar': bodyAr,
        'body_en': bodyEn,
        'type': 'store_visit',
      });
    } catch (e) {
      debugPrint('store visit notification skipped: $e');
    }
  }

  String _fmt(DateTime d, String locale) => DateFormat('EEE d MMM, h:mm a', locale).format(d);

  String? _clean(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();
}
