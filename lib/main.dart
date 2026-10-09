import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'firebase_options.dart'; // ⚠️ هيتعمل تلقائيًا بعد ما تشغل flutterfire configure
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/product_provider.dart';
import 'providers/compare_provider.dart';
import 'providers/cart_provider.dart';
import 'services/notification_service.dart';
import 'screens/root_screen.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. تهيئة Supabase (الداتابيز + الأوث + الـ storage)
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // 1.5 تهيئة بيانات التاريخ لـ intl (أسامي الشهور/الأيام بالعربي والإنجليزي)
  // من غيرها DateFormat بأسماء زي 'EEEE'/'MMMM' بيرمي Exception لو اللغة مش 'en'
  await initializeDateFormatting('ar');
  await initializeDateFormatting('en');

  // 2. تهيئة Firebase (بنستخدمه للإشعارات بس - FCM)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // لو مفيش ملفات google-services.json / GoogleService-Info.plist لسه،
    // التطبيق هيشتغل عادي بس من غير إشعارات لحد ما تضيفهم
    debugPrint('Firebase init skipped: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CompareProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) {
          return MaterialApp(
            title: 'Merchant',
            debugShowCheckedModeBanner: false,
            // ⚠️ الوضع الليلي متعطّل مؤقتًا بطلب من الفريق لحد ما نخلص تصميم الويب.
            // لإرجاعه: رجّع السطر لـ themeMode: themeProvider.themeMode
            themeMode: ThemeMode.light,
            theme: AppTheme.light(isArabic: localeProvider.isArabic),
            darkTheme: AppTheme.dark(isArabic: localeProvider.isArabic),
            locale: localeProvider.locale,
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              // يضمن اتجاه RTL صح لما اللغة عربي
              return Directionality(
                textDirection: localeProvider.isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: child!,
              );
            },
            home: const _AppStartup(),
          );
        },
      ),
    );
  }
}

/// شاشة بدء التشغيل: بتهيئ خدمة الإشعارات بعد ما يبقى فيه مستخدم مسجل دخول
class _AppStartup extends StatefulWidget {
  const _AppStartup();

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      await NotificationService().initialize();
    } catch (e) {
      debugPrint('Notification init skipped: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const RootScreen();
  }
}