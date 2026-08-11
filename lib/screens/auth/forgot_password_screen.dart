import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/locale_provider.dart';

/// شاشة استعادة كلمة المرور - بتبعت رابط إعادة تعيين على الإيميل
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _sent = false;

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(_emailController.text.trim());
      setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(isArabic ? 'استعادة كلمة المرور' : 'Reset Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mark_email_read_outlined, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      isArabic
                          ? 'بعتنالك رابط لإعادة تعيين كلمة المرور على إيميلك. افتح الرسالة واتبع التعليمات.'
                          : 'We sent a password reset link to your email. Check your inbox.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(isArabic ? 'رجوع لتسجيل الدخول' : 'Back to Login'),
                    ),
                  ],
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isArabic ? 'اكتب إيميلك' : 'Enter your email',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isArabic
                            ? 'هنبعتلك رابط تقدر تعمل بيه كلمة مرور جديدة'
                            : 'We\'ll send you a link to reset your password',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: isArabic ? 'البريد الإلكتروني' : 'Email address',
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: (v) => (v == null || !v.contains('@')) ? (isArabic ? 'بريد إلكتروني غير صحيح' : 'Invalid email') : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _send,
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(isArabic ? 'إرسال الرابط' : 'Send Link'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
