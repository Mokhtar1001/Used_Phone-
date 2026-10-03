import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ========================================================================
/// Merchnt Design System
/// مبني على البراند بوك: Charcoal (أساسي) + Gold (Accent نادر الاستخدام)
/// فوق سكيلة نيوترال دافية (White → Deep Gray).
/// Typography: Inter لواجهة الإنجليزي، Tajawal للعربي، بنفس الـ Type Scale.
/// ========================================================================
class AppTheme {
  // ---------------- Brand colors ----------------
  static const charcoal = Color(0xFF1C1C1C); // اللوجو، العناوين، النص الأساسي، الأزرار
  static const gold = Color(0xFFC9971F); // Accent نادر: بادچ، هايلايت، لحظة ثقة - أبدًا كخلفية

  // ---------------- Neutrals (دافية) ----------------
  static const pureWhite = Color(0xFFFFFFFF); // الخلفية الأساسية 62%
  static const offWhite = Color(0xFFF7F6F3); // خلفيات ثانوية: كروت وسكاشن
  static const lightGray = Color(0xFFE5E3DF); // حدود وفواصل وحالات معطلة
  static const midGray = Color(0xFF8C8A85); // تعليقات ونص ثانوي
  static const deepGray = Color(0xFF4A4846); // فقرات النص الأساسية

  // ---------------- Semantic (مش من البراند بوك، بتتماشى مع نفس الدفء) ----------------
  static const successColor = Color(0xFF3F7D58);
  static const errorColor = Color(0xFFB3432B);
  static const warningColor = Color(0xFFB3832B);

  // ---------------- Dark mode surfaces ----------------
  static const darkBg = Color(0xFF141414);
  static const darkSurface = Color(0xFF201F1D);
  static const darkBorder = Color(0xFF34332F);

  // ---------------- Legacy aliases ----------------
  // عشان الشاشات القديمة اللي لسه بتنادي على الأسامي دي متتكسرش لحد ما نعدلها واحدة واحدة
  static const primaryColor = charcoal;
  static const priceColor = charcoal;
  static const blackColor = charcoal;
  static const blackColor60 = midGray;
  static const blackColor40 = Color(0xFFB7B5B0);
  static const blackColor10 = lightGray;
  static const greyBg = offWhite;

  static const MaterialColor primaryMaterialColor = MaterialColor(0xFF1C1C1C, <int, Color>{
    50: Color(0xFFF2F2F2),
    100: Color(0xFFE0E0E0),
    200: Color(0xFFB8B8B8),
    300: Color(0xFF8F8F8F),
    400: Color(0xFF6E6E6E),
    500: Color(0xFF1C1C1C),
    600: Color(0xFF191919),
    700: Color(0xFF141414),
    800: Color(0xFF101010),
    900: Color(0xFF0A0A0A),
  });

