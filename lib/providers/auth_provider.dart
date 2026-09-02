import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  Profile? _profile;
  bool _isLoading = true;

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _authService.isLoggedIn;
  bool get isAdmin => _profile?.isAdmin ?? false;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _authService.authStateChanges.listen((state) async {
      if (state.session != null) {
        await _loadProfile();
      } else {
        _profile = null;
        notifyListeners();
      }
    });

    if (_authService.isLoggedIn) {
      await _loadProfile();
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfile() async {
    _profile = await _authService.getCurrentProfile();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    await _loadProfile();
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _authService.signIn(email: email, password: password);
      await _loadProfile();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      await _loadProfile();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _profile = null;
    notifyListeners();
  }
}