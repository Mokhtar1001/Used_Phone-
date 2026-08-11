import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import 'edit_profile_screen.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';

/// شاشة إعدادات بستايل "Profile" بتاع template Shoplon:
/// كارت بروفايل فوق + أقسام معنونة (الحساب، التخصيص، الإعدادات)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(isArabic ? 'الإعدادات' : 'Settings'), automaticallyImplyLeading: false),
      body: ListView(
        children: [
          // كارت البروفايل
          ListTile(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              backgroundImage: auth.profile?.avatarUrl != null ? CachedNetworkImageProvider(auth.profile!.avatarUrl!) : null,
              child: auth.profile?.avatarUrl == null
                  ? Text((auth.profile?.fullName ?? '?').characters.first, style: const TextStyle(color: AppTheme.primaryColor))
                  : null,
            ),
            title: Text(isArabic ? 'أهلاً، ${auth.profile?.fullName ?? ''}' : 'Hi, ${auth.profile?.fullName ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(auth.profile?.phone ?? ''),
            trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 8),

          _SectionHeader(title: isArabic ? 'الحساب' : 'Account'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(border: Border.all(color: AppTheme.blackColor10), borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.favorite_border,
                  text: isArabic ? 'المفضلة' : 'Favorites',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  text: isArabic ? 'الإشعارات' : 'Notifications',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.person_outline,
                  text: isArabic ? 'تعديل البيانات الشخصية' : 'Edit Profile',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _SectionHeader(title: isArabic ? 'التخصيص' : 'Personalization'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(border: Border.all(color: AppTheme.blackColor10), borderRadius: BorderRadius.circular(14)),
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: Text(isArabic ? 'الوضع الليلي' : 'Dark Mode'),
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (v) => context.read<ThemeProvider>().toggleTheme(v),
            ),
          ),

          const SizedBox(height: 16),
          _SectionHeader(title: isArabic ? 'الإعدادات' : 'Settings'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(border: Border.all(color: AppTheme.blackColor10), borderRadius: BorderRadius.circular(14)),
            child: _SettingsTile(
              icon: Icons.language_outlined,
              text: isArabic ? 'اللغة' : 'Language',
              trailingText: isArabic ? 'العربية' : 'English',
              onTap: () => context.read<LocaleProvider>().toggleLocale(),
            ),
          ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => context.read<AuthProvider>().signOut(),
              icon: const Icon(Icons.logout, color: Colors.red, size: 18),
              label: Text(isArabic ? 'تسجيل الخروج' : 'Logout', style: const TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.blackColor60)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? trailingText;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.text, this.trailingText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 22),
      title: Text(text, style: const TextStyle(fontSize: 14)),
      trailing: trailingText != null
          ? Text(trailingText!, style: TextStyle(color: Colors.grey.shade500))
          : Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
    );
  }
}
