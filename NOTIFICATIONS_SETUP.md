
# 🔔 دليل تفعيل الإشعارات الفعلية (خطوة بخطوة)

## 1. ثبّت Supabase CLI (لو مش متثبت)
```bash
npm install -g supabase
```

## 2. سجل دخول واربط مشروعك
```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```
`YOUR_PROJECT_REF` تلاقيه في رابط مشروعك على Supabase (الجزء اللي بعد `supabase.com/dashboard/project/`)

## 3. هات مفتاح Firebase Service Account
1. روح لـ Firebase Console → أيقونة الترس ⚙️ → **Project settings**
2. تبويب **Service accounts**
3. دوس **Generate new private key** → هينزلك ملف JSON
4. **متشاركش الملف ده مع حد** — فيه صلاحيات كاملة على مشروع Firebase بتاعك

## 4. سجّل الملف كـ Secret في Supabase (مش هتحطه في الكود أبدًا)
```bash
supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON="$(cat path/to/serviceAccountKey.json)"
```
(استبدل `path/to/serviceAccountKey.json` بمكان الملف اللي نزلته)

## 5. أضف عمود fcm_token للداتابيز
شغّل ملف `supabase/migration_add_fcm_token.sql` في **SQL Editor** بتاع Supabase.

## 6. انشر الـ Edge Function
```bash
supabase functions deploy send-chat-notification --no-verify-jwt
```
`--no-verify-jwt` لازمة هنا لأن اللي هيستدعي الـ function ده هو Supabase نفسه (Webhook) مش المستخدم.

## 7. اربط الـ Webhook (آخر خطوة)
1. روح للوحة تحكم Supabase → **Database** → **Webhooks**
2. دوس **Create a new webhook**
3. اختار:
   - **Table:** `messages`
   - **Events:** ✅ Insert بس
   - **Type:** Supabase Edge Functions
   - **Edge Function:** اختار `send-chat-notification`
4. احفظ

---

## ✅ اختبار إن كل حاجة شغالة

1. سجل دخول بحساب عميل وابعت رسالة في شات
2. روح للوحة تحكم Supabase → **Edge Functions** → `send-chat-notification` → **Logs**
3. المفروض تشوف الـ request واصل، ولو فيه خطأ هيظهر هنا بالتفصيل

لو محتاج تتأكد إن الجهاز بيسجل الـ FCM token فعلاً، افتح جدول `profiles` وشوف عمود `fcm_token` اتملى بعد أول تسجيل دخول.

---

## ملحوظة عن التكلفة
Supabase Edge Functions و Firebase Cloud Messaging الاتنين مجانين تمامًا للاستخدام العادي لمحل زي بتاعك (آلاف الرسائل شهريًا من غير أي تكلفة).
