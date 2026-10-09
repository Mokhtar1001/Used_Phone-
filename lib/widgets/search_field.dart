import 'package:flutter/material.dart';
import '../core/theme.dart';

/// حقل البحث - كومبوننت مستقل عن الـ Text Input العادي حسب البراند بوك:
/// - الحالة العادية: خلفية Off-White مليانة، من غير حدود، شكل Pill بالكامل.
/// - حالة الكتابة/الفوكس: خلفية بيضا وحدود شاركول (أسود) - مش Gold زي باقي الحقول،
///   لأن البحث مش "فورم فيلد" عادي.
class SearchField extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final Widget? trailing;

  const SearchField({
    super.key,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.controller,
    this.trailing,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      decoration: BoxDecoration(
        color: _focused ? AppTheme.pureWhite : AppTheme.offWhite,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _focused ? AppTheme.charcoal : Colors.transparent, width: 1.3),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        onTap: widget.onTap,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14, color: AppTheme.charcoal),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: AppTheme.midGray, fontSize: 14),
          prefixIcon: Icon(Icons.search, size: 20, color: _focused ? AppTheme.charcoal : AppTheme.midGray),
          suffixIcon: widget.trailing,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}