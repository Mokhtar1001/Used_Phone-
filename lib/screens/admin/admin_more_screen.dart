import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/theme.dart';
import 'analytics_screen.dart';
import 'inspection_requests_admin_screen.dart';

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(isArabic ? 'أدوات إضافية' : 'More tools'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ToolCard(
            icon: Icons.bar_chart_rounded,
            title: isArabic ? 'الإحصائيات' : 'Analytics',
            subtitle: isArabic ? 'أكتر المنتجات مشاهدة، والإيرادات الشهرية' : 'Most viewed products and monthly revenue',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.fact_check_outlined,
            title: isArabic ? 'طلبات الفحص الفني' : 'Inspection Requests',
            subtitle: isArabic ? 'رد على طلبات فحص الأجهزة من العملاء' : 'Respond to customer device inspection requests',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InspectionRequestsAdminScreen())),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ToolCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppTheme.blackColor10), borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1), child: Icon(icon, color: AppTheme.primaryColor)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
