class AppConstants {
  // ⚠️ استبدل القيم دي بمشروعك على Supabase (Settings > API)
  static const supabaseUrl = 'https://sugpqlbrrpxoelpkaopj.supabase.co';
  static const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN1Z3BxbGJycnB4b2VscGthb3BqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ4MTgwOTAsImV4cCI6MjEwMDM5NDA5MH0.aGbMALVXfq-yaILc08Bw-bh1yHe7MkeMs0t7MJD9s-w';

  // Storage buckets
  static const productImagesBucket = 'product-images';
  static const chatImagesBucket = 'chat-images';

  // Roles
  static const roleAdmin = 'admin';
  static const roleCustomer = 'customer';

  // Product status
  static const statusAvailable = 'available';
  static const statusReserved = 'reserved';
  static const statusSold = 'sold';

  // معاينة في المحل (Store visits) - عدّل المواعيد دي حسب مواعيد شغل المحل
  static const storeOpenHour = 11; // أول ميعاد بيبدأ الساعة كام
  static const storeCloseHour = 21; // المحل بيقفل الساعة كام (آخر ميعاد بيبدأ قبلها بمدة slot)
  static const visitSlotMinutes = 30; // مدة الميعاد الواحد بالدقايق
  static const visitMinLeadHours = 1; // أقل مدة بين دلوقتي والميعاد
  static const visitMaxDaysAhead = 14; // أقصى عدد أيام قدام ينفع يتحجز فيها
  static const storeClosedWeekdays = <int>{}; // أيام الإجازة، مثال: {DateTime.friday}
  // أقصى مدة لحجز التليفون للعميل (لأنه ممكن يتباع في المحل). لازم تتطابق مع interval '24 hours' في migration_store_visits.sql
  static const holdHours = 24;

  // تسجيل الدخول بجوجل (Supabase OAuth). الـ scheme ده لازم يكون مضاف في:
  //  - Supabase > Authentication > URL Configuration > Redirect URLs
  //  - android/app/src/main/AndroidManifest.xml و ios/Runner/Info.plist (متضاف)
  static const oauthRedirectUrl = 'io.supabase.merchnt://login-callback/';

  // Shared prefs keys
  static const prefThemeMode = 'theme_mode';
  static const prefLocale = 'locale';
}
