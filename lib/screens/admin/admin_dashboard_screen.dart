import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.inventory_2_outlined), selectedIcon: const Icon(Icons.inventory_2), label: isArabic ? 'المنتجات' : 'Products'),
          NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), selectedIcon: const Icon(Icons.chat_bubble), label: isArabic ? 'المحادثات' : 'Chats'),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long), label: isArabic ? 'الطلبات' : 'Orders'),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: isArabic ? 'الإعدادات' : 'Settings'),
        ],
      ),
    );
  }
}
