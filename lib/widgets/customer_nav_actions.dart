import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../providers/cart_provider.dart';
import '../screens/customer/cart_screen.dart';
import '../screens/customer/favorites_screen.dart';
import '../screens/customer/notifications_screen.dart';
import 'desktop_top_nav.dart';
import 'profile_menu_button.dart';

/// أيقونة السلة مع عدّاد المنتجات. نفس شكل أيقونات الهيدر.
class CartNavButton extends StatelessWidget {
  final double padding;
  final double iconSize;
  final Color background;
  final double horizontalMargin;

  const CartNavButton({
    super.key,
    this.padding = 9,
    this.iconSize = 19,
    this.background = AppTheme.offWhite,
    this.horizontalMargin = 4,
  });

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartProvider>().count;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
        child: Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          backgroundColor: AppTheme.gold,
          textColor: AppTheme.charcoal,
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(shape: BoxShape.circle, color: background),
            child: Icon(Icons.shopping_cart_outlined, size: iconSize, color: AppTheme.charcoal),
          ),
        ),
      ),
    );
  }
}

/// أيقونات الهيدر العلوي للعميل (إشعارات + مفضلة + سلة + بروفايل) - نفسها في كل الصفحات.
class CustomerNavActions extends StatelessWidget {
  const CustomerNavActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TopNavIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        ),
        TopNavIconButton(
          icon: Icons.favorite_border,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
        ),
        const CartNavButton(),
        const SizedBox(width: 6),
        const ProfileMenuButton(),
      ],
    );
  }
}

/// يحط الهيدر العلوي بتاع الموقع (لوجو MERCHNT + أيقونات) فوق الـ AppBar الأصلي للصفحة
/// على الويب/الديسكتوب. الـ AppBar الأصلي (زرار الرجوع والعنوان والأزرار) بيفضل زي ما هو تحته.
/// على الموبايل/التطبيق بيرجّع الـ AppBar زي ما هو من غير تغيير.
PreferredSizeWidget withCustomerNav(BuildContext context, AppBar pageBar) {
  if (!Responsive.isDesktop(context)) return pageBar;

  final nav = DesktopTopNav(
    selectedIndex: 0,
    onDestinationSelected: (_) {},
    items: const [],
    trailing: const CustomerNavActions(),
  );

  return PreferredSize(
    preferredSize: Size.fromHeight(nav.preferredSize.height + pageBar.preferredSize.height),
    child: Column(
      children: [
        SizedBox(height: nav.preferredSize.height, child: nav),
        SizedBox(height: pageBar.preferredSize.height, child: pageBar),
      ],
    ),
  );
}

/// الهيدر العلوي لوحده (من غير AppBar تحته) - للصفحات اللي مش عايزين فيها شريط تاني (زي تفاصيل المنتج).
PreferredSizeWidget customerTopNav() => DesktopTopNav(
      selectedIndex: 0,
      onDestinationSelected: (_) {},
      items: const [],
      trailing: const CustomerNavActions(),
    );