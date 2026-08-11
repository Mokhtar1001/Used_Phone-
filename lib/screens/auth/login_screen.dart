import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/theme.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final error = await auth.signIn(_emailController.text.trim(), _passwordController.text);

    setState(() => _isLoading = false);
    if (error != null) {
      final isArabic = context.read<LocaleProvider>().isArabic;
      if (error.toLowerCase().contains('email not confirmed')) {
        setState(() => _error = isArabic
            ? 'لازم تأكد بريدك الإلكتروني الأول. افتح الإيميل ودوس على رابط التأكيد.'
            : 'Please confirm your email first. Check your inbox for the confirmation link.');
      } else if (error.toLowerCase().contains('invalid login credentials')) {
        setState(() => _error = isArabic ? 'الإيميل أو كلمة المرور غلط' : 'Invalid email or password');
      } else {
        setState(() => _error = error);
      }
    } else if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // رأس بنفس روح التمبلت: مساحة ملونة فوق بدل صورة ثابتة
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryColor, Color(0xFF5E45FF)],
                ),
              ),
              child: const Center(child: Icon(Icons.phone_iphone_rounded, size: 80, color: Colors.white)),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'أهلاً بعودتك!' : 'Welcome back!',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isArabic
                          ? 'سجل دخولك بنفس البيانات اللي كتبتها وقت إنشاء الحساب'
                          : 'Log in with the data you entered during registration.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: isArabic ? 'البريد الإلكتروني' : 'Email address',
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (v) => (v == null || !v.contains('@')) ? (isArabic ? 'بريد إلكتروني غير صحيح' : 'Invalid email') : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: isArabic ? 'كلمة المرور' : 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? (isArabic ? 'كلمة المرور قصيرة' : 'Password too short') : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                        child: Text(isArabic ? 'نسيت كلمة المرور؟' : 'Forgot password?'),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 4),
                      Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(isArabic ? 'تسجيل الدخول' : 'Log in'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(isArabic ? 'ليس لديك حساب؟' : "Don't have an account?"),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                          child: Text(isArabic ? 'إنشاء حساب' : 'Sign up'),
                        ),
                      ],
                    ),
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
