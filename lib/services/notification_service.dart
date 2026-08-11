import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final _client = Supabase.instance.client;
  final _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // اطلب صلاحية الإشعارات
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // تهيئة local notifications (لعرض إشعار وقت التطبيق مفتوح)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // احفظ الـ FCM token في جدول profiles عشان تقدر تبعت إشعار للمستخدم ده لاحقًا
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveTokenToProfile(token);
    }
    _fcm.onTokenRefresh.listen(_saveTokenToProfile);

    // استقبال إشعار والتطبيق مفتوح (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
  }

  Future<void> _saveTokenToProfile(String token) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    // ملحوظة: لازم تضيف عمود fcm_token في جدول profiles لو عايز تستخدم ده
    await _client.from('profiles').update({'fcm_token': token}).eq('id', user.id);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? '',
      message.notification?.body ?? '',
      details,
    );
  }

  /// يسجل صف في جدول notifications (in-app notifications)
  /// إرسال الـ push الفعلي بيتم من سيرفر بسيط (Edge Function) لما يتحدث الجدول ده
  Future<void> createNotification({
    required String userId,
    required String titleAr,
    required String titleEn,
    required String bodyAr,
    required String bodyEn,
    required String type,
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'title_ar': titleAr,
      'title_en': titleEn,
      'body_ar': bodyAr,
      'body_en': bodyEn,
      'type': type,
    });
  }

  Future<List<Map<String, dynamic>>> getMyNotifications(String userId) async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}
