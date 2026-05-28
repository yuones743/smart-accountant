import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService() : _client = Supabase.instance.client;

  Future<bool> sendOtp(String phoneNumber) async {
    try {
      await _client.auth.signInWithOtp(
        phone: phoneNumber,
        shouldCreateUser: true,
      );
      return true;
    } catch (e) {
      debugPrint('Failed to send OTP: $e');
      return false;
    }
  }

  Future<bool> verifyOtp(String phoneNumber, String token) async {
    try {
      await _client.auth.verifyOTP(
        phone: phoneNumber,
        token: token,
        type: OtpType.sms,
      );
      return true;
    } catch (e) {
      debugPrint('Failed to verify OTP: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
