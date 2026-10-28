import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../screens/customer/edit_profile_screen.dart';
import '../screens/customer/loyalty_screen.dart';
import '../screens/auth/signup_screen.dart';
import 'sign_in_dialog.dart';

/// زرار البروفايل في الهيدر/التوب نافيجيشن - بيتغير شكله حسب حالة تسجيل الدخول:
/// - لو المستخدم عامل دخول: أفتار بصورته الحقيقية (لو موجودة) + قائمة منسدلة
///   (تعديل بروفايل - نقاط الولاء - تغيير اللغة - تسجيل خروج).
/// - لو Guest: أيقونة شخص بقائمة منسدلة فيها "تسجيل الدخول" (بيفتح بوب أب) و"إنشاء حساب".
class ProfileMenuButton extends StatelessWidget {
  const ProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return _GuestMenu(isArabic: isArabic);
    }

    final profile = auth.profile;
    final avatarUrl = profile?.avatarUrl;

    return PopupMenuButton<String>(
      tooltip: isArabic ? 'حسابي' : 'Account',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppTheme.lightGray)),
      color: AppTheme.pureWhite,
      onSelected: (value) {
        switch (value) {
          case 'edit_profile':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            break;
          case 'loyalty':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LoyaltyScreen()));
            break;
          case 'language':
            context.read<LocaleProvider>().toggleLocale();
            break;
          case 'logout':
            context.read<AuthProvider>().signOut();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            profile?.fullName ?? (isArabic ? 'حسابي' : 'My Account'),
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.charcoal, fontSize: 13),
          ),
        ),
        const PopupMenuDivider(),
        _item('edit_profile', Icons.person_outline, isArabic ? 'تعديل البروفايل' : 'Edit Profile'),
        _item('loyalty', Icons.star_border_rounded, isArabic ? 'نقاط الولاء' : 'Loyalty Points'),
        // زرار الترجمة مخفي مؤقتًا - لإرجاعه: kShowLanguageToggle = true في locale_provider.dart
        if (kShowLanguageToggle) _item('language', Icons.translate_rounded, isArabic ? 'English' : 'العربية'),
        const PopupMenuDivider(),
        _item('logout', Icons.logout_rounded, isArabic ? 'تسجيل الخروج' : 'Logout', isDestructive: true),
      ],
      child: CircleAvatar(
        radius: 17,
        backgroundColor: AppTheme.charcoal,
        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? CachedNetworkImageProvider(avatarUrl) : null,
        child: (avatarUrl == null || avatarUrl.isEmpty) ? const Icon(Icons.person, size: 17, color: Colors.white) : null,
      ),
    );
  }

  PopupMenuItem<String> _item(String value, IconData icon, String label, {bool isDestructive = false}) =>
      _menuItem(value, icon, label, isDestructive: isDestructive);
}

PopupMenuItem<String> _menuItem(String value, IconData icon, String label, {bool isDestructive = false}) {
    final color = isDestructive ? AppTheme.errorColor : AppTheme.charcoal;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
}

/// أيقونة الشخص للـ Guest: بتنزل منها قائمة فيها "تسجيل الدخول" و"إنشاء حساب".
/// تسجيل الدخول بيفتح بوب أب (إيميل + باسورد / جوجل / إنشاء حساب).
class _GuestMenu extends StatelessWidget {
  final bool isArabic;
  const _GuestMenu({required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: isArabic ? 'حسابي' : 'Account',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppTheme.lightGray)),
      color: AppTheme.pureWhite,
      onSelected: (value) {
        if (value == 'signin') {
          showSignInDialog(context);
        } else if (value == 'signup') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            isArabic ? 'أهلًا بيك في Merchnt' : 'Welcome to Merchnt',
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.charcoal, fontSize: 13),
          ),
        ),
        const PopupMenuDivider(),
        _menuItem('signin', Icons.login_rounded, isArabic ? 'تسجيل الدخول' : 'Sign in'),
        _menuItem('signup', Icons.person_add_alt_1_outlined, isArabic ? 'إنشاء حساب' : 'Create account'),
      ],
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.offWhite),
        child: const Icon(Icons.person_outline_rounded, size: 20, color: AppTheme.charcoal),
      ),
    );
  }
}
