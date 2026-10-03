import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import 'modern_nav_bar.dart' show ModernNavItem;

/// نافيجيشن علوي بشكل موقع ويب دسكتوب: لوجو على اليسار، روابط أفقية في النص،
/// وأيقونات/أفاتار على اليمين (trailing). بيستخدم بدل ModernNavBar (البوتوم بار)
/// لما الشاشة تبقى بعرض ديسكتوب/تابلت كبير.
class DesktopTopNav extends StatelessWidget implements PreferredSizeWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ModernNavItem> items;
  final Widget? trailing;

  const DesktopTopNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.pureWhite,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 76,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.lightGray)),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: [
                    // اللوجو
                    const Text(
                      'Merchnt',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.charcoal,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.gold, shape: BoxShape.circle)),
                    const SizedBox(width: 48),
                    // روابط النافيجيشن
                    ...List.generate(items.length, (i) {
                      final item = items[i];
                      final selected = i == selectedIndex;
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 4),
                        child: _TopNavLink(
                          label: item.label,
                          icon: selected ? item.selectedIcon : item.icon,
                          selected: selected,
                          onTap: () => onDestinationSelected(i),
                        ),
                      );
                    }),
                    const Spacer(),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopNavLink extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TopNavLink({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  State<_TopNavLink> createState() => _TopNavLinkState();
}

class _TopNavLinkState extends State<_TopNavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected || _hovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SizedBox(
            height: 76,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 18, color: active ? AppTheme.charcoal : AppTheme.midGray),
                    const SizedBox(width: 7),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                        color: active ? AppTheme.charcoal : AppTheme.midGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 2,
                  width: widget.selected ? 22 : 0,
                  color: AppTheme.gold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// أيقونة صغيرة دائرية تستخدم في trailing الـ Top Nav (إشعارات/مفضلة/أفاتار)
class TopNavIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const TopNavIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.offWhite),
          child: Icon(icon, size: 19, color: AppTheme.charcoal),
        ),
      ),
    );
  }
}