// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ================================
  // STUDENT REGISTRATION (FIXED)
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

      // STEP 1: Cleanup any orphaned profiles FIRST
      await _cleanupFailedRegistration(email);

      // STEP 2: Check if email already exists in profiles
      final existingProfile = await _supabase
          .from('profiles')
          .select('id, email')
          .eq('email', email)
          .maybeSingle();

      if (existingProfile != null) {
        print('⚠️ Profile already exists for email: $email');

        // Check if auth user exists for this profile
        try {
          final authUser = await _supabase.auth.admin.getUserById(existingProfile['id']);
          if (authUser != null) {
            return AuthResult.error('This email is already registered. Please use login instead.');
          }
        } catch (e) {
          // Auth user doesn't exist, clean up orphaned profile
          print('🧹 Cleaning up orphaned profile');
          await _supabase.from('profiles').delete().eq('id', existingProfile['id']);
        }
      }

      // STEP 3: Create auth user with metadata
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'achivo://email-verified',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'role': 'student',
          'department_id': departmentId,
          'institute_id': instituteId,
          'state_id': stateId,
          'country_id': countryId,
        },
      );

      if (authResponse.user == null) {
        print('❌ Auth signup failed - no user returned');
        return AuthResult.error('Failed to create account. Please try again.');
      }

      final userId = authResponse.user!.id;
      print('✅ Auth user created: $userId');

      // STEP 4: Wait a moment for trigger to create profile
      await Future.delayed(const Duration(milliseconds: 500));

      // STEP 5: Call registration RPC
      print('📞 Calling register_student_rpc');
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
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ RPC timeout');
          throw Exception('Registration timeout - please try again');
        },
      );

      print('📦 RPC Response: $rpcResponse');

      // STEP 6: Handle RPC response
      if (rpcResponse == null) {
        print('❌ RPC returned null');
        await _deleteAuthUser(userId);
        return AuthResult.error('Registration failed. Please try again.');
      }

      final result = rpcResponse as Map<String, dynamic>;

      if (result['success'] != true) {
        print('❌ RPC failed: ${result['error']}');
        await _deleteAuthUser(userId);
        return AuthResult.error(result['error'] ?? 'Registration failed');
      }

      // STEP 7: Sign out temporary session
      await _supabase.auth.signOut();

      final emailVerified = result['email_verified'] == true;
      print('✅ Registration successful. Email verified: $emailVerified');

      return AuthResult.success(
        message: result['message'] ?? (emailVerified
            ? 'Account created! You can now log in.'
            : 'Account created! Please verify your email to activate your account.'),
        data: {'email_verified': emailVerified},
      );
    } on AuthException catch (e) {
      print('❌ Auth Exception: ${e.message}');
      if (e.message.contains('already registered') || e.message.contains('User already registered')) {
        return AuthResult.error('This email is already registered. Please use login.');
      }
      return AuthResult.error('Registration error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
      return AuthResult.error('Unexpected error: ${e.toString()}');
    }
  }

  // ================================
  // LOGIN (IMPROVED)
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
        return AuthResult.error('Account profile not found. Please contact support or register again.');
      }

      print('👤 Profile found - Role: ${profile['role']}, Active: ${profile['is_active']}');

      // STEP 4: Check if account is active
      if (profile['is_active'] != true || profile['email_verified'] != true) {
        print('⚠️ Account not active');
        await _supabase.auth.signOut();
        return AuthResult.error('Your account is not activated. Please verify your email first.');
      }

      // STEP 5: Update last login
      try {
        await _supabase
            .from('profiles')
            .update({'last_login': DateTime.now().toIso8601String()})
            .eq('id', response.user!.id);
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
        return AuthResult.error('Incorrect email or password. Please try again.');
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
      print('🧹 Running cleanup for: $email');
      await _supabase.rpc('cleanup_failed_registration', params: {
        'user_email': email,
      });
      print('✅ Cleanup completed');
    } catch (e) {
      print('⚠️ Cleanup error (non-fatal): $e');
      // Don't throw - this is just cleanup
    }
  }

  static Future<void> _deleteAuthUser(String userId) async {
    try {
      print('🗑️ Attempting to delete auth user: $userId');
      // Sign out first
      await _supabase.auth.signOut();
      // Note: Actual deletion requires admin API or manual intervention
      // The database triggers should clean up the profile
    } catch (e) {
      print('⚠️ Could not delete auth user: $e');
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
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'role': 'faculty',
        },
      );

      if (authResponse.user == null) {
        return AuthResult.error('Failed to create account');
      }

      final userId = authResponse.user!.id;
      await Future.delayed(const Duration(milliseconds: 500));

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

      if (rpcResponse == null || rpcResponse['success'] != true) {
        await _deleteAuthUser(userId);
        return AuthResult.error(rpcResponse?['error'] ?? 'Registration failed');
      }

      await _supabase.auth.signOut();

      return AuthResult.success(
        message: 'Faculty account created! Please verify your email.',
        data: {'email_verified': rpcResponse['email_verified']},
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
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'role': 'hod',
        },
      );

      if (authResponse.user == null) {
        return AuthResult.error('Failed to create account');
      }

      final userId = authResponse.user!.id;
      await Future.delayed(const Duration(milliseconds: 500));

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

      if (rpcResponse == null || rpcResponse['success'] != true) {
        await _deleteAuthUser(userId);
        return AuthResult.error(rpcResponse?['error'] ?? 'Registration failed');
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
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'role': 'admin',
        },
      );

      if (authResponse.user == null) {
        return AuthResult.error('Failed to create account');
      }

      final userId = authResponse.user!.id;
      await Future.delayed(const Duration(milliseconds: 500));

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

      if (rpcResponse == null || rpcResponse['success'] != true) {
        await _deleteAuthUser(userId);
        return AuthResult.error(rpcResponse?['error'] ?? 'Registration failed');
      }

      await _supabase.auth.signOut();

      return AuthResult.success(message: 'Admin account created! Please verify your email.');
    } catch (e) {
      return AuthResult.error(e.toString());
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