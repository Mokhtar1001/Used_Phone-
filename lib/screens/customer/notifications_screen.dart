import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final userId = context.read<AuthProvider>().profile?.id;
    if (userId == null) return;
    final notifications = await _notificationService.getMyNotifications(userId);
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  IconData _iconFor(String? type) {
    switch (type) {
      case 'price_drop':
        return Icons.trending_down_rounded;
      case 'new_message':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(isArabic ? 'الإشعارات' : 'Notifications')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(isArabic ? 'لا يوجد إشعارات دلوقتي' : 'No notifications yet', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final n = _notifications[i];
                      final isRead = n['is_read'] == true;
                      final title = isArabic ? n['title_ar'] : n['title_en'];
                      final body = isArabic ? n['body_ar'] : n['body_en'];
                      final createdAt = DateTime.tryParse(n['created_at'] ?? '');

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.transparent : AppTheme.primaryColor.withValues(alpha: 0.05),
                          border: Border.all(color: AppTheme.blackColor10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: Icon(_iconFor(n['type']), size: 18, color: AppTheme.primaryColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(body ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  if (createdAt != null) ...[
                                    const SizedBox(height: 6),
                                    Text(timeago.format(createdAt, locale: isArabic ? 'ar' : 'en'),
                                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
