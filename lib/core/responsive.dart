import 'package:flutter/material.dart';

/// نقاط الكسر (Breakpoints) الموحّدة للتصميم المتجاوب.
/// بتستخدم في أي شاشة عايزة تفرّق بين شكل الموبايل وشكل الويب/الدسكتوب
/// (نافيجيشن، عدد أعمدة الشبكة، أقصى عرض للمحتوى...).
class Responsive {
  Responsive._();

  static const double mobileMax = 640; // أقل من كده = موبايل
  static const double tabletMax = 1024; // من mobileMax لحد كده = تابلت، وبعدها ديسكتوب
  static const double maxContentWidth = 1280; // أقصى عرض للمحتوى على شاشات الديسكتوب الكبيرة

  static bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < mobileMax;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobileMax && w < tabletMax;
  }

  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= tabletMax;

  /// عدد أعمدة شبكة المنتجات المناسب لعرض الشاشة/الحاوية الحالية
  static int productGridColumns(double width) {
    if (width >= 1400) return 5;
    if (width >= tabletMax) return 4;
    if (width >= mobileMax) return 3;
    return 2;
  }
}