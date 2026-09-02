import 'package:flutter/material.dart';
import '../core/theme.dart';

/// عنصر واحد في الـ Navigation Bar
class ModernNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const ModernNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Bottom Navigation Bar عائم بشكل مودرن (pill-style):
/// - كارت عائم بحواف دائرية كاملة وظل ناعم بدل الشريط العريض التقليدي
/// - العنصر المختار بس هو اللي بيظهر معاه خلفية ولون ولابل، والباقي أيقونة رمادية بس
/// - أنيميشن سلس (حجم + لون) بدل التغيير المفاجئ
/// بيستخدم نفس لون البراند (AppTheme.primaryColor) والخط بتاع التطبيق، فمحسوسش غريب عن باقي الشاشات.
class ModernNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ModernNavItem> items;

  const ModernNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark ? const Color(0xFF23232D) : Colors.white;
    final unselectedColor = isDark ? AppTheme.blackColor40 : AppTheme.blackColor40;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: barColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppTheme.blackColor)
                  .withValues(alpha: isDark ? 0.45 : 0.10),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = index == selectedIndex;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onDestinationSelected(index),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: selected ? 16 : 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primaryColor.withValues(alpha: isDark ? 0.22 : 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected ? item.selectedIcon : item.icon,
                          size: 22,
                          color: selected ? AppTheme.primaryColor : unselectedColor,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: selected
                              ? Padding(
                                  padding: const EdgeInsetsDirectional.only(start: 7),
                                  child: Text(
                                    item.label,
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
