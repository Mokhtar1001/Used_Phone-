import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/responsive.dart';
import '../../widgets/modern_nav_bar.dart';
import '../../widgets/desktop_top_nav.dart';
import '../../widgets/profile_menu_button.dart';
import 'admin_home_screen.dart';
import 'admin_products_screen.dart';
import 'orders_screen.dart';
// ⚠️ تابي "المحادثات" و"الإعدادات" متخفيين مؤقتًا من لوحة تحكم الأدمن بطلب الفريق.
// لإرجاعهم: رجّع الاستيرادات دي:
// import 'admin_chats_screen.dart';
// import '../customer/settings_screen.dart';
// وضيفهم في pages[] و navItems[] تحت زي ما كانوا.

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final isDesktop = Responsive.isDesktop(context);

    final pages = const [
      AdminHomeScreen(),
      AdminProductsScreen(),
      OrdersScreen(),
    ];

    final navItems = [
      ModernNavItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: isArabic ? 'الرئيسية' : 'Dashboard'),
      ModernNavItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2, label: isArabic ? 'المنتجات' : 'Products'),
      ModernNavItem(icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: isArabic ? 'الطلبات' : 'Orders'),
    ];

    // نفس منطق شاشة العميل بالظبط: نافيجيشن علوي على الديسكتوب/الويب بدل الشريط السفلي
    if (isDesktop) {
      return Scaffold(
        appBar: DesktopTopNav(
          selectedIndex: _tabIndex,
          onDestinationSelected: (i) => setState(() => _tabIndex = i),
          items: navItems,
          trailing: const Row(mainAxisSize: MainAxisSize.min, children: [ProfileMenuButton()]),
        ),
        body: pages[_tabIndex],
      );
    }

    return Scaffold(
      body: pages[_tabIndex],
      bottomNavigationBar: ModernNavBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        items: navItems,
      ),
    );
  }
}