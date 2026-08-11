import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
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
    );

    setState(() => _isLoading = false);
    if (error != null) {
      setState(() => _error = error);
    } else if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(isArabic ? 'إنشاء حساب جديد' : 'Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), shape: BoxShape.circle),
                    child: const Icon(Icons.person_add_alt_1_rounded, size: 40, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isArabic ? 'خلينا نبدأ' : "Let's get started",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: isArabic ? 'الاسم بالكامل' : 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? (isArabic ? 'مطلوب' : 'Required') : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: isArabic ? 'رقم الهاتف' : 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  validator: (v) => (v == null || v.length < 8) ? (isArabic ? 'رقم غير صحيح' : 'Invalid phone') : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: isArabic ? 'البريد الإلكتروني' : 'Email',
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
                  validator: (v) => (v == null || v.length < 6) ? (isArabic ? 'كلمة المرور قصيرة (6 أحرف على الأقل)' : 'Min 6 characters') : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isArabic ? 'إنشاء حساب' : 'Sign Up'),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(isArabic ? 'لديك حساب بالفعل؟' : 'Already have an account?'),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(isArabic ? 'تسجيل الدخول' : 'Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
