import 'package:flutter/material.dart';
import '../core/theme.dart';

/// عناصر مشتركة لصفحة التسجيل وبوب أب تسجيل الدخول (نفس شكل Merchnt_SignUp_Page_Mockup.html)

const Color authPlaceholder = Color(0xFFB5B3AD);

OutlineInputBorder _authBorder(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: 1.5),
    );

InputDecoration authInputDecoration(String hint, {Widget? suffix}) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: authPlaceholder, fontSize: 14.5),
      filled: true,
      fillColor: AppTheme.pureWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      suffixIcon: suffix,
      border: _authBorder(AppTheme.lightGray),
      enabledBorder: _authBorder(AppTheme.lightGray),
      focusedBorder: _authBorder(AppTheme.gold),
      errorBorder: _authBorder(AppTheme.errorColor),
      focusedErrorBorder: _authBorder(AppTheme.errorColor),
      errorStyle: const TextStyle(fontSize: 12, color: AppTheme.errorColor),
    );

/// حقل بلابل فوقه (وملاحظة صغيرة تحته اختياريًا)
Widget authField({required String label, required Widget child, String? hint, double bottom = 18}) {
  return Padding(
    padding: EdgeInsets.only(bottom: bottom),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 7),
        child,
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(hint, style: const TextStyle(fontSize: 12, color: AppTheme.midGray)),
        ],
      ],
    ),
  );
}

/// فاصل "or continue with"
class AuthDivider extends StatelessWidget {
  final String text;
  const AuthDivider({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          const Expanded(child: Divider(height: 1, color: AppTheme.lightGray)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(text, style: const TextStyle(fontSize: 12.5, color: AppTheme.midGray)),
          ),
          const Expanded(child: Divider(height: 1, color: AppTheme.lightGray)),
        ],
      ),
    );
  }
}
