import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? _user;

  User get user {
    if (_user == null) {
      throw Exception('User is not logged in');
    }
    return _user!;
  }

  AuthProvider() {
    _initialize();
  }

  bool get isAuthenticated => _user != null;

  Future<void> _initialize() async {
    _user = _supabase.auth.currentUser;
    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _user = response.user;
      notifyListeners();
      return response.user;
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
      log("Error signing in: $e");
      return null;
    }
  }

  Future<User?> signUp(
    String email,
    String password,
    Map<String, dynamic> data,
  ) async {
    try {
      AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
      _user = res.user;
      notifyListeners();
      return res.user;
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
      log("Error signing in: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
