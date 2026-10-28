import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/signup_screen.dart';
import 'auth_widgets.dart';
import 'google_sign_in_button.dart';

/// بوب أب تسجيل الدخول: إيميل + باسورد، أو جوجل، أو رابط إنشاء حساب.
/// بيرجّع true لو المستخدم سجّل دخول.
Future<bool> showSignInDialog(BuildContext context) async {
  final result = await showDialog<bool>(context: context, builder: (_) => const _SignInDialog());
  return result == true;
}

class _SignInDialog extends StatefulWidget {
  const _SignInDialog();

  @override
  State<_SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends State<_SignInDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final isArabic = context.read<LocaleProvider>().isArabic;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final error = await context.read<AuthProvider>().signIn(_emailController.text.trim(), _passwordController.text);
    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context, true);
      return;
    }

    final lower = error.toLowerCase();
    setState(() {
      _isLoading = false;
      if (lower.contains('email not confirmed')) {
        _error = isArabic
            ? 'لازم تأكد بريدك الإلكتروني الأول. افتح الإيميل ودوس على رابط التأكيد.'
            : 'Please confirm your email first. Check your inbox for the confirmation link.';
      } else if (lower.contains('invalid login credentials')) {
        _error = isArabic ? 'الإيميل أو كلمة المرور غلط' : 'Invalid email or password';
      } else {
        _error = error;
      }
    });
  }

  /// يقفل البوب أب وبعدين يفتح صفحة تانية فوق الصفحة الحالية
  void _closeAndPush(Widget page) {
    final nav = Navigator.of(context);
    nav.pop(false);
    nav.push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Dialog(
      backgroundColor: AppTheme.pureWhite,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 28),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: IconButton(
                      tooltip: isArabic ? 'إغلاق' : 'Close',
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close, size: 20, color: AppTheme.midGray),
                    ),
                  ),
                  Text(
                    isArabic ? 'تسجيل الدخول' : 'Sign in',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isArabic ? 'أهلًا بيك تاني في Merchnt.' : 'Welcome back to Merchnt.',
                    style: const TextStyle(fontSize: 14.5, color: AppTheme.midGray),
                  ),
                  const SizedBox(height: 24),
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
                    label: isArabic ? 'كلمة المرور' : 'Password',
                    bottom: 4,
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _isLoading ? null : _login(),
                      decoration: authInputDecoration(
                        isArabic ? 'اكتب كلمة المرور' : 'Enter your password',
                        suffix: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: AppTheme.midGray),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? (isArabic ? 'كلمة المرور قصيرة' : 'Password too short') : null,
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: () => _closeAndPush(const ForgotPasswordScreen()),
                      child: Text(isArabic ? 'نسيت كلمة المرور؟' : 'Forgot password?', style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.charcoal,
                      foregroundColor: AppTheme.pureWhite,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(50),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isArabic ? 'تسجيل الدخول' : 'Sign in'),
                  ),
                  AuthDivider(text: isArabic ? 'أو كمّل بـ' : 'or continue with'),
                  GoogleSignInButton(
                    isArabic: isArabic,
                    onSignedIn: () => Navigator.of(context).pop(true),
                    onError: (m) => setState(() => _error = m),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        isArabic ? 'مفيش عندك حساب؟ ' : 'New to Merchnt? ',
                        style: const TextStyle(fontSize: 14, color: AppTheme.deepGray),
                      ),
                      InkWell(
                        onTap: () => _closeAndPush(const SignupScreen()),
                        child: Text(
                          isArabic ? 'إنشاء حساب' : 'Sign up',
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
}
