// ملحوظة: الملف ده بديل مؤقت. لما تشغل المشروع لأول مرة بـ:
//   flutter pub get
//   flutter run
// فلاتر هيولد نسخة رسمية من الملف ده تلقائيًا من ملفات .arb الموجودة في lib/l10n/
// (بناءً على l10n.yaml في جذر المشروع). النسخة دي هنا بسيطة عشان الكود يشتغل فورًا
// حتى قبل أول build.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:convert';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      'appTitle': 'محل الموبيلات المستعملة',
      'login': 'تسجيل الدخول',
      'signup': 'إنشاء حساب',
    },
    'en': {
      'appTitle': 'Used Phones Store',
      'login': 'Login',
      'signup': 'Sign Up',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  String get appTitle => translate('appTitle');
  String get login => translate('login');
  String get signup => translate('signup');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
