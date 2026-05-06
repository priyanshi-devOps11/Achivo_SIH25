// lib/screens/auth_student_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'dart:math';

SupabaseClient get supabase => Supabase.instance.client;

class AuthStudentPage extends StatefulWidget {
  const AuthStudentPage({Key? key}) : super(key: key);

  @override
  State<AuthStudentPage> createState() => _AuthStudentPageState();
}

class _AuthStudentPageState extends State<AuthStudentPage>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late AnimationController _otpTimerController;

  late Animation<double> _backgroundAnimation;
  late Animation<double> _contentAnimation;

  bool _isLoading = false;
  bool _isLogin = false;
  bool _isOtpSent = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  String? selectedGender;
  String? selectedDepartment;
  String? selectedYear;
  String _captchaText = '';
  int _otpCountdown = 0;

  List<String> _departmentNames = [];
  Map<String, int> _departmentIdMap = {};
  bool _departmentsLoaded = false;

  Map<String, dynamic> _profileData = {};
  bool _isDataLoaded = false;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _rollNoController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _otpController = TextEditingController();
  final _captchaController = TextEditingController();

  final List<String> genders = ['Male', 'Female', 'Other'];
  final List<String> years = ['I', 'II', 'III', 'IV', 'V'];

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    _contentController = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this);
    _otpTimerController =
        AnimationController(duration: const Duration(seconds: 60), vsync: this);

    _backgroundAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
            parent: _backgroundController, curve: Curves.easeOut));
    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _contentController, curve: Curves.easeOut));

    _generateCaptcha();
    _fetchDepartments();
    _backgroundController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _contentController.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _profileData = args;
        _isDataLoaded = true;
      }
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    _otpTimerController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _studentIdController.dispose();
    _rollNoController.dispose();
    _fatherNameController.dispose();
    _otpController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA FETCHING
  // ============================================================

  Future<void> _fetchDepartments() async {
    try {
      final response = await supabase
          .from('departments')
          .select('id, name')
          .eq('is_active', true)
          .order('name', ascending: true);

      if (response is List) {
        final List<String> names = [];
        final Map<String, int> idMap = {};

        for (var dept in response) {
          final name = dept['name'] as String;
          final id = dept['id'] as int;
          names.add(name);
          idMap[name] = id;
        }

        setState(() {
          _departmentNames = names;
          _departmentIdMap = idMap;
          _departmentsLoaded = true;
        });
      } else {
        setState(() => _departmentsLoaded = true);
      }
    } catch (e) {
      print('Department fetch error: $e');
      setState(() => _departmentsLoaded = true);
    }
  }

  // ============================================================
  // CAPTCHA
  // ============================================================

  void _generateCaptcha() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random.secure();
    setState(() {
      _captchaText = String.fromCharCodes(
        Iterable.generate(
            6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
      );
    });
  }

  // ============================================================
  // OTP TIMER
  // ============================================================

  void _startOtpTimer() {
    setState(() => _otpCountdown = 60);
    _otpTimerController.reset();
    _otpTimerController.forward();

    _otpTimerController.addListener(() {
      if (_otpTimerController.isAnimating) {
        setState(() {
          _otpCountdown = (60 * (1 - _otpTimerController.value)).round();
        });
      }
    });
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> _sendOTP() async {
    if (_emailController.text.isEmpty) {
      _showErrorMessage('Please enter a valid email first.');
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
        .hasMatch(_emailController.text.trim())) {
      _showErrorMessage('Please enter a valid email address.');
      return;
    }

    if (_captchaController.text.toUpperCase() != _captchaText) {
      _showErrorMessage('Incorrect captcha. Please re-enter.');
      _generateCaptcha();
      _captchaController.clear();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showErrorMessage('Please fill all required fields correctly.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('📧 Sending OTP to: ${_emailController.text.trim()}');

      final profileResponse = await supabase
          .from('profiles')
          .select('email, email_verified')
          .eq('email', _emailController.text.trim())
          .maybeSingle();

      if (profileResponse != null &&
          profileResponse['email_verified'] == true) {
        _showErrorMessage(
            'Email already registered. Please use login instead.');
        setState(() => _isLoading = false);
        return;
      }

      await supabase.auth.signInWithOtp(
        email: _emailController.text.trim(),
        emailRedirectTo: 'achivo://email-verified',
        data: {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
        },
      );

      setState(() {
        _isLoading = false;
        _isOtpSent = true;
      });

      _startOtpTimer();
      _showSuccessMessage(
          'Verification code sent to your email! Check your inbox.');

      print('✅ OTP sent successfully via Supabase Auth');
    } on AuthException catch (e) {
      setState(() => _isLoading = false);
      print('❌ OTP Send Error: ${e.message}');
      _showErrorMessage('Failed to send verification code: ${e.message}');
    } catch (error) {
      setState(() => _isLoading = false);
      print('❌ Unexpected Error: $error');
      _showErrorMessage(
          'Failed to send verification code: ${error.toString()}');
    }
  }

  Future<void> _resendOTP() async {
    if (_otpCountdown == 0) {
      await _sendOTP();
    }
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      _showErrorMessage('Please enter the 6-digit verification code.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🔐 Verifying OTP: ${_otpController.text.trim()}');

      final response = await supabase.auth.verifyOTP(
        email: _emailController.text.trim(),
        token: _otpController.text.trim(),
        type: OtpType.email,
      );

      if (response.session == null || response.user == null) {
        setState(() => _isLoading = false);
        _showErrorMessage('Invalid verification code. Please try again.');
        return;
      }

      final userId = response.user!.id;
      print('✅ OTP verified successfully!');
      print('📧 Email confirmed: ${response.user!.emailConfirmedAt}');
      print('👤 User ID: $userId');

      await _completeRegistration(userId);
    } on AuthException catch (e) {
      setState(() => _isLoading = false);
      print('❌ OTP Verification Error: ${e.message}');
      _showErrorMessage('Verification failed: ${e.message}');
    } catch (error) {
      setState(() => _isLoading = false);
      print('❌ Unexpected Error: $error');
      _showErrorMessage('Verification failed: ${error.toString()}');
    }
  }

  // ============================================================
  // COMPLETE REGISTRATION
  // ============================================================

  Future<void> _completeRegistration(String userId) async {
    if (_profileData['institute_id'] == null) {
      throw Exception('Institute data missing from initial setup.');
    }

    final departmentId = _departmentIdMap[selectedDepartment];
    if (departmentId == null) {
      throw Exception('Please select a valid department.');
    }

    try {
      print('📝 Completing registration for user: $userId');

      await supabase.auth.updateUser(
        UserAttributes(
          password: _passwordController.text.trim(),
          data: {
            'first_name': _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
            'role': 'student',
            'department_id': departmentId,
            'institute_id': _profileData['institute_id'],
            'state_id': _profileData['state_id'],
            'country_id': _profileData['country_id'],
          },
        ),
      );

      print('✅ User metadata updated');

      await Future.delayed(const Duration(milliseconds: 500));

      print('📞 Calling register_student_rpc');
      final rpcResponse =
      await supabase.rpc('register_student_rpc', params: {
        'p_user_id': userId,
        'p_email': _emailController.text.trim(),
        'p_first_name': _firstNameController.text.trim(),
        'p_last_name': _lastNameController.text.trim(),
        'p_father_name': _fatherNameController.text.trim(),
        'p_gender': selectedGender!,
        'p_phone': _phoneController.text.trim(),
        'p_student_id': _studentIdController.text.trim(),
        'p_roll_number': _rollNoController.text.trim(),
        'p_year': selectedYear!,
        'p_dept_id': departmentId,
        'p_inst_id': _profileData['institute_id'],
        'p_state_id': _profileData['state_id'],
        'p_country_id': _profileData['country_id'],
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Registration timeout - please try again');
        },
      );

      print('📦 RPC Response: $rpcResponse');

      if (rpcResponse == null || rpcResponse['success'] != true) {
        try {
          await supabase.auth.signOut();
        } catch (_) {}
        throw Exception(rpcResponse?['error'] ?? 'Registration failed');
      }

      setState(() {
        _isLoading = false;
        _otpTimerController.stop();
      });

      print('✅ Registration completed successfully - redirecting to dashboard');
      _showSuccessMessage('Account created successfully! Welcome to Achivo 🎉');

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/student-dashboard');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Registration completion error: $e');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _handleLogin() async {
    try {
      print('🔐 Starting login for roll number: ${_rollNoController.text}');

      final studentResponse = await supabase
          .from('students')
          .select('email, is_active')
          .eq('roll_number', _rollNoController.text.trim())
          .maybeSingle();

      if (studentResponse == null) {
        throw Exception('Student not found. Please check your roll number.');
      }

      final email = studentResponse['email'] as String;
      final isActive = studentResponse['is_active'] as bool?;

      print('📧 Found student email: $email, Active: $isActive');

      if (isActive == false) {
        throw Exception(
          'Your account is not activated. Please verify your email first. '
              'Check your inbox for the verification link.',
        );
      }

      final result = await AuthService.login(
        email: email,
        password: _passwordController.text.trim(),
      );

      if (!result.success) {
        throw Exception(result.message);
      }

      print('✅ Login successful!');
      _showSuccessMessage('Login successful!');

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/student-dashboard');
      }
    } catch (error) {
      print('❌ Login Error: $error');
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<void> _handleForgotPassword() async {
    if (_rollNoController.text.isEmpty) {
      _showErrorMessage('Please enter your roll number first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await supabase
          .from('students')
          .select('email')
          .eq('roll_number', _rollNoController.text.trim())
          .maybeSingle();

      if (response != null) {
        final result = await AuthService.resetPassword(response['email']);
        if (result.success) {
          _showSuccessMessage(result.message);
        } else {
          _showErrorMessage(result.message);
        }
      } else {
        _showErrorMessage('No account found with this roll number');
      }
    } catch (error) {
      _showErrorMessage('Failed to send reset link: ${error.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // FORM SUBMIT
  // ============================================================

  bool _isPasswordValid(String password) {
    RegExp passwordRegex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (!_isLogin && !_isOtpSent) {
        _showErrorMessage(
            'Please verify your email first by clicking "Send OTP" and entering the code');
        return;
      }

      if (_captchaController.text.toUpperCase() != _captchaText) {
        _showErrorMessage('Incorrect captcha. Please refresh and try again.');
        _generateCaptcha();
        _captchaController.clear();
        return;
      }

      setState(() => _isLoading = true);

      try {
        if (_isLogin) {
          await _handleLogin();
        } else {
          await _verifyOTP();
        }
      } catch (error) {
        _showErrorMessage(error is Exception
            ? error.toString().replaceFirst('Exception: ', '')
            : 'An unexpected error occurred.');
      } finally {
        if (_isLogin) {
          setState(() => _isLoading = false);
        }
        _generateCaptcha();
        _captchaController.clear();
      }
    } else {
      _generateCaptcha();
      _captchaController.clear();
    }
  }

  // ============================================================
  // SNACKBARS
  // ============================================================

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ============================================================
  // TERMS AND CONDITIONS DIALOG
  // ============================================================

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.purple.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Terms and Conditions',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTermsSection(
                          'Last Updated: January 15, 2026',
                          '',
                          isDate: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTermsSection(
                          '1. Acceptance of Terms',
                          'By accessing and using the Achivo Student Portal, you accept and agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our services.',
                        ),
                        _buildTermsSection(
                          '2. Student Account Registration',
                          'You agree to provide accurate, current, and complete information during the registration process. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.',
                        ),
                        _buildTermsSection(
                          '3. Authorized Use',
                          'Student accounts are intended solely for enrolled students of registered educational institutions. You may not share your login credentials with unauthorized individuals or use the portal for any unlawful purposes.',
                        ),
                        _buildTermsSection(
                          '4. Data Privacy and Security',
                          'We take data security seriously. All personal and academic data is encrypted and stored securely. You acknowledge that you are responsible for maintaining the confidentiality of your credentials and the information accessible through the portal.',
                        ),
                        _buildTermsSection(
                          '5. Intellectual Property',
                          'All content, features, and functionality of the Achivo platform are owned by Achivo and are protected by international copyright, trademark, and other intellectual property laws.',
                        ),
                        _buildTermsSection(
                          '6. Prohibited Activities',
                          'You agree not to:\n• Attempt to gain unauthorized access to any portion of the portal\n• Use the platform to transmit malicious code or viruses\n• Interfere with or disrupt the integrity or performance of the platform\n• Attempt to decipher, decompile, or reverse engineer any software\n• Impersonate other students or academic staff',
                        ),
                        _buildTermsSection(
                          '7. Academic Integrity',
                          'Students are expected to uphold academic integrity at all times while using the platform. Any misuse of the platform to facilitate academic dishonesty may result in account suspension.',
                        ),
                        _buildTermsSection(
                          '8. Service Availability',
                          'While we strive to maintain continuous service availability, we do not guarantee uninterrupted access. We reserve the right to modify, suspend, or discontinue any aspect of the service with or without notice.',
                        ),
                        _buildTermsSection(
                          '9. Limitation of Liability',
                          'Achivo shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use or inability to use the service.',
                        ),
                        _buildTermsSection(
                          '10. Governing Law',
                          'These Terms shall be governed by and construed in accordance with the laws of India, without regard to its conflict of law provisions.',
                        ),
                        _buildTermsSection(
                          '11. Contact Information',
                          'For questions about these Terms and Conditions, please contact us at:\n\nEmail: support@achivo.com\nPhone: +91-XXX-XXX-XXXX',
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'By clicking "Create Student Account" or "Sign In as Student", you acknowledge that you have read and agree to these Terms and Conditions.',
                                  style: TextStyle(
                                    color: Colors.blue.shade900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'I Understand',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PRIVACY POLICY DIALOG
  // ============================================================

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.blue.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.privacy_tip,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTermsSection(
                          'Effective Date: January 15, 2026',
                          '',
                          isDate: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTermsSection(
                          '1. Information We Collect',
                          'We collect information that you provide directly to us, including:\n• Personal identification (name, email, phone number)\n• Academic details (roll number, student ID, department, year)\n• Account authentication data\n• Usage data and preferences',
                        ),
                        _buildTermsSection(
                          '2. How We Use Your Information',
                          'We use the collected information to:\n• Provide and maintain our services\n• Authenticate and authorize student access\n• Communicate important updates and notifications\n• Improve our platform and user experience\n• Comply with legal obligations',
                        ),
                        _buildTermsSection(
                          '3. Data Security',
                          'We implement industry-standard security measures to protect your data:\n• End-to-end encryption for sensitive information\n• Secure authentication protocols (OTP verification)\n• Regular security audits and updates\n• Restricted access to authorized personnel only',
                        ),
                        _buildTermsSection(
                          '4. Data Sharing and Disclosure',
                          'We do not sell or rent your personal information. We may share data only:\n• With your explicit consent\n• With your registered educational institution\n• To comply with legal requirements\n• To protect our rights and prevent fraud',
                        ),
                        _buildTermsSection(
                          '5. Cookies and Tracking',
                          'We use cookies and similar technologies to enhance user experience, maintain sessions, and analyze platform usage. You can control cookie preferences through your browser settings.',
                        ),
                        _buildTermsSection(
                          '6. Data Retention',
                          'We retain your information for as long as your account is active or as needed to provide services. You may request account deletion at any time, subject to legal retention requirements.',
                        ),
                        _buildTermsSection(
                          '7. Your Rights',
                          'You have the right to:\n• Access your personal data\n• Correct inaccurate information\n• Request data deletion\n• Opt-out of marketing communications\n• Export your data in a portable format',
                        ),
                        _buildTermsSection(
                          '8. Children\'s Privacy',
                          'While our platform serves students who may be minors, we take extra care to protect their data. Parental consent may be required for students under 13 years of age.',
                        ),
                        _buildTermsSection(
                          '9. International Data Transfers',
                          'Your data may be transferred and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your information.',
                        ),
                        _buildTermsSection(
                          '10. Changes to Privacy Policy',
                          'We may update this Privacy Policy periodically. We will notify you of significant changes via email or platform notification.',
                        ),
                        _buildTermsSection(
                          '11. Contact Us',
                          'For privacy-related inquiries:\n\nEmail: privacy@achivo.com\nPhone: +91-XXX-XXX-XXXX\nAddress: Achivo Headquarters, India',
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.verified_user,
                                  color: Colors.green.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your privacy is important to us. We are committed to protecting your personal information and maintaining transparency.',
                                  style: TextStyle(
                                    color: Colors.green.shade900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'I Understand',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // TERMS SECTION HELPER
  // ============================================================

  Widget _buildTermsSection(String title, String content,
      {bool isDate = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isDate ? 12 : 16,
              fontWeight: isDate ? FontWeight.w500 : FontWeight.bold,
              color: isDate ? Colors.grey[600] : Colors.grey[800],
            ),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3E8FF),
              Color(0xFFE0E7FF),
              Color(0xFFDBEAFE),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildTabSelector(),
                  const SizedBox(height: 32),
                  _buildForm(),
                  const SizedBox(height: 32),
                  _buildFooter(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/welcome'),
              icon: const Icon(Icons.arrow_back, size: 24),
              color: Colors.black87,
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Student Portal',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Begin your achievement journey with Achivo',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ============================================================
  // TAB SELECTOR
  // ============================================================

  Widget _buildTabSelector() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _isLogin = false;
                _isOtpSent = false;
                _generateCaptcha();
              }),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: !_isLogin
                      ? const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                  )
                      : null,
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Center(
                  child: Text(
                    'Register',
                    style: TextStyle(
                      color: !_isLogin ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _isLogin = true;
                _isOtpSent = false;
                _generateCaptcha();
              }),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: _isLogin
                      ? const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                  )
                      : null,
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Center(
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: _isLogin ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORM
  // ============================================================

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (!_isLogin) ...[
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: _firstNameController,
                    label: 'First Name',
                    placeholder: 'Enter first name',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter first name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    placeholder: 'Enter last name',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter last name';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildEmailFieldWithOTP(),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _fatherNameController,
              label: "Father's Name",
              placeholder: "Enter your father's name",
              icon: Icons.family_restroom_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter your father's name";
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildDropdownField(
              label: 'Gender',
              value: selectedGender,
              items: genders,
              onChanged: (value) => setState(() => selectedGender = value),
              hint: 'Select gender',
              icon: Icons.person_2_outlined,
              validator: (value) {
                if (value == null) return 'Please select your gender';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _phoneController,
              label: 'Phone Number',
              placeholder: 'Enter your phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.length < 10) {
                  return 'Phone number must be at least 10 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildDropdownField(
              label: 'Year',
              value: selectedYear,
              items: years,
              onChanged: (value) => setState(() => selectedYear = value),
              hint: 'Select year',
              icon: Icons.calendar_today_outlined,
              validator: (value) {
                if (value == null) return 'Please select your year';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _studentIdController,
              label: 'Student ID',
              placeholder: 'Enter Student ID',
              icon: Icons.badge_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter Student ID';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            if (!_departmentsLoaded)
              _buildInputField(
                controller:
                TextEditingController(text: 'Loading departments...'),
                label: 'Department',
                placeholder: 'Loading...',
                icon: Icons.business_outlined,
                enabled: false,
                validator: (_) => null,
              )
            else if (_departmentNames.isEmpty)
              _buildInputField(
                controller:
                TextEditingController(text: 'No departments found'),
                label: 'Department',
                placeholder: 'Check database connection',
                icon: Icons.error_outline,
                enabled: false,
                validator: (_) => 'Department list is empty.',
              )
            else
              _buildDropdownField(
                label: 'Department',
                value: selectedDepartment,
                items: _departmentNames,
                onChanged: (value) =>
                    setState(() => selectedDepartment = value),
                hint: 'Select department',
                icon: Icons.business_outlined,
                validator: (value) {
                  if (value == null) return 'Please select your department';
                  return null;
                },
              ),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _rollNoController,
              label: 'Roll Number',
              placeholder: 'Enter Roll Number',
              icon: Icons.numbers_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter Roll Number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
          ],
          if (_isLogin) ...[
            _buildInputField(
              controller: _rollNoController,
              label: 'Roll Number',
              placeholder: 'Enter Roll Number',
              icon: Icons.numbers_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your roll number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
          ],
          _buildInputField(
            controller: _passwordController,
            label: 'Password',
            placeholder:
            _isLogin ? 'Enter your password' : 'Create a password',
            icon: Icons.lock_outline,
            obscureText: !_passwordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey[500],
              ),
              onPressed: () =>
                  setState(() => _passwordVisible = !_passwordVisible),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (!_isLogin && !_isPasswordValid(value)) {
                return 'Password must be 8+ chars with uppercase, lowercase, digit & special char';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          if (!_isLogin) ...[
            _buildInputField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              placeholder: 'Confirm your password',
              icon: Icons.lock_outline,
              obscureText: !_confirmPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _confirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey[500],
                ),
                onPressed: () => setState(
                        () => _confirmPasswordVisible = !_confirmPasswordVisible),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
          ],
          _buildEnhancedCaptchaField(),
          const SizedBox(height: 20),
          if (_isLogin) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _handleForgotPassword,
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 14,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ] else
            const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin
                        ? 'Sign In as Student'
                        : 'Create Student Account',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.school_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FOOTER — clickable Terms & Privacy links
  // ============================================================

  Widget _buildFooter() {
    return Text.rich(
      TextSpan(
        text: 'By continuing, you agree to our ',
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
        children: [
          WidgetSpan(
            child: GestureDetector(
              onTap: _showTermsAndConditions,
              child: const Text(
                'Terms of Service',
                style: TextStyle(
                  color: Color(0xFF8B5CF6),
                  decoration: TextDecoration.underline,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const TextSpan(text: ' and '),
          WidgetSpan(
            child: GestureDetector(
              onTap: _showPrivacyPolicy,
              child: const Text(
                'Privacy Policy',
                style: TextStyle(
                  color: Color(0xFF8B5CF6),
                  decoration: TextDecoration.underline,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  // ============================================================
  // INPUT FIELD WIDGET
  // ============================================================

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            enabled: enabled,
            style: TextStyle(color: Colors.grey[800], fontSize: 16),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
              prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DROPDOWN FIELD WIDGET
  // ============================================================

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
              prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            items: items.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMAIL + OTP FIELD
  // ============================================================

  Widget _buildEmailFieldWithOTP() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Email Address',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
            style: TextStyle(color: Colors.grey[800], fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Enter your email address',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
              prefixIcon:
              Icon(Icons.mail_outline, color: Colors.grey[500], size: 20),
              suffixIcon: TextButton(
                onPressed: _isOtpSent ? null : _sendOTP,
                child: Text(
                  _isOtpSent ? 'Sent ✓' : 'Send OTP',
                  style: TextStyle(
                    color: _isOtpSent ? Colors.green : const Color(0xFF8B5CF6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (_isOtpSent) ...[
          const SizedBox(height: 16),
          _buildEnhancedOtpField(),
        ],
      ],
    );
  }

  // ============================================================
  // OTP FIELD WIDGET
  // ============================================================

  Widget _buildEnhancedOtpField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Text(
                'Email Verification',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Enter the 6-digit code sent to your email',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                    ),
                    decoration: InputDecoration(
                      hintText: '• • • • • •',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 18,
                        letterSpacing: 8,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Verify',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _otpCountdown > 0
                    ? 'Resend OTP in ${_otpCountdown}s'
                    : "Didn't receive code?",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              TextButton(
                onPressed: _otpCountdown == 0 ? _resendOTP : null,
                child: Text(
                  'Resend OTP',
                  style: TextStyle(
                    color: _otpCountdown == 0
                        ? const Color(0xFF8B5CF6)
                        : Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CAPTCHA FIELD WIDGET
  // ============================================================

  Widget _buildEnhancedCaptchaField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Security Verification',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade100,
                          Colors.blue.shade100,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: CaptchaBackgroundPainter(),
                          ),
                        ),
                        Center(
                          child: Text(
                            _captchaText,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _captchaController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter captcha';
                    }
                    if (value.toUpperCase() != _captchaText) {
                      return 'Incorrect captcha';
                    }
                    return null;
                  },
                  style: TextStyle(color: Colors.grey[800], fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Enter captcha',
                    hintStyle:
                    TextStyle(color: Colors.grey[500], fontSize: 16),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  onPressed: () {
                    _generateCaptcha();
                    _captchaController.clear();
                  },
                  icon: const Icon(Icons.refresh, color: Color(0xFF8B5CF6)),
                  tooltip: 'Change Captcha',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.purple.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CAPTCHA PAINTER
// ============================================================

class CaptchaBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final random = Random(42);
    for (int i = 0; i < 8; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final endX = random.nextDouble() * size.width;
      final endY = random.nextDouble() * size.height;
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }

    paint.style = PaintingStyle.fill;
    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 1, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}