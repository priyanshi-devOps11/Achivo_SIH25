// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ================================
  // STUDENT REGISTRATION
  // ================================
  static Future<AuthResult> registerStudent({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String fatherName,
    required String gender,
    required String phone,
    required String studentId,
    required String rollNumber,
    required String year,
    required int departmentId,
    required int instituteId,
    required int stateId,
    required int countryId,
  }) async {
    try {
      print('📝 Starting student registration for: $email');

      // STEP 1: Cleanup any orphaned profiles
      await _cleanupFailedRegistration(email);

      // STEP 2: Create auth user
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'achivo://email-verified',
      );

      if (authResponse.user == null) {
        return AuthResult.error('Failed to create account. Please try again.');
      }

      final userId = authResponse.user!.id;
      print('✅ Auth user created: $userId');

      // STEP 3: Call registration RPC
      final rpcResponse = await _supabase.rpc('register_student_rpc', params: {
        'p_user_id': userId,
        'p_email': email,
        'p_first_name': firstName,
        'p_last_name': lastName,
        'p_father_name': fatherName,
        'p_gender': gender,
        'p_phone': phone,
        'p_student_id': studentId,
        'p_roll_number': rollNumber,
        'p_year': year,
        'p_dept_id': departmentId,
        'p_inst_id': instituteId,
        'p_state_id': stateId,
        'p_country_id': countryId,
      });

      print('📦 RPC Response: $rpcResponse');

      // STEP 4: Handle RPC response
      if (rpcResponse == null) {
        print('❌ RPC returned null, cleaning up...');
        await _deleteAuthUser(userId);
        return AuthResult.error('Registration failed. Please try again.');
      }

      final result = rpcResponse as Map<String, dynamic>;

      if (result['success'] != true) {
        print('❌ RPC failed: ${result['error']}');
        await _deleteAuthUser(userId);
        return AuthResult.error(result['error'] ?? 'Registration failed');
      }

      // STEP 5: Sign out temporary session
      await _supabase.auth.signOut();

      final emailVerified = result['email_verified'] == true;
      print('✅ Registration successful. Email verified: $emailVerified');

      return AuthResult.success(
        message: emailVerified
            ? 'Account created! You can now log in.'
            : 'Account created! Please verify your email to activate your account.',
        data: {'email_verified': emailVerified},
      );
    } on AuthException catch (e) {
      print('❌ Auth Exception: ${e.message}');
      if (e.message.contains('already registered')) {
        return AuthResult.error('This email is already registered. Please use login.');
      }
      return AuthResult.error('Registration error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
      return AuthResult.error('Unexpected error: ${e.toString()}');
    }
  }

  // ================================
  // FACULTY REGISTRATION
  // ================================
  static Future<AuthResult> registerFaculty({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String gender,
    required String phone,
    required String facultyId,
    required int departmentId,
    required List<String> subjects,
    required int instituteId,
    required int stateId,
    required int countryId,
  }) async {
    try {
      print('📝 Starting faculty registration for: $email');

      await _cleanupFailedRegistration(email);

      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'achivo://email-verified',
      );

      if (authResponse.user == null) {
        return AuthResult.error('Failed to create account');
      }

      final userId = authResponse.user!.id;
      print('✅ Auth user created: $userId');

      final rpcResponse = await _supabase.rpc('register_faculty_rpc', params: {
        'p_user_id': userId,
        'p_email': email,
        'p_first_name': firstName,
        'p_last_name': lastName,
        'p_gender': gender,
        'p_phone': phone,
        'p_faculty_id': facultyId,
        'p_dept_id': departmentId,
        'p_subjects': subjects,
        'p_inst_id': instituteId,
        'p_state_id': stateId,
        'p_country_id': countryId,
      });

      if (rpcResponse == null) {
        await _deleteAuthUser(userId);
        return AuthResult.error('Registration failed');
      }

      final result = rpcResponse as Map<String, dynamic>;

      if (result['success'] != true) {
        await _deleteAuthUser(userId);
        return AuthResult.error(result['error'] ?? 'Registration failed');
      }

      await _supabase.auth.signOut();

      print('✅ Faculty registration successful');

      return AuthResult.success(
        message: 'Faculty account created! Please verify your email.',
        data: {'email_verified': result['email_verified']},
      );
    } catch (e) {
      print('❌ Faculty registration error: $e');
      return AuthResult.error(e.toString());
    }
  }

  // ================================
  // HOD REGISTRATION
  // ================================
  static Future<AuthResult> registerHOD({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String fatherName,
    required String gender,
    required String phone,
    required String hodId,
    required int departmentId,
    required int instituteId,
    required int stateId,
    required int countryId,
  }) async {
    try {
      print('📝 Starting HOD registration for: $email');

      await _cleanupFailedRegistration(email);

      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'achivo://email-verified',
      );

      if (authResponse.user == null) {
        return AuthResult.error('Failed to create account');
      }

      final userId = authResponse.user!.id;

      final rpcResponse = await _supabase.rpc('register_hod_rpc', params: {
        'p_user_id': userId,
        'p_email': email,
        'p_first_name': firstName,
        'p_last_name': lastName,
        'p_father_name': fatherName,
        'p_gender': gender,
        'p_phone': phone,
        'p_hod_id': hodId,
        'p_dept_id': departmentId,
        'p_inst_id': instituteId,
        'p_state_id': stateId,
        'p_country_id': countryId,
      });

      if (rpcResponse == null) {
        await _deleteAuthUser(userId);
        return AuthResult.error('Registration failed');
      }

      final result = rpcResponse as Map<String, dynamic>;

      if (result['success'] != true) {
        await _deleteAuthUser(userId);
        return AuthResult.error(result['error'] ?? 'Registration failed');
      }

      await _supabase.auth.signOut();

      return AuthResult.success(message: 'HOD account created! Please verify your email.');
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  // ================================
  // ADMIN REGISTRATION
  // ================================
  static Future<AuthResult> registerAdmin({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required int instituteId,
    required int stateId,
    required int countryId,
  }) async {
    try {
      print('📝 Starting admin registration for: $email');

      await _cleanupFailedRegistration(email);

      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'achivo://email-verified',
      );

      if (authResponse.user == null) {
        return AuthResult.error('Failed to create account');
      }

      final userId = authResponse.user!.id;

      final rpcResponse = await _supabase.rpc('register_admin_rpc', params: {
        'p_user_id': userId,
        'p_email': email,
        'p_first_name': firstName,
        'p_last_name': lastName,
        'p_phone': phone,
        'p_inst_id': instituteId,
        'p_state_id': stateId,
        'p_country_id': countryId,
      });

      if (rpcResponse == null) {
        await _deleteAuthUser(userId);
        return AuthResult.error('Registration failed');
      }

      final result = rpcResponse as Map<String, dynamic>;

      if (result['success'] != true) {
        await _deleteAuthUser(userId);
        return AuthResult.error(result['error'] ?? 'Registration failed');
      }

      await _supabase.auth.signOut();

      return AuthResult.success(message: 'Admin account created! Please verify your email.');
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  // ================================
  // LOGIN
  // ================================
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Starting login for: $email');

      // Attempt sign in
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return AuthResult.error('Invalid credentials');
      }

      print('👤 User authenticated: ${response.user!.id}');

      // Check email verification
      if (response.user!.emailConfirmedAt == null) {
        await _supabase.auth.signOut();
        return AuthResult.error(
          'Please verify your email before logging in. Check your inbox for the verification link.',
        );
      }

      // Check if profile exists and is active
      final profile = await _supabase
          .from('profiles')
          .select('role, is_active, email_verified')
          .eq('id', response.user!.id)
          .maybeSingle();

      if (profile == null) {
        await _supabase.auth.signOut();
        return AuthResult.error('Account profile not found. Please contact support.');
      }

      if (profile['is_active'] != true || profile['email_verified'] != true) {
        await _supabase.auth.signOut();
        return AuthResult.error('Your account is not activated. Please verify your email.');
      }

      // Update last login
      await _supabase
          .from('profiles')
          .update({'last_login': DateTime.now().toIso8601String()})
          .eq('id', response.user!.id);

      print('✅ Login successful. Role: ${profile['role']}');

      return AuthResult.success(
        message: 'Login successful!',
        data: {
          'user': response.user,
          'role': profile['role'],
        },
      );
    } on AuthException catch (e) {
      print('❌ Auth Exception: ${e.message}');
      if (e.message.contains('Invalid login credentials')) {
        return AuthResult.error('Incorrect email or password');
      }
      return AuthResult.error(e.message);
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
      return AuthResult.success(message: 'Password reset link sent to your email');
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
  // RESEND VERIFICATION EMAIL
  // ================================
  static Future<AuthResult> resendVerificationEmail(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      return AuthResult.success(message: 'Verification email sent! Check your inbox.');
    } catch (e) {
      return AuthResult.error('Failed to resend email: ${e.toString()}');
    }
  }

  // ================================
  // GET CURRENT USER PROFILE
  // ================================
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

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

  // ================================
  // PRIVATE HELPERS
  // ================================

  static Future<void> _cleanupFailedRegistration(String email) async {
    try {
      await _supabase.rpc('cleanup_failed_registration', params: {
        'user_email': email,
      });
      print('🧹 Cleanup completed for: $email');
    } catch (e) {
      print('⚠️ Cleanup warning: $e');
      // Don't throw - this is just cleanup
    }
  }

  static Future<void> _deleteAuthUser(String userId) async {
    try {
      // Note: This requires admin privileges
      // In production, you might need to use Supabase Admin API
      print('🗑️ Attempting to delete auth user: $userId');
    } catch (e) {
      print('⚠️ Failed to delete auth user: $e');
    }
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