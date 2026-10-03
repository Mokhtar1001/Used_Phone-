import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// بيسجل زيارات الموقع/التطبيق بشكل صحيح:
/// - لو المستخدم مسجل دخول: بيتحسب حسب الإيميل، مرة واحدة بس كل 24 ساعة
///   (يعني كل ريفريش/لوج-إن تاني خلال نفس اليوم ميتحسبش زيارة جديدة).
/// - الأدمن مابيتحسبش في العداد خالص (الفلترة بتحصل في الـ Supabase function نفسها).
/// - الزوار اللي مش مسجلين دخول (Guests) بيتحسبوا بمعرّف جهاز عشوائي ثابت
///   محفوظ محليًا، بنفس قاعدة الـ 24 ساعة، عشان الريفريش المتكرر مايضخمش العدد.
///
/// الفلترة والتكرار بيتحصلوا فعليًا جوه دالة `log_visit` على مستوى الـ Supabase
/// (مش هنا في الكود)، عشان ميبقاش سهل التلاعب بالعدد من المتصفح.
class VisitService {
  final _client = Supabase.instance.client;
  static const _deviceIdKey = 'anonymous_device_id';

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceIdKey);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_deviceIdKey, id);
    }
    return id;
  }

  Future<void> logVisit() async {
    try {
      final user = _client.auth.currentUser;
      final String visitorKey;
      if (user != null && user.email != null) {
        visitorKey = user.email!;
      } else {
        visitorKey = 'guest_${await _getOrCreateDeviceId()}';
      }

      await _client.rpc('log_visit', params: {
        'p_user_id': user?.id,
        'p_email': user?.email,
        'p_visitor_key': visitorKey,
      });
    } catch (e) {
      // أي مشكلة (الدالة لسه مش متعملة في Supabase، أو مشكلة شبكة) - نتجاهلها بهدوء
      // عشان تتبع الزيارات ميوقفش المستخدم عن استخدام الموقع
      debugPrint('logVisit skipped: $e');
    }
  }
}
