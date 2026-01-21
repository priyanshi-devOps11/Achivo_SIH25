// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ================================
  // LOGIN (Only used for login flow)
  // ================================
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Starting login for: $email');

      // STEP 1: Attempt sign in
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null || response.session == null) {
        print('❌ No user/session returned');
        return AuthResult.error('Invalid credentials');
      }

      print('👤 User authenticated: ${response.user!.id}');
      print('📧 Email confirmed at: ${response.user!.emailConfirmedAt}');

      // STEP 2: Check email verification
      if (response.user!.emailConfirmedAt == null) {
        print('⚠️ Email not verified');
        await _supabase.auth.signOut();
        return AuthResult.error(
          'Please verify your email before logging in. Check your inbox for the verification link.',
        );
      }

      // STEP 3: Verify profile exists and is active
      final profile = await _supabase
          .from('profiles')
          .select('role, is_active, email_verified, email')
          .eq('id', response.user!.id)
          .maybeSingle();

      if (profile == null) {
        print('❌ No profile found');
        await _supabase.auth.signOut();
        return AuthResult.error(
            'Account profile not found. Please contact support or register again.');
      }

      print(
          '👤 Profile found - Role: ${profile['role']}, Active: ${profile['is_active']}');

      // STEP 4: Check if account is active
      if (profile['is_active'] != true || profile['email_verified'] != true) {
        print('⚠️ Account not active');
        await _supabase.auth.signOut();
        return AuthResult.error(
            'Your account is not activated. Please verify your email first.');
      }

      // STEP 5: Update last login
      try {
        await _supabase
            .from('profiles')
            .update({'last_login': DateTime.now().toIso8601String()}).eq(
            'id', response.user!.id);
      } catch (e) {
        print('⚠️ Could not update last_login: $e');
        // Don't fail login if this fails
      }

      print('✅ Login successful. Role: ${profile['role']}');

      return AuthResult.success(
        message: 'Login successful!',
        data: {
          'user': response.user,
          'session': response.session,
          'role': profile['role'],
        },
      );
    } on AuthException catch (e) {
      print('❌ Auth Exception: ${e.message}');

      if (e.message.contains('Invalid login credentials')) {
        return AuthResult.error(
            'Incorrect email or password. Please try again.');
      }

      if (e.message.contains('Email not confirmed')) {
        return AuthResult.error('Please verify your email before logging in.');
      }

      return AuthResult.error('Login failed: ${e.message}');
    } catch (e) {
      print('❌ Login error: $e');
      return AuthResult.error('Login failed: ${e.toString()}');
    }
  }

  // ================================
  // LOGOUT
  // ================================
  static Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      print('✅ Logged out successfully');
    } catch (e) {
      print('❌ Logout error: $e');
    }
  }

  // ================================
  // PASSWORD RESET
  // ================================
  static Future<AuthResult> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'achivo://reset-password',
      );
      return AuthResult.success(
          message: 'Password reset link sent to your email');
    } catch (e) {
      return AuthResult.error('Failed to send reset link: ${e.toString()}');
    }
  }

  // ================================
  // UPDATE PASSWORD
  // ================================
  static Future<AuthResult> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      return AuthResult.success(message: 'Password updated successfully');
    } catch (e) {
      return AuthResult.error('Failed to update password: ${e.toString()}');
    }
  }

  // ================================
  // GET CURRENT USER PROFILE
  // ================================
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final profile =
      await _supabase.from('profiles').select().eq('id', user.id).single();

      return profile;
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }

  // ================================
  // GET CURRENT USER
  // ================================
  static User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // ================================
  // CHECK IF LOGGED IN
  // ================================
  static bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }
}

// ================================
// AUTH RESULT CLASS
// ================================
class AuthResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  AuthResult._({
    required this.success,
    required this.message,
    this.data,
  });

  factory AuthResult.success({
    required String message,
    Map<String, dynamic>? data,
  }) {
    return AuthResult._(
      success: true,
      message: message,
      data: data,
    );
  }

  factory AuthResult.error(String message) {
    return AuthResult._(
      success: false,
      message: message,
    );
  }
}