  // ======================= Typography =======================
  // Type scale (البراند بوك): Display 34/Bold, H1 28/Bold, H2 22/SemiBold,
  // H3 18/SemiBold, Body Large 17/Reg, Body 15/Reg, Body Small 13/Reg, Caption 11/Medium.
  // الأوزان المسموحة بس: Regular(400) / Medium(500) / SemiBold(600) / Bold(700).
  static TextTheme _typeScale(bool isArabic, Color primaryText) {
    final base = isArabic ? GoogleFonts.tajawalTextTheme() : GoogleFonts.interTextTheme();

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
          fontSize: 34, fontWeight: FontWeight.w700, height: 40 / 34, color: primaryText),
      headlineLarge: base.headlineLarge?.copyWith(
          fontSize: 28, fontWeight: FontWeight.w700, height: 34 / 28, color: primaryText),
      headlineMedium: base.headlineMedium?.copyWith(
          fontSize: 22, fontWeight: FontWeight.w600, height: 28 / 22, color: primaryText),
      titleLarge: base.titleLarge?.copyWith(
          fontSize: 18, fontWeight: FontWeight.w600, height: 24 / 18, color: primaryText),
      titleMedium: base.titleMedium?.copyWith(
          fontSize: 15, fontWeight: FontWeight.w500, height: 22 / 15, color: primaryText),
      bodyLarge: base.bodyLarge?.copyWith(
          fontSize: 17, fontWeight: FontWeight.w400, height: 24 / 17, color: primaryText),
      bodyMedium: base.bodyMedium?.copyWith(
          fontSize: 15, fontWeight: FontWeight.w400, height: 22 / 15, color: primaryText),
      bodySmall: base.bodySmall?.copyWith(
          fontSize: 13, fontWeight: FontWeight.w400, height: 18 / 13, color: midGray),
      labelLarge: base.labelLarge?.copyWith(
          fontSize: 15, fontWeight: FontWeight.w500, color: primaryText),
      labelMedium: base.labelMedium?.copyWith(
          fontSize: 13, fontWeight: FontWeight.w500, color: midGray),
      labelSmall: base.labelSmall?.copyWith(
          fontSize: 11, fontWeight: FontWeight.w500, height: 14 / 11, color: midGray, letterSpacing: 0.4),
    );
  }

  static String? _fontFamily(bool isArabic) =>
      isArabic ? GoogleFonts.tajawal().fontFamily : GoogleFonts.inter().fontFamily;

  // ======================= Light theme =======================
  static ThemeData light({bool isArabic = false}) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: pureWhite,
        primaryColor: charcoal,
        primarySwatch: primaryMaterialColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: charcoal,
          brightness: Brightness.light,
          primary: charcoal,
          secondary: gold,
          error: errorColor,
          surface: pureWhite,
        ),
        textTheme: _typeScale(isArabic, charcoal),
        appBarTheme: AppBarTheme(
          backgroundColor: pureWhite,
          foregroundColor: charcoal,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
              fontFamily: _fontFamily(isArabic), fontSize: 18, fontWeight: FontWeight.w600, color: charcoal),
          iconTheme: const IconThemeData(color: charcoal),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: offWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: lightGray),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: pureWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: lightGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: lightGray),
          ),
          // Focus بلون Gold - الاستثناء الوحيد اللي Gold بيبقى فيه حدود بدل accent عادي،
          // عشان يوضح الحقل الوحيد النشط دلوقتي.
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: gold, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: errorColor, width: 1.3),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: errorColor, width: 1.6),
          ),
          hintStyle: const TextStyle(color: midGray),
          labelStyle: const TextStyle(color: deepGray, fontSize: 13, fontWeight: FontWeight.w500),
          floatingLabelStyle: const TextStyle(color: midGray, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.4),
          errorStyle: const TextStyle(color: errorColor, fontSize: 12, fontWeight: FontWeight.w500),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          // Primary: تعبئة كاملة شاركول، حواف دايرة بالكامل (Pill)، Gold مايتحطش كخلفية أبدًا
          style: ButtonStyle(
            shape: WidgetStateProperty.all(const StadiumBorder()),
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16, horizontal: 24)),
            elevation: WidgetStateProperty.all(0),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) return lightGray;
              if (states.contains(WidgetState.pressed)) return const Color(0xFF0E0E0E);
              return charcoal;
            }),
            foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.disabled) ? midGray : pureWhite),
            overlayColor: WidgetStateProperty.all(pureWhite.withValues(alpha: 0.08)),
            textStyle: WidgetStateProperty.all(
                TextStyle(fontFamily: _fontFamily(isArabic), fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          // Secondary: حدود شاركول بس، تتملى بلون خفيف وقت الضغط فقط
          style: ButtonStyle(
            shape: WidgetStateProperty.all(const StadiumBorder()),
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16, horizontal: 24)),
            side: WidgetStateProperty.resolveWith((states) => BorderSide(
                color: states.contains(WidgetState.disabled) ? lightGray : charcoal, width: 1.3)),
            backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.pressed) ? offWhite : Colors.transparent),
            foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.disabled) ? midGray : charcoal),
            textStyle: WidgetStateProperty.all(
                TextStyle(fontFamily: _fontFamily(isArabic), fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          // Tertiary: لينك نصي بس، تحته خط دايمًا في الوضع العادي (مافيش استخدام لل Gold كخلفية أبدًا)
          style: ButtonStyle(
            shape: WidgetStateProperty.all(const StadiumBorder()),
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 12, horizontal: 18)),
            backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.pressed) ? offWhite : Colors.transparent),
            foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.disabled) ? midGray : charcoal),
            textStyle: WidgetStateProperty.resolveWith((states) {
              final base = TextStyle(fontFamily: _fontFamily(isArabic), fontWeight: FontWeight.w600, fontSize: 15);
              final isFlat = states.contains(WidgetState.pressed) || states.contains(WidgetState.disabled);
              return isFlat
                  ? base
                  : base.copyWith(decoration: TextDecoration.underline, decorationColor: gold, decorationThickness: 1.6);
            }),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: const BorderSide(color: lightGray)),
          selectedColor: charcoal,
          backgroundColor: offWhite,
          labelStyle: const TextStyle(fontWeight: FontWeight.w500, color: charcoal),
          secondaryLabelStyle: const TextStyle(color: pureWhite, fontWeight: FontWeight.w500),
          side: const BorderSide(color: lightGray),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
        dividerTheme: const DividerThemeData(color: lightGray, thickness: 1, space: 1),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: pureWhite,
          elevation: 0,
          indicatorColor: charcoal.withValues(alpha: 0.08),
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
                fontFamily: _fontFamily(isArabic),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: states.contains(WidgetState.selected) ? charcoal : midGray,
              )),
          iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(color: states.contains(WidgetState.selected) ? charcoal : midGray)),
        ),
      );

  // ======================= Dark theme =======================
  static ThemeData dark({bool isArabic = false}) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        primaryColor: gold,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.dark,
          primary: gold,
          secondary: gold,
          surface: darkSurface,
          error: errorColor,
        ),
        textTheme: _typeScale(isArabic, pureWhite),
        appBarTheme: AppBarTheme(
          backgroundColor: darkBg,
          foregroundColor: pureWhite,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
              fontFamily: _fontFamily(isArabic), fontSize: 18, fontWeight: FontWeight.w600, color: pureWhite),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: darkBorder),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: gold, width: 1.4),
          ),
          hintStyle: TextStyle(color: midGray.withValues(alpha: 0.85)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: gold,
            foregroundColor: charcoal,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            textStyle: TextStyle(fontFamily: _fontFamily(isArabic), fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: pureWhite,
            side: const BorderSide(color: darkBorder),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: TextStyle(fontFamily: _fontFamily(isArabic), fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: gold),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: const BorderSide(color: darkBorder)),
          selectedColor: gold,
          backgroundColor: darkSurface,
          labelStyle: const TextStyle(color: pureWhite, fontWeight: FontWeight.w500),
          secondaryLabelStyle: const TextStyle(color: charcoal, fontWeight: FontWeight.w600),
          side: const BorderSide(color: darkBorder),
        ),
        dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1, space: 1),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: darkBg,
          elevation: 0,
          indicatorColor: gold.withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
                fontFamily: _fontFamily(isArabic),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: states.contains(WidgetState.selected) ? gold : midGray,
              )),
          iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(color: states.contains(WidgetState.selected) ? gold : midGray)),
        ),
      );
}
