import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../screens/auth/login_screen.dart';

/// بيتأكد إن اليوزر مسجل دخول قبل تنفيذ أكشن معين (مفضلة / شات / شراء).
/// لو Guest (زي وضع تصفح الويب من غير تسجيل دخول)، بيطلعله بوتوم شيت بسيط
/// يشرحله إنه محتاج يسجل دخول، ولو دوس "تسجيل الدخول" بيوديه لشاشة اللوجين.
///
/// بيرجع true لو اليوزر بقى مسجل دخول (سواء كان مسجل أصلاً أو سجل دلوقتي)،
/// و false لو لسه Guest — يبقى المفروض الكود اللي نادى عليها يوقف هنا.
Future<bool> requireLogin(
  BuildContext context, {
  String? messageAr,
  String? messageEn,
}) async {
  final auth = context.read<AuthProvider>();
  if (auth.isLoggedIn) return true;

  final isArabic = context.read<LocaleProvider>().isArabic;

  final wantsLogin = await showModalBottomSheet<bool>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 40),
          const SizedBox(height: 14),
          Text(
            isArabic ? 'سجّل دخولك الأول' : 'Please log in first',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? (messageAr ?? 'محتاج تعمل حساب أو تسجل دخول عشان تكمل الخطوة دي')
                : (messageEn ?? 'You need to sign in or create an account to continue'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(sheetContext, true),
              child: Text(isArabic ? 'تسجيل الدخول' : 'Log in'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(sheetContext, false),
            child: Text(isArabic ? 'لسه لأ' : 'Not now'),
          ),
        ],
      ),
    ),
  );

  if (wantsLogin != true || !context.mounted) return false;

  await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  return context.mounted && context.read<AuthProvider>().isLoggedIn;
}
