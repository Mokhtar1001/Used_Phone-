# 📱 تطبيق محل الموبيلات المستعملة (Used Phones Store)

تطبيق Flutter كامل لمحل موبيلات مستعملة: عرض منتجات، شات مباشر بين العميل والأدمن مربوط بكل منتج، دفع بالفيزا، إشعارات، وضع ليلي، ودعم اللغتين عربي/إنجليزي.

## 📂 هيكل المشروع

```
lib/
├── main.dart                     # نقطة الدخول
├── core/
│   ├── constants.dart            # روابط Supabase (لازم تعدلها)
│   └── theme.dart                # الألوان + الوضع الليلي
├── models/                       # Profile, Product, Category, Chat, Message
├── services/                     # الاتصال بـ Supabase (Auth, Products, Chat, Notifications)
├── providers/                    # إدارة الحالة (Provider package)
├── screens/
│   ├── auth/                     # تسجيل دخول / حساب جديد
│   ├── customer/                 # الرئيسية، تفاصيل المنتج، الشات، الإعدادات، الدفع
│   └── admin/                    # لوحة تحكم، إضافة/تعديل منتج، كل الشاتات، الطلبات
├── widgets/                      # مكونات قابلة لإعادة الاستخدام
└── l10n/                         # ملفات الترجمة (عربي/إنجليزي)

supabase/
└── schema.sql                    # كل جداول الداتابيز + الصلاحيات (RLS) + الـ Storage buckets
```

## 🚀 خطوات التشغيل

### 1. تثبيت Flutter (لو لسه مش متثبت)
اتبع الشرح هنا: https://docs.flutter.dev/get-started/install

### 2. تثبيت الحزم
```bash
cd used_phones_app
flutter pub get
```

### 3. إعداد Supabase
1. اعمل حساب/مشروع جديد على https://supabase.com
2. روح لـ **SQL Editor** في لوحة تحكم Supabase، وانسخ محتوى ملف `supabase/schema.sql` بالكامل وشغّله.
3. **مهم:** شغّل كمان ملف `supabase/migration_all_features.sql` — فيه كل الجداول الجديدة (المفضلة، التقييمات، سجل المبيعات، عداد المشاهدات، تنبيه نزول السعر).
4. ده هيعمل كل الجداول، صلاحيات RLS، وبكتات الصور (Storage buckets) تلقائيًا.
5. روح لـ **Settings > API** وهات:
   - `Project URL`
   - `anon public key`
