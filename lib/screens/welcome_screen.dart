import 'package:flutter/material.dart';
import '../providers/locale_provider.dart';
import '../core/theme.dart';
import 'package:provider/provider.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';

/// شاشة ترحيب أولى، بنفس روح تصميم "Findora Dream House":
/// صورة كبيرة فوق + شعار دائري + عنوان بارز + زرارين (أسود مليان + أبيض بحد)
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ⚠️ استبدل الصورة دي بصورة محل الموبيلات بتاعك (حطها في assets/images/)
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppTheme.primaryColor, Color(0xFF5E45FF)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.phone_iphone, size: 140, color: Colors.white38),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.smartphone, size: 36, color: AppTheme.primaryColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isArabic ? 'أهلاً بيك' : 'WELCOME',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isArabic
                        ? 'موبايلك الجديد (المستعمل) في مكان واحد بثقة وسهولة'
                        : 'Find your next phone, with trust and ease',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 36),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: Text(isArabic ? 'تسجيل الدخول' : 'Login'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: Text(isArabic ? 'إنشاء حساب' : 'Sign Up'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
