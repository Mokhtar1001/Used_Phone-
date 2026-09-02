import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/modern_nav_bar.dart';
import 'admin_products_screen.dart';
import 'admin_chats_screen.dart';
import 'orders_screen.dart';
import '../customer/settings_screen.dart';

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

    final pages = const [
      AdminProductsScreen(),
      AdminChatsScreen(),
      OrdersScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: pages[_tabIndex],
      bottomNavigationBar: ModernNavBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        items: [
          ModernNavItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2, label: isArabic ? 'المنتجات' : 'Products'),
          ModernNavItem(icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble, label: isArabic ? 'المحادثات' : 'Chats'),
          ModernNavItem(icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: isArabic ? 'الطلبات' : 'Orders'),
          ModernNavItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: isArabic ? 'الإعدادات' : 'Settings'),
        ],
      ),
    );
  }
}