5. افتح `lib/core/constants.dart` وحط القيم دي بدل:
   ```dart
   static const supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
   static const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

### 4. تحويل حساب الأدمن (نفسك)
بعد ما تعمل حساب في التطبيق (Sign Up)، روح لـ Supabase → **Table Editor** → جدول `profiles`، ودور على صفك، وغيّر عمود `role` من `customer` لـ `admin` يدويًا. كده أول ما تسجل دخول هيوجهك للوحة التحكم مباشرة.

### 5. إعداد Firebase (للإشعارات فقط)
1. اعمل مشروع على https://console.firebase.google.com
2. ضيف تطبيق Android و iOS
3. نزّل `google-services.json` وحطه في `android/app/`
4. نزّل `GoogleService-Info.plist` وحطه في `ios/Runner/`
5. (اختياري لأول تشغيل) لو معندكش وقت تظبط الملفين دول دلوقتي، التطبيق هيشتغل عادي من غير إشعارات مؤقتًا.

### 6. توليد ملفات الترجمة الرسمية
```bash
flutter gen-l10n
```
ده هيحدث `lib/l10n/app_localizations.dart` تلقائيًا من ملفات `app_ar.arb` و `app_en.arb`.

### 7. تشغيل التطبيق
```bash
flutter run
```

## 💳 الدفع بالفيزا (Stripe / Paymob)

⚠️ **مهم جدًا:** أي مفتاح سري (Secret Key) لبوابة الدفع **متحطش في كود التطبيق أبدًا**. لازم:
1. اعمل حساب على [Stripe](https://stripe.com) أو [Paymob](https://paymob.com) (لو في مصر، Paymob بيدعم فيزا/ماستركارد محلي وأسهل في التفعيل).
2. اعمل **Supabase Edge Function** بتستقبل طلب الدفع من التطبيق، وتتكلم مع Stripe/Paymob من السيرفر (فيه المفتاح السري بأمان).
3. شاشة `lib/screens/customer/checkout_screen.dart` جاهزة بالتدفق (flow)، وعليك بس تفعّل استدعاء الـ Edge Function.

مستندات مفيدة:
- Stripe + Flutter: https://pub.dev/packages/flutter_stripe
- Paymob API: https://docs.paymob.com

## 🔔 الإشعارات (Push Notifications)

النظام شغال بـ FCM (Firebase Cloud Messaging) للإرسال، وSupabase لتخزين الإشعارات (in-app). عشان الإشعار يتبعت فعليًا وقت وصول رسالة شات جديدة، لازم تعمل **Supabase Edge Function** أو **Database Webhook** يتفعل تلقائيًا لما يتضاف صف جديد في جدول `messages`، ويبعت طلب لـ FCM API.

مرجع: https://supabase.com/docs/guides/functions

## ✨ الميزات الكاملة (اتضافت بعد المراجعة)

| # | الميزة | فين تلاقيها |
|---|---|---|
| 1 | Loading/Error states + زرار "حاول تاني" | الهوم، تفاصيل المنتج، لوحة الأدمن |
| 2 | Pull-to-refresh | الهوم، تفاصيل المنتج، الشات |
| 3 | عداد رسايل غير مقروءة | شاشة "محادثاتي" و"كل المحادثات" |
| 4 | Validation (صورة + سعر إجباري) | شاشة إضافة منتج |
| 5 | فلترة بالسعر (من - إلى) | زرار الفلتر (🎚️) في الهوم |
| 6 | مشاركة المنتج | زرار Share في تفاصيل المنتج |
| 7 | المفضلة (Favorites) | أيقونة ❤️ في الهوم + شاشة مستقلة |
| 8 | سجل المبيعات | أيقونة 🕐 في لوحة تحكم الأدمن |
| 9 | تقييمات العملاء | أسفل تفاصيل المنتج |
| 10 | تنبيه نزول السعر | تلقائي عن طريق SQL trigger |
| 11 | عداد مشاهدات لكل منتج | ظاهر في تفاصيل المنتج + كارت الأدمن |

## 🗄️ قاعدة البيانات (تحديث)

| الجدول | الوصف |
|---|---|
| `profiles` | بيانات المستخدمين (أدمن/عميل) |
| `categories` | أقسام الموبيلات (آيفون، سامسونج...) |
| `products` | المنتجات بكل تفاصيلها |
| `product_images` | صور كل منتج (أكتر من صورة) |
| `chats` | شات واحد لكل (منتج + عميل) |
| `messages` | رسايل كل شات |
| `notifications` | إشعارات داخل التطبيق |
| `orders` | طلبات الشراء والدفع |

## 🌐 اللغتين والوضع الليلي

- التبديل بين عربي/إنجليزي وبين الوضع الليلي/النهاري موجود في شاشة **الإعدادات**، وبيتحفظ تلقائيًا (SharedPreferences) عشان يفضل شغال حتى لو قفلت التطبيق.
- التطبيق بيدعم RTL تلقائيًا لما تختار عربي.

## 📦 الحزم المستخدمة (Packages)

| الحزمة | الاستخدام |
|---|---|
| `supabase_flutter` | الاتصال بالداتابيز، الأوث، والـ Storage |
| `firebase_messaging` | الإشعارات |
| `provider` | إدارة الحالة |
| `image_picker` | رفع صور المنتجات/الشات |
| `cached_network_image` | عرض الصور بكفاءة |
| `google_fonts` | خط Cairo للعربي |
| `timeago` | عرض "منذ 5 دقائق" وهكذا |

## ✅ الخطوات التالية المقترحة

1. اضبط بيانات Supabase و Firebase زي ما هو موضح فوق.
2. جرب تعمل حساب، حوّله لأدمن، وأضف أول منتج بصوره.
3. اعمل حساب تاني (عميل عادي) وجرب تدخل على المنتج وتدوس "شات".
4. لما تكون جاهز للدفع الحقيقي، اعمل Edge Function لـ Paymob/Stripe.
5. اعمل Edge Function كمان لإرسال push notification حقيقي عند وصول رسالة جديدة.

---
لو حصل أي خطأ في `flutter pub get` أو أي مشكلة تانية، ابعتلي رسالة الخطأ وهساعدك تحلها.
