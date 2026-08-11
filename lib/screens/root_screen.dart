import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import 'onboarding_screen.dart';
import 'welcome_screen.dart';
import 'customer/home_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool? _onboardingSeen;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _onboardingSeen = prefs.getBool('onboarding_seen') ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // استنى لحد ما نتأكد هل المستخدم شاف شاشات الترحيب قبل كده ولا لأ
    if (_onboardingSeen == null || auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!auth.isLoggedIn || auth.profile == null) {
      // أول مرة يفتح التطبيق -> يشوف شاشات الترحيب المتحركة، وبعدها كل مرة يروح على طول لشاشة تسجيل الدخول
      return _onboardingSeen! ? const WelcomeScreen() : const OnboardingScreen();
    }

    // التوجيه حسب الدور: أدمن يروح للوحة التحكم، عميل عادي يروح للواجهة الرئيسية
    return auth.isAdmin ? const AdminDashboardScreen() : const HomeScreen();
  }
}
