import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/brand_mark.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/address_form.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/google_sign_in_button.dart';

// ألوان من ملف الـ HTML مش موجودة في AppTheme
const Color _subOnDark = Color(0xFFC9C7C2);
const Color _captionOnDark = Color(0xFFA8A6A1);

/// صفحة إنشاء الحساب (مبنية على Merchnt_SignUp_Page_Mockup.html):
/// على الشاشات العريضة (900+) لوحة براند غامقة + الفورم، وعلى الموبايل الفورم بس مع اللوجو فوق.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _agreed = false;
  bool _showAddress = false; // العنوان اختياري في التسجيل
  final _address = AddressFieldsController();
  bool _termsError = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final formOk = _formKey.currentState!.validate();
    // لازم يوافق على الشروط قبل ما ينشئ الحساب
    setState(() => _termsError = !_agreed);
    if (!formOk || !_agreed) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final error = await auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      // لو كتب عنوان بنحفظه (بيتنقل لجدول العناوين أول تسجيل دخول). لو سابه فاضي مفيش حاجة بتتبعت.
      address: _address.hasAny ? _address.toAddress().toJson() : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) {
      setState(() => _error = error);
    } else {
      _showConfirmEmailDialog();
    }
  }

  void _showConfirmEmailDialog() {
    final isArabic = context.read<LocaleProvider>().isArabic;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.mark_email_unread_outlined, size: 40),
        title: Text(isArabic ? 'أكّد بريدك الإلكتروني' : 'Confirm your email'),
        content: Text(
          isArabic
              ? 'بعتنالك رسالة تأكيد على إيميلك. لازم تدخل على البريد وتدوس على رابط التأكيد الأول، وبعد كده تقدر تسجل دخول.'
              : 'We sent a confirmation link to your email. Please check your inbox and confirm before logging in.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(isArabic ? 'تمام' : 'OK'),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── UI ─────────────────────────

  TextSpan _link(String text) => TextSpan(
        text: text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.charcoal,
          decoration: TextDecoration.underline,
          decorationColor: AppTheme.gold,
          decorationThickness: 1.5,
        ),
        // لسه مفيش صفحات للشروط والخصوصية: لما تتعمل حوّل الجزء ده لـ WidgetSpan بيفتحها
      );

  Widget _formPanel(bool isArabic, bool wide) {
    const textStyle = TextStyle(fontSize: 13, color: AppTheme.deepGray, height: 1.5);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: wide ? 32 : 24, vertical: wide ? 48 : 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!wide) ...[
                    const Row(
                      children: [
                        MerchntMark(size: 32),
                        SizedBox(width: 10),
                        Text('MERCHNT', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 36),
                  ],
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: InkWell(
                      // على الموقع: ارجع للمتجر (الرئيسية). على التطبيق: ارجع للشاشة اللي قبلها
                      onTap: () => kIsWeb ? Navigator.of(context).popUntil((r) => r.isFirst) : Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isArabic ? Icons.arrow_forward : Icons.arrow_back, size: 16, color: AppTheme.midGray),
                            const SizedBox(width: 6),
                            Text(
                              kIsWeb ? (isArabic ? 'الرجوع للمتجر' : 'Back to shop') : (isArabic ? 'رجوع' : 'Back'),
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.midGray),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Text(
                    isArabic ? 'إنشاء حساب جديد' : 'Create your account',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabic ? 'مش هتاخد أكتر من دقيقة.' : 'Takes less than a minute.',
                    style: const TextStyle(fontSize: 14.5, color: AppTheme.midGray),
                  ),
                  const SizedBox(height: 32),
                  authField(
                    label: isArabic ? 'الاسم بالكامل' : 'Full name',
                    child: TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: authInputDecoration(isArabic ? 'اكتب اسمك بالكامل' : 'Enter your full name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? (isArabic ? 'مطلوب' : 'Required') : null,
                    ),
                  ),
                  authField(
                    label: isArabic ? 'البريد الإلكتروني' : 'Email',
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: authInputDecoration('you@example.com'),
                      validator: (v) => (v == null || !v.contains('@')) ? (isArabic ? 'بريد إلكتروني غير صحيح' : 'Invalid email') : null,
                    ),
                  ),
                  authField(
                    label: isArabic ? 'رقم الهاتف' : 'Phone number',
                    hint: isArabic ? 'بنستخدمه لتحديثات التوصيل بس، ومش هنزعجك.' : "Used for delivery updates — we'll never spam you.",
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: authInputDecoration('+20 1XX XXX XXXX'),
                      validator: (v) => (v == null || v.length < 8) ? (isArabic ? 'رقم غير صحيح' : 'Invalid phone') : null,
                    ),
                  ),
                  authField(
                    label: isArabic ? 'كلمة المرور' : 'Password',
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) => _isLoading ? null : _signup(),
                      decoration: authInputDecoration(
                        isArabic ? 'اختار كلمة مرور' : 'Create a password',
                        suffix: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: AppTheme.midGray),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? (isArabic ? 'كلمة المرور قصيرة (6 أحرف على الأقل)' : 'Min 6 characters') : null,
                    ),
                  ),
                  // عنوان التوصيل (اختياري): هيتطلب وقت الشراء لو متسجلش هنا
                  InkWell(
                    onTap: () => setState(() => _showAddress = !_showAddress),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(_showAddress ? Icons.remove_circle_outline : Icons.add_circle_outline, size: 18, color: AppTheme.charcoal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isArabic ? 'إضافة عنوان التوصيل (اختياري)' : 'Add a delivery address (optional)',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showAddress) ...[
                    const SizedBox(height: 8),
                    Text(
                      isArabic
                          ? 'ممكن تسيبه وتضيفه وقت الشراء. وتقدر تحفظ عنوانين.'
                          : 'You can skip this and add it when you buy. You can save up to 2 addresses.',
                      style: const TextStyle(fontSize: 12, color: AppTheme.midGray),
                    ),
                    const SizedBox(height: 12),
                    AddressFields(controller: _address, isArabic: isArabic, requiredFields: false, showLabel: false),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 22,
                        width: 22,
                        child: Checkbox(
                          value: _agreed,
                          activeColor: AppTheme.charcoal,
                          onChanged: (v) => setState(() {
                            _agreed = v ?? false;
                            if (_agreed) _termsError = false;
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text.rich(
                            isArabic
                                ? TextSpan(style: textStyle, children: [
                                    const TextSpan(text: 'أوافق على '),
                                    _link('شروط الخدمة'),
                                    const TextSpan(text: ' و'),
                                    _link('سياسة الخصوصية'),
                                    const TextSpan(text: ' الخاصة بـ Merchnt.'),
                                  ])
                                : TextSpan(style: textStyle, children: [
                                    const TextSpan(text: "I agree to Merchnt's "),
                                    _link('Terms of Service'),
                                    const TextSpan(text: ' and '),
                                    _link('Privacy Policy'),
                                    const TextSpan(text: '.'),
                                  ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_termsError) ...[
                    const SizedBox(height: 6),
                    Text(
                      isArabic ? 'لازم توافق على الشروط الأول' : 'Please accept the terms to continue',
                      style: const TextStyle(fontSize: 12, color: AppTheme.errorColor),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.charcoal,
                      foregroundColor: AppTheme.pureWhite,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(52),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isArabic ? 'إنشاء حساب' : 'Create account'),
                  ),
                  AuthDivider(text: isArabic ? 'أو كمّل بـ' : 'or continue with'),
                  GoogleSignInButton(
                    isArabic: isArabic,
                    onSignedIn: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    onError: (m) => setState(() => _error = m),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        isArabic ? 'عندك حساب بالفعل؟ ' : 'Already have an account? ',
                        style: const TextStyle(fontSize: 14, color: AppTheme.deepGray),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          isArabic ? 'تسجيل الدخول' : 'Log in',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.charcoal,
                            decoration: TextDecoration.underline,
                            decorationColor: AppTheme.gold,
                            decorationThickness: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      backgroundColor: AppTheme.pureWhite,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final form = _formPanel(isArabic, wide);
          if (!wide) return SafeArea(child: form);
          return Row(
            children: [
              Expanded(flex: 42, child: _BrandPanel(isArabic: isArabic)),
              Expanded(flex: 58, child: form),
            ],
          );
        },
      ),
    );
  }
}

/// اللوحة الغامقة على الشمال (للشاشات العريضة بس)
class _BrandPanel extends StatelessWidget {
  final bool isArabic;
  const _BrandPanel({required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final items = isArabic
        ? const [
            ('متفحوص مش تخمين', 'كل موبايل بيتفحص وبيتقيّم قبل ما يتعرض'),
            ('ضمان حقيقي، من غير استثناءات', 'كل جهاز مضمون بنفس الطريقة بغض النظر عن الدرجة'),
            ('شوفنا بنفسك، واشتري أونلاين', 'فروع حقيقية تقدر تزورها، مش حساب مجهول'),
          ]
        : const [
            ('Verified, not guessed', "Every phone inspected and graded before it's listed"),
            ('Real warranty, no exceptions', 'Every device backed the same way, regardless of grade'),
            ('See us in person, buy online', 'Real stores you can visit, not an anonymous account'),
          ];

    return Container(
      color: AppTheme.charcoal,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              top: -160,
              right: -200,
              child: _Ring(size: 520, color: Colors.white.withValues(alpha: 0.08)),
            ),
            Positioned(
              bottom: -140,
              right: -120,
              child: _Ring(size: 340, color: AppTheme.gold.withValues(alpha: 0.15)),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(64),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MerchntMark(size: 38, main: Colors.white, accent: AppTheme.gold),
                        SizedBox(width: 12),
                        Text(
                          'MERCHNT',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppTheme.pureWhite),
                        ),
                      ],
                    ),
                    const SizedBox(height: 56),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Text(
                        isArabic ? 'موبايل مميز، من غير ما تغامر.' : 'A premium phone, without the leap of faith.',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.25, color: AppTheme.pureWhite),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Text(
                        isArabic
                            ? 'اعمل حساب وابدأ تتصفح موبايلات مستعملة متفحوصة ومتقيّمة، وتابع طلباتك من الدفع لحد التسليم.'
                            : 'Create an account to start browsing graded, verified pre-owned phones — and track your orders from checkout to delivery.',
                        style: const TextStyle(fontSize: 16, height: 1.6, color: _subOnDark),
                      ),
                    ),
                    const SizedBox(height: 40),
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 20),
                      _TrustItem(title: items[i].$1, subtitle: items[i].$2),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double size;
  final Color color;
  const _Ring({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color)),
      );
}

class _TrustItem extends StatelessWidget {
  final String title;
  final String subtitle;
  const _TrustItem({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.gold.withValues(alpha: 0.15)),
          child: const Icon(Icons.check, size: 13, color: AppTheme.gold),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppTheme.pureWhite)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: _captionOnDark)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
