import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class AuthService {
  final _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone,
        'role': 'customer', // العميل العادي دايمًا، الأدمن بيتحدد يدويًا من الداتابيز
      },
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Profile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromJson(data);
  }

  Future<void> updateProfile({
    required String fullName,
    required String phone,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    if (user == null) return;

    await _client.from('profiles').update({
      'full_name': fullName,
      'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    }).eq('id', user.id);
  }
}
