import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Theme مأخوذ من ألوان template "Shoplon" (E-commerce Flutter UI):
/// بنفسجي مميز كلون أساسي، أزرار بحواف دايرة متوسطة، وكروت نضيفة بسيطة.
class AppTheme {
  static const primaryColor = Color(0xFF7B61FF); // البنفسجي الأساسي من الـ template
  static const priceColor = Color(0xFF31B0D8); // لون السعر (أزرق فاتح مميز)
  static const errorColor = Color(0xFFFF4848);
  static const blackColor = Color(0xFF16161E);
  static const blackColor60 = Color(0xFF737378);
  static const blackColor40 = Color(0xFFA2A2A5);
  static const blackColor10 = Color(0xFFE8E8E9);
  static const greyBg = Color(0xFFF8F8F9);

  static const MaterialColor primaryMaterialColor = MaterialColor(0xFF7B61FF, <int, Color>{
    50: Color(0xFFEFECFF),
    100: Color(0xFFD7D0FF),
    200: Color(0xFFBDB0FF),
    300: Color(0xFFA390FF),
    400: Color(0xFF8F79FF),
    500: Color(0xFF7B61FF),
    600: Color(0xFF7359FF),
    700: Color(0xFF684FFF),
    800: Color(0xFF5E45FF),
    900: Color(0xFF6C56DD),
  });

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: primaryColor,
        primarySwatch: primaryMaterialColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
          primary: primaryColor,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(bodyColor: blackColor),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: blackColor,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: blackColor10),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: greyBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: const BorderSide(color: primaryColor),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          selectedColor: primaryColor,
          backgroundColor: greyBg,
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: primaryColor.withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11)),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1C1C25),
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1C1C25),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF2A2A35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A35),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          selectedColor: primaryColor,
          backgroundColor: const Color(0xFF2A2A35),
          side: BorderSide.none,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF1C1C25),
          elevation: 0,
        ),
      );
}
