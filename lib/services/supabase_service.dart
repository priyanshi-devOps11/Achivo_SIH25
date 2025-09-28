import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Generate and send OTP
  static Future<bool> sendOTP(String email) async {
    try {
      // Generate 6-digit OTP
      final otp = (Random().nextInt(900000) + 100000).toString();

      // Delete any existing OTP for this email
      await _client.from('otp_verifications').delete().eq('email', email);

      // Insert new OTP with 5-minute expiry
      await _client.from('otp_verifications').insert({
        'email': email,
        'otp_code': otp,
        'expires_at':
            DateTime.now().add(Duration(minutes: 5)).toIso8601String(),
      });

      // In a real app, you would send this OTP via email service
      // For now, we'll just print it to console for testing
      print('OTP for $email: $otp');

      return true;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  // Verify OTP
  static Future<bool> verifyOTP(String email, String otp) async {
    try {
      final response = await _client
          .from('otp_verifications')
          .select()
          .eq('email', email)
          .eq('otp_code', otp)
          .gt('expires_at', DateTime.now().toIso8601String())
          .eq('verified', false);

      if (response.isEmpty) {
        return false;
      }

      // Mark OTP as verified
      await _client
          .from('otp_verifications')
          .update({'verified': true})
          .eq('email', email)
          .eq('otp_code', otp);

      return true;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  // Admin Registration
  static Future<Map<String, dynamic>> registerAdmin({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String instituteId,
    required String country,
    required String state,
    required String institute,
  }) async {
    try {
      // Create auth user
      final AuthResponse authResponse = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return {'success': false, 'message': 'Failed to create user account'};
      }

      // Create user profile
      await _client.from('user_profiles').insert({
        'id': authResponse.user!.id,
        'full_name': fullName,
        'phone': phone,
        'role': 'admin',
        'institute_id': instituteId,
        'country': country,
        'state': state,
        'institute': institute,
        'email_verified': true,
      });

      return {'success': true, 'user': authResponse.user};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // HOD Registration
  static Future<Map<String, dynamic>> registerHOD({
    required String fullName,
    required String email,
    required String password,
    required String fatherName,
    required String gender,
    required String phone,
    required String hodId,
    required String department,
    required String country,
    required String state,
    required String institute,
  }) async {
    try {
      final AuthResponse authResponse = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return {'success': false, 'message': 'Failed to create user account'};
      }

      await _client.from('user_profiles').insert({
        'id': authResponse.user!.id,
        'full_name': fullName,
        'father_name': fatherName,
        'gender': gender,
        'phone': phone,
        'role': 'hod',
        'hod_id': hodId,
        'department': department,
        'country': country,
        'state': state,
        'institute': institute,
        'email_verified': true,
      });

      return {'success': true, 'user': authResponse.user};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Faculty Registration
  static Future<Map<String, dynamic>> registerFaculty({
    required String fullName,
    required String email,
    required String password,
    required String fatherName,
    required String gender,
    required String phone,
    required String facultyId,
    required List<String> subjects,
    required String country,
    required String state,
    required String institute,
  }) async {
    try {
      final AuthResponse authResponse = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return {'success': false, 'message': 'Failed to create user account'};
      }

      await _client.from('user_profiles').insert({
        'id': authResponse.user!.id,
        'full_name': fullName,
        'father_name': fatherName,
        'gender': gender,
        'phone': phone,
        'role': 'faculty',
        'faculty_id': facultyId,
        'subjects': subjects,
        'country': country,
        'state': state,
        'institute': institute,
        'email_verified': true,
      });

      return {'success': true, 'user': authResponse.user};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Student Registration
  static Future<Map<String, dynamic>> registerStudent({
    required String fullName,
    required String email,
    required String password,
    required String fatherName,
    required String gender,
    required String phone,
    required String studentId,
    required String rollNumber,
    required String department,
    required String country,
    required String state,
    required String institute,
  }) async {
    try {
      final AuthResponse authResponse = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return {'success': false, 'message': 'Failed to create user account'};
      }

      await _client.from('user_profiles').insert({
        'id': authResponse.user!.id,
        'full_name': fullName,
        'father_name': fatherName,
        'gender': gender,
        'phone': phone,
        'role': 'student',
        'student_id': studentId,
        'roll_number': rollNumber,
        'department': department,
        'country': country,
        'state': state,
        'institute': institute,
        'email_verified': true,
      });

      return {'success': true, 'user': authResponse.user};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Login
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return {'success': false, 'message': 'Invalid credentials'};
      }

      // Get user profile
      final profileResponse = await _client
          .from('user_profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      return {
        'success': true,
        'user': response.user,
        'profile': profileResponse,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Sign Out
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Get Current User Profile
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .single();

      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Password Reset
  static Future<bool> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      print('Error resetting password: $e');
      return false;
    }
  }
}
