import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _isOtpVerified = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _showEmailVerificationPending = false;
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
        CurvedAnimation(parent: _backgroundController, curve: Curves.easeOut));
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

  Future<void> _fetchDepartments() async {
    try {
      final response = await supabase
          .from('departments')
          .select('id, name')
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
        setState(() {
          _departmentsLoaded = true;
        });
      }
    } catch (e) {
      print('Department fetch error: $e');
      setState(() {
        _departmentsLoaded = true;
      });
    }
  }

  void _generateCaptcha() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random.secure(); // ✅ Use secure random
    setState(() {
      _captchaText = String.fromCharCodes(
        Iterable.generate(
            6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
      );
    });
  }

  void _startOtpTimer() {
    setState(() {
      _otpCountdown = 60;
    });
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

    setState(() {
      _isLoading = true;
    });

    try {
      final profileResponse = await supabase
          .from('profiles')
          .select('email')
          .eq('email', _emailController.text.trim())
          .maybeSingle();

      if (profileResponse != null && !_isLogin) {
        _showErrorMessage('Email already registered. Please use login instead.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await supabase.auth.signInWithOtp(
        email: _emailController.text.trim(),
        emailRedirectTo: 'achivo://email-verified',
      );

      setState(() {
        _isLoading = false;
        _isOtpSent = true;
      });

      _startOtpTimer();
      _showSuccessMessage('Verification code sent to your email! Check your inbox.');
    } on AuthException catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Failed to send verification code: ${error.message}');
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Failed to send verification code: ${error.toString()}');
    }
  }

  Future<void> _resendOTP() async {
    if (_otpCountdown == 0) {
      await _sendOTP();
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      _showErrorMessage('Please enter the 6-digit verification code.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase.auth.verifyOTP(
        email: _emailController.text.trim(),
        token: _otpController.text.trim(),
        type: OtpType.email,
      );

      if (response.user != null) {
        await supabase.auth.signOut();

        setState(() {
          _isLoading = false;
          _isOtpVerified = true;
          _otpTimerController.stop();
        });

        _showSuccessMessage('Email verified successfully! You can now complete registration.');
      }
    } on AuthException catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Invalid verification code: ${error.message}');
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Verification failed: ${error.toString()}');
    }
  }

  bool _isPasswordValid(String password) {
    RegExp passwordRegex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (!_isLogin && !_isOtpVerified) {
        _showErrorMessage('Please verify your email first');
        return;
      }

      if (_captchaController.text.toUpperCase() != _captchaText) {
        _showErrorMessage('Incorrect captcha. Please refresh and try again.');
        _generateCaptcha();
        _captchaController.clear();
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        if (_isLogin) {
          await _handleLogin();
        } else {
          await _handleRegistration();
        }
      } catch (error) {
        _showErrorMessage(error is Exception
            ? error.toString().replaceFirst('Exception: ', '')
            : 'An unexpected error occurred.');
      } finally {
        setState(() {
          _isLoading = false;
        });
        _generateCaptcha();
        _captchaController.clear();
      }
    } else {
      _generateCaptcha();
      _captchaController.clear();
    }
  }

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

      final authResponse = await supabase.auth.signInWithPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      print('👤 Auth response user: ${authResponse.user?.id}');
      print('✅ Email confirmed at: ${authResponse.user?.emailConfirmedAt}');

      if (authResponse.user == null) {
        throw Exception('Login failed: Invalid credentials.');
      }

      if (authResponse.user!.emailConfirmedAt == null) {
        await supabase.auth.signOut();
        throw Exception(
          'Please verify your email before logging in. '
              'Check your inbox for the verification link.',
        );
      }

      await supabase.from('profiles').update({
        'last_login': DateTime.now().toIso8601String(),
      }).eq('id', authResponse.user!.id);

      print('✅ Login successful!');
      _showSuccessMessage('Login successful!');

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/student-dashboard');
      }
    } on AuthException catch (e) {
      print('❌ Auth Exception: ${e.message}');
      String errorMessage = 'Login failed: ';

      if (e.message.toLowerCase().contains('invalid') ||
          e.message.toLowerCase().contains('credentials')) {
        errorMessage += 'Incorrect roll number or password.';
      } else if (e.message.toLowerCase().contains('email')) {
        errorMessage += 'Please verify your email first.';
      } else {
        errorMessage += e.message;
      }

      throw Exception(errorMessage);
    } catch (error) {
      print('❌ General Error: $error');
      throw Exception('Login failed: ${error.toString()}');
    }
  }

  Future<void> _handleRegistration() async {
    if (_profileData['institute_id'] == null) {
      throw Exception('Institute data missing from initial setup.');
    }

    final departmentId = _departmentIdMap[selectedDepartment];

    try {
      print('📝 Starting registration for: ${_emailController.text}');

      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        emailRedirectTo: 'achivo://email-verified',
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create account. Please try again.');
      }

      print('✅ User created: ${authResponse.user!.id}');
      print('📧 Email confirmed: ${authResponse.user!.emailConfirmedAt}');

      await supabase.rpc('register_student_rpc', params: {
        'p_user_id': authResponse.user!.id,
        'p_email': _emailController.text.trim(),
        'p_first_name': _firstNameController.text.trim(),
        'p_last_name': _lastNameController.text.trim(),
        'p_father_name': _fatherNameController.text.trim(),
        'p_gender': selectedGender,
        'p_phone': _phoneController.text.trim(),
        'p_student_id': _studentIdController.text.trim(),
        'p_roll_number': _rollNoController.text.trim(),
        'p_year': selectedYear,
        'p_dept_id': departmentId,
        'p_inst_id': _profileData['institute_id'],
        'p_state_id': _profileData['state_id'],
        'p_country_id': _profileData['country_id'],
      });

      print('✅ Student record created');

      await supabase.auth.signOut();

      setState(() {
        _showEmailVerificationPending = true;
      });

      _showSuccessMessage(
        'Account created! Please check your email to verify your account.',
      );
    } on AuthException catch (e) {
      print('❌ Auth Error: ${e.message}');
      throw Exception('Registration failed: ${e.message}');
    } catch (error) {
      print('❌ Registration Error: $error');
      throw Exception('Registration Error: $error');
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_rollNoController.text.isEmpty) {
      _showErrorMessage('Please enter your roll number first');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase
          .from('students')
          .select('email')
          .eq('roll_number', _rollNoController.text.trim())
          .maybeSingle();

      if (response != null) {
        await supabase.auth.resetPasswordForEmail(
          response['email'],
          redirectTo: 'achivo://reset-password',
        );
        _showSuccessMessage('Password reset link sent to your email');
      } else {
        _showErrorMessage('No account found with this roll number');
      }
    } on AuthException catch (e) {
      _showErrorMessage('Failed to send reset link: ${e.message}');
    } catch (error) {
      _showErrorMessage('Failed to send reset link: ${error.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: _emailController.text.trim(),
      );
      _showSuccessMessage('Verification email sent! Check your inbox.');
    } catch (e) {
      _showErrorMessage('Failed to resend email: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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

  // ✅ NEW: Show Terms and Conditions Dialog
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
                      const Icon(Icons.description, color: Colors.white, size: 28),
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
                          'By creating a student account on Achivo, you accept and agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our platform.',
                        ),
                        _buildTermsSection(
                          '2. Student Account Registration',
                          'You agree to provide accurate, current, and complete information during registration. You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account.',
                        ),
                        _buildTermsSection(
                          '3. Educational Use Only',
                          'Student accounts are intended solely for educational purposes within your registered institution. You may not use the platform for commercial purposes or any unlawful activities.',
                        ),
                        _buildTermsSection(
                          '4. Achievement Tracking & Records',
                          'All achievements, certificates, and records submitted through Achivo must be genuine and verifiable. Submitting false or fraudulent information may result in account suspension or termination.',
                        ),
                        _buildTermsSection(
                          '5. Data Privacy and Security',
                          'We are committed to protecting your personal information. All student data is encrypted and stored securely. You acknowledge that your academic records and achievements may be accessed by authorized institute administrators.',
                        ),
                        _buildTermsSection(
                          '6. Intellectual Property',
                          'All content, features, and functionality of the Achivo platform are owned by Achivo and protected by international copyright, trademark, and intellectual property laws.',
                        ),
                        _buildTermsSection(
                          '7. Prohibited Activities',
                          'You agree not to:\n• Share your login credentials with others\n• Upload malicious code or viruses\n• Attempt unauthorized access to other accounts\n• Misrepresent your identity or achievements\n• Use the platform to harass or harm others',
                        ),
                        _buildTermsSection(
                          '8. Content Ownership',
                          'You retain ownership of content you upload (certificates, projects, achievements). By uploading, you grant Achivo a license to display and process this content for platform functionality.',
                        ),
                        _buildTermsSection(
                          '9. Service Availability',
                          'While we strive for continuous availability, we do not guarantee uninterrupted access. We reserve the right to modify, suspend, or discontinue any aspect of the service with or without notice.',
                        ),
                        _buildTermsSection(
                          '10. Account Termination',
                          'We reserve the right to suspend or terminate accounts that violate these terms. You may request account deletion at any time, subject to institutional record-keeping requirements.',
                        ),
                        _buildTermsSection(
                          '11. Limitation of Liability',
                          'Achivo shall not be liable for any indirect, incidental, special, or consequential damages resulting from your use or inability to use the platform.',
                        ),
                        _buildTermsSection(
                          '12. Governing Law',
                          'These Terms shall be governed by the laws of India, without regard to conflict of law provisions.',
                        ),
                        _buildTermsSection(
                          '13. Changes to Terms',
                          'We may modify these terms at any time. Continued use after changes constitutes acceptance of modified terms.',
                        ),
                        _buildTermsSection(
                          '14. Contact Information',
                          'For questions about these Terms:\n\nEmail: student-support@achivo.com\nPhone: +91-XXX-XXX-XXXX',
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
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
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

  // ✅ NEW: Show Privacy Policy Dialog
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
                      const Icon(Icons.privacy_tip, color: Colors.white, size: 28),
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
                          'We collect information you provide during registration:\n• Personal details (name, email, phone, gender)\n• Academic information (student ID, roll number, department, year)\n• Parent/guardian information (father\'s name)\n• Achievement records and certificates\n• Usage data and preferences',
                        ),
                        _buildTermsSection(
                          '2. How We Use Your Information',
                          'We use collected information to:\n• Create and manage your student account\n• Track and verify your academic achievements\n• Facilitate communication with your institution\n• Improve platform functionality and user experience\n• Generate reports for authorized administrators\n• Comply with educational and legal requirements',
                        ),
                        _buildTermsSection(
                          '3. Data Security',
                          'We implement robust security measures:\n• End-to-end encryption for sensitive data\n• Secure OTP-based email verification\n• Regular security audits and updates\n• Password protection with strong requirements\n• Restricted access to authorized personnel only',
                        ),
                        _buildTermsSection(
                          '4. Data Sharing',
                          'We share your data only:\n• With your educational institution\'s administrators\n• With your explicit consent\n• To comply with legal obligations\n• With trusted service providers under strict confidentiality\n\nWe NEVER sell your personal information to third parties.',
                        ),
                        _buildTermsSection(
                          '5. Student Rights Under FERPA',
                          'If applicable, your educational records are protected under the Family Educational Rights and Privacy Act (FERPA). You have the right to access and request corrections to your records.',
                        ),
                        _buildTermsSection(
                          '6. Cookies and Tracking',
                          'We use cookies to enhance user experience, maintain sessions, and analyze platform usage. You can manage cookie preferences through your browser settings.',
                        ),
                        _buildTermsSection(
                          '7. Data Retention',
                          'We retain your information for the duration of your enrollment and as required by institutional policies. You may request data deletion after graduation, subject to legal retention requirements.',
                        ),
                        _buildTermsSection(
                          '8. Your Privacy Rights',
                          'You have the right to:\n• Access your personal data\n• Correct inaccurate information\n• Request data portability\n• Opt-out of non-essential communications\n• Request account deletion (subject to institutional requirements)',
                        ),
                        _buildTermsSection(
                          '9. Parental Access',
                          'If you are under 18, your parents/guardians may have rights to access your educational records as permitted by law and institutional policy.',
                        ),
                        _buildTermsSection(
                          '10. Third-Party Services',
                          'Our platform may integrate with third-party services (e.g., email verification). These services have their own privacy policies, which we encourage you to review.',
                        ),
                        _buildTermsSection(
                          '11. International Data Transfers',
                          'Your data may be processed in countries other than your own. We ensure appropriate safeguards are in place to protect your information.',
                        ),
                        _buildTermsSection(
                          '12. Changes to Privacy Policy',
                          'We may update this Privacy Policy periodically. We will notify you of significant changes via email or platform notification.',
                        ),
                        _buildTermsSection(
                          '13. Contact Us',
                          'For privacy-related inquiries:\n\nEmail: privacy@achivo.com\nStudent Support: student-support@achivo.com\nPhone: +91-XXX-XXX-XXXX',
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
                              Icon(Icons.verified_user, color: Colors.green.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your privacy is our priority. We are committed to protecting your personal information and being transparent about how we use it.',
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

  Widget _buildTermsSection(String title, String content, {bool isDate = false}) {
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

  @override
  Widget build(BuildContext context) {
    if (_showEmailVerificationPending) {
      return _buildEmailVerificationPendingScreen();
    }

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

  Widget _buildEmailVerificationPendingScreen() {
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_unread,
                      size: 80,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Verify Your Email',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We\'ve sent a verification link to:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _emailController.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Click the link in your email to activate your account',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Don\'t see the email? Check your spam folder',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _resendVerificationEmail,
                    icon: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.refresh),
                    label: const Text('Resend Verification Email'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showEmailVerificationPending = false;
                      });
                      Navigator.pushReplacementNamed(context, '/welcome');
                    },
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
                _isOtpVerified = false;
                _generateCaptcha();
              }),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: !_isLogin
                      ? const LinearGradient(
                    colors: [
                      Color(0xFF8B5CF6),
                      Color(0xFF3B82F6),
                    ],
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
                _isOtpVerified = false;
                _generateCaptcha();
              }),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: _isLogin
                      ? const LinearGradient(
                    colors: [
                      Color(0xFF8B5CF6),
                      Color(0xFF3B82F6),
                    ],
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
                if (value == null) {
                  return 'Please select your gender';
                }
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
                if (value == null) {
                  return 'Please select your year';
                }
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
                controller: TextEditingController(
                    text: 'No departments found (Check DB)'),
                label: 'Department',
                placeholder: 'Check database connection or seeding',
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
                  if (value == null) {
                    return 'Please select your department';
                  }
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
              onPressed: () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (!_isLogin) {
                if (!_isPasswordValid(value)) {
                  return 'Password must contain uppercase, lowercase, digit & special character';
                }
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
                onPressed: () {
                  setState(() {
                    _confirmPasswordVisible = !_confirmPasswordVisible;
                  });
                },
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
                colors: [
                  Color(0xFF8B5CF6),
                  Color(0xFF3B82F6),
                ],
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
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

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
              suffixIcon: !_isOtpVerified && !_isLogin
                  ? TextButton(
                onPressed: _isOtpSent ? null : _sendOTP,
                child: Text(
                  _isOtpSent ? 'Sent' : 'Send OTP',
                  style: TextStyle(
                    color: _isOtpSent
                        ? Colors.green
                        : const Color(0xFF8B5CF6),
                    fontSize: 12,
                  ),
                ),
              )
                  : _isOtpVerified
                  ? const Icon(Icons.verified, color: Colors.green, size: 20)
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (_isOtpSent && !_isOtpVerified && !_isLogin) ...[
          const SizedBox(height: 16),
          _buildEnhancedOtpField(),
        ],
      ],
    );
  }

  Widget _buildEnhancedOtpField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.purple.shade50,
          ],
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
                  onPressed: _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                  child: const Text(
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
                    : 'Didn\'t receive code?',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
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