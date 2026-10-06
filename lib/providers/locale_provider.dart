import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

/// مؤقتًا: زرار تغيير اللغة مخفي، واللغة بتبدأ إنجليزي دايمًا.
/// لإرجاع الترجمة: خلّي kShowLanguageToggle = true و kRestoreSavedLocale = true
/// (وغيّر الافتراضي تحت لـ Locale('ar') لو عايز العربي يرجع هو الأساسي).
const bool kShowLanguageToggle = false;
const bool kRestoreSavedLocale = false;

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en'); // الإنجليزي هو اللغة الافتراضية (مؤقتًا)
  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  LocaleProvider() {
    // مؤقتًا منرجّعش اللغة المحفوظة عشان التطبيق يفتح إنجليزي دايمًا
    if (kRestoreSavedLocale) _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.prefLocale);
    if (saved != null) {
      _locale = Locale(saved);
      notifyListeners();
    }
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLocale, languageCode);
  }

  Future<void> toggleLocale() async {
    await setLocale(isArabic ? 'en' : 'ar');
  }
}