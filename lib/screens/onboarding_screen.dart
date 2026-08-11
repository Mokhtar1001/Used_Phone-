import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/locale_provider.dart';
import '../core/theme.dart';
import 'welcome_screen.dart';

class _OnboardData {
  final IconData icon;
  final String titleAr, titleEn, descAr, descEn;
  _OnboardData({required this.icon, required this.titleAr, required this.titleEn, required this.descAr, required this.descEn});
}

/// شاشات ترحيب متحركة بالسحب، بنفس نمط onboarding بتاع template "Shoplon"
/// (نقط تحت + زرار دائري بسهم يودي للصفحة اللي بعدها)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _pageIndex = 0;

  final List<_OnboardData> _pages = [
    _OnboardData(
      icon: Icons.phone_iphone_rounded,
      titleAr: 'لاقي الموبايل اللي بتدور عليه',
      titleEn: 'Find the phone\nyou\'re looking for',
      descAr: 'تشكيلة واسعة من الموبيلات المستعملة بحالات وأسعار مختلفة، مرتبة عشان تلاقي اللي يناسبك بسهولة.',
      descEn: 'A wide range of used phones in different conditions and prices, organized for easy browsing.',
    ),
    _OnboardData(
      icon: Icons.chat_bubble_rounded,
      titleAr: 'شات مباشر مع البائع',
      titleEn: 'Chat directly\nwith the seller',
      descAr: 'اسأل عن أي منتج مباشرة، الشات مربوط بالموبايل نفسه عشان تكون كل التفاصيل واضحة.',
      descEn: 'Ask about any product directly. The chat is linked to that specific phone.',
    ),
    _OnboardData(
      icon: Icons.verified_rounded,
      titleAr: 'دفع آمن وسريع',
      titleEn: 'Fast & secure\npayment',
      descAr: 'اختار طريقة الدفع اللي تناسبك، وكمل عملية الشراء بأمان.',
      descEn: 'Choose the payment method that suits you and complete your purchase safely.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const WelcomeScreen()));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(isArabic ? 'تخطي' : 'Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (v) => setState(() => _pageIndex = v),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.icon, size: 90, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          isArabic ? page.titleAr : page.titleEn,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isArabic ? page.descAr : page.descEn,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                children: [
                  ...List.generate(
                    _pages.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 6,
                        width: index == _pageIndex ? 20 : 6,
                        decoration: BoxDecoration(
                          color: index == _pageIndex ? AppTheme.primaryColor : AppTheme.blackColor10,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 56,
                    width: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_pageIndex < _pages.length - 1) {
                          _pageController.nextPage(curve: Curves.ease, duration: const Duration(milliseconds: 300));
                        } else {
                          _finish();
                        }
                      },
                      style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: EdgeInsets.zero),
                      child: Icon(isArabic ? Icons.arrow_back : Icons.arrow_forward),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
