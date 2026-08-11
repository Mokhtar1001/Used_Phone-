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

  // Shared prefs keys
  static const prefThemeMode = 'theme_mode';
  static const prefLocale = 'locale';
}
