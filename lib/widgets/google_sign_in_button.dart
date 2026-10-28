import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

const _googleLogo =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
    '<path fill="#4285F4" d="M23.52 12.27c0-.85-.08-1.67-.22-2.45H12v4.64h6.47c-.28 1.5-1.13 2.78-2.4 3.63v3h3.88c2.27-2.09 3.57-5.17 3.57-8.82z"/>'
    '<path fill="#34A853" d="M12 24c3.24 0 5.95-1.07 7.93-2.91l-3.88-3c-1.07.72-2.45 1.15-4.05 1.15-3.11 0-5.75-2.1-6.69-4.92H1.3v3.09C3.26 21.3 7.3 24 12 24z"/>'
    '<path fill="#FBBC05" d="M5.31 14.32c-.24-.72-.38-1.49-.38-2.28s.14-1.56.38-2.28V6.67H1.3C.47 8.29 0 10.1 0 12s.47 3.71 1.3 5.33l4.01-3.01z"/>'
    '<path fill="#EA4335" d="M12 4.75c1.76 0 3.34.6 4.58 1.79l3.44-3.44C17.94 1.19 15.24 0 12 0 7.3 0 3.26 2.7 1.3 6.67l4.01 3.05C6.25 6.9 8.89 4.75 12 4.75z"/>'
    '</svg>';

/// زرار "Continue with Google".
/// - على الويب: بيحوّل الصفحة لجوجل وبعدين بيرجع (الجلسة بتتسترجع لوحدها).
/// - على التطبيق: بيفتح المتصفح، ولما الجلسة توصل بالـ deep link بينادي [onSignedIn].
class GoogleSignInButton extends StatefulWidget {
  final bool isArabic;
  final VoidCallback? onSignedIn;
  final ValueChanged<String>? onError;
  const GoogleSignInButton({super.key, required this.isArabic, this.onSignedIn, this.onError});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _busy = false;
  StreamSubscription<AuthState>? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    final error = await context.read<AuthProvider>().signInWithGoogle();
    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      widget.onError?.call(widget.isArabic ? 'مقدرناش نبدأ تسجيل الدخول بجوجل، حاول تاني' : 'Could not start Google sign-in, please try again');
      return;
    }

    // على التطبيق الجلسة بتوصل بعد ما المتصفح يرجع: نستناها ونقفل الشاشات
    if (!kIsWeb) {
      await _sub?.cancel();
      _sub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
        if (state.session != null) {
          _sub?.cancel();
          if (mounted) widget.onSignedIn?.call();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _busy ? null : _start,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppTheme.pureWhite,
        foregroundColor: AppTheme.charcoal,
        minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: AppTheme.lightGray, width: 1.5),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      child: _busy
          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.string(_googleLogo, width: 18, height: 18),
                const SizedBox(width: 10),
                Text(widget.isArabic ? 'المتابعة بحساب جوجل' : 'Continue with Google'),
              ],
            ),
    );
  }
}
