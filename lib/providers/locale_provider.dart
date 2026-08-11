import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar'); // العربي هو اللغة الافتراضية
  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  LocaleProvider() {
    _loadLocale();
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
