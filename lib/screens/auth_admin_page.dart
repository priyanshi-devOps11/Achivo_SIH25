import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

SupabaseClient get supabase => Supabase.instance.client;

class AuthAdminPage extends StatefulWidget {
  const AuthAdminPage({Key? key}) : super(key: key);

  @override
  State<AuthAdminPage> createState() => _AuthAdminPageState();
}

class _AuthAdminPageState extends State<AuthAdminPage>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late AnimationController _otpTimerController;

  late Animation<double> _backgroundAnimation;
  late Animation<double> _contentAnimation;

  bool _isLoading = false;
  bool _isLogin = false;
  bool _rememberMe = false;
  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  String _captchaText = '';
  int _otpCountdown = 0;

  Map<String, dynamic> _profileData = {};
  bool _isDataLoaded = false;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instituteIdController = TextEditingController();
  final _otpController = TextEditingController();
  final _captchaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);
    _contentController    = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _otpTimerController   = AnimationController(duration: const Duration(seconds: 60), vsync: this);
    _backgroundAnimation  = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _backgroundController, curve: Curves.easeOut));
    _contentAnimation     = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _contentController,    curve: Curves.easeOut));
    _generateCaptcha();
    _backgroundController.forward();
    Future.delayed(const Duration(milliseconds: 300), () => _contentController.forward());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) { _profileData = args; _isDataLoaded = true; }
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
    _instituteIdController.dispose();
    _otpController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  void _generateCaptcha() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    setState(() {
      _captchaText = String.fromCharCodes(
        Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
      );
    });
  }

  void _startOtpTimer() {
    setState(() => _otpCountdown = 60);
    _otpTimerController.reset();
    _otpTimerController.forward();
    _otpTimerController.addListener(() {
      if (_otpTimerController.isAnimating) {
        setState(() => _otpCountdown = (60 * (1 - _otpTimerController.value)).round());
      }
    });
  }

  // ── Pre-checks before sending OTP ────────────────────────────────────
  Future<bool> _preCheckRegistration() async {
    final instituteCode = _instituteIdController.text.trim();
    final email         = _emailController.text.trim();
    final phone         = _phoneController.text.trim();

    // 1. Validate institute code and fetch IDs
    final instRow = await supabase
        .from('institutes')
        .select('id, state_id, country_id')
        .eq('institute_code', instituteCode)
        .maybeSingle();

    if (instRow == null) {
      _showErrorMessage('Institute ID not found. Please check and try again.');
      return false;
    }

    final instId = instRow['id'] as int;

    // 2. One admin per institute
    final existingAdmin = await supabase
        .from('admins')
        .select('id')
        .eq('institute_id', instId)
        .maybeSingle();

    if (existingAdmin != null) {
      _showErrorMessage('An admin is already registered for this institute. Each institute can only have one admin.');
      return false;
    }

    // 3. Email uniqueness globally
    final emailRow = await supabase
        .from('profiles')
        .select('email')
        .eq('email', email)
        .maybeSingle();

    if (emailRow != null) {
      _showErrorMessage('This email is already registered with another account.');
      return false;
    }

    // 4. Phone uniqueness globally using DB function
    final phoneCheck = await supabase.rpc('validate_registration_fields', params: {
      'p_role': 'admin',
      'p_phone': phone,
      'p_inst_id': instId,
    });

    if (phoneCheck is Map && phoneCheck['valid'] == false) {
      final errors = phoneCheck['errors'] as Map?;
      if (errors != null) {
        if (errors.containsKey('phone')) {
          _showErrorMessage(errors['phone']);
          return false;
        }
        if (errors.containsKey('institute')) {
          _showErrorMessage(errors['institute']);
          return false;
        }
      }
    }

    return true;
  }

  Future<void> _sendOTP() async {
    if (_emailController.text.isEmpty || !_formKey.currentState!.validate()) {
      _showErrorMessage('Please fill all fields correctly before sending OTP.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Run pre-checks BEFORE sending OTP to avoid wasting email quota
      final ok = await _preCheckRegistration();
      if (!ok) {
        setState(() => _isLoading = false);
        return;
      }

      await supabase.auth.signInWithOtp(
        email: _emailController.text.trim(),
        shouldCreateUser: true,
      );

      setState(() { _isLoading = false; _isOtpSent = true; });
      _startOtpTimer();
      _showSuccessMessage('OTP sent! Check your inbox (and spam/junk folder).');
    } on AuthException catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Failed to send OTP: ${e.message}');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Failed to send OTP: $e');
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      _showErrorMessage('Please enter the 6-digit OTP.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await supabase.auth.verifyOTP(
        email: _emailController.text.trim(),
        token: _otpController.text.trim(),
        type: OtpType.email,
      );
      if (response.user != null) {
        setState(() { _isLoading = false; _isOtpVerified = true; _otpTimerController.stop(); });
        _showSuccessMessage('Email verified! Complete your registration below.');
      } else {
        setState(() => _isLoading = false);
        _showErrorMessage('Invalid OTP. Please try again.');
      }
    } on AuthException catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('OTP verification failed: ${e.message}');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('OTP verification failed: $e');
    }
  }

  Future<void> _resendOTP() async {
    if (_otpCountdown == 0) await _sendOTP();
  }

  bool _isPasswordValid(String p) =>
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$').hasMatch(p);

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      _generateCaptcha(); _captchaController.clear();
      return;
    }

    if (!_isLogin && !_isOtpVerified) {
      _showErrorMessage('Please verify your email first.');
      return;
    }

    if (_captchaController.text.toUpperCase() != _captchaText) {
      _showErrorMessage('Incorrect captcha. Please try again.');
      _generateCaptcha(); _captchaController.clear();
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) await _handleLogin();
      else           await _handleRegistration();
    } catch (e) {
      _showErrorMessage(e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'An unexpected error occurred.');
    } finally {
      setState(() => _isLoading = false);
      _generateCaptcha(); _captchaController.clear();
    }
  }

  Future<void> _handleLogin() async {
    final instituteCode = _instituteIdController.text.trim();

    final instRow = await supabase
        .from('institutes')
        .select('id')
        .eq('institute_code', instituteCode)
        .maybeSingle();

    if (instRow == null) throw Exception('Institute ID not found or invalid.');

    final adminProfile = await supabase
        .from('profiles')
        .select('email, first_name')
        .eq('institute_id', instRow['id'])
        .eq('role', 'admin')
        .maybeSingle();

    if (adminProfile == null) throw Exception('No admin registered for this institute. Please register first.');

    final authResponse = await supabase.auth.signInWithPassword(
      email: adminProfile['email'],
      password: _passwordController.text.trim(),
    );

    if (authResponse.user != null) {
      await supabase.from('profiles').update({'last_login': DateTime.now().toIso8601String()}).eq('id', authResponse.user!.id);
      _showSuccessMessage('Login successful! Welcome Admin.');
      if (mounted) Navigator.pushReplacementNamed(context, '/admin-dashboard');
    }
  }

  Future<void> _handleRegistration() async {
    final session = supabase.auth.currentSession;
    if (session == null || session.user == null) throw Exception('No active session. Please verify OTP first.');

    final userId        = session.user!.id;
    final instituteCode = _instituteIdController.text.trim();

    final instRow = await supabase
        .from('institutes')
        .select('id, state_id, country_id')
        .eq('institute_code', instituteCode)
        .maybeSingle();

    if (instRow == null) throw Exception('Institute ID not found.');

    final instId    = instRow['id']        as int;
    final stateId   = instRow['state_id']  as int;
    final countryId = instRow['country_id'] as int;

    // Final guard: one admin per institute (RPC also checks, but fail fast)
    final existingAdmin = await supabase
        .from('admins')
        .select('id')
        .eq('institute_id', instId)
        .maybeSingle();

    if (existingAdmin != null) throw Exception('An admin is already registered for this institute.');

    // Update user metadata + password
    await supabase.auth.updateUser(UserAttributes(
      password: _passwordController.text.trim(),
      data: {
        'first_name':  _firstNameController.text.trim(),
        'last_name':   _lastNameController.text.trim(),
        'role':        'admin',
        'institute_id': instId.toString(),
        'state_id':    stateId.toString(),
        'country_id':  countryId.toString(),
      },
    ));

    // Call registration RPC (contains all DB-level constraint checks)
    final result = await supabase.rpc('register_admin_rpc', params: {
      'p_user_id':   userId,
      'p_email':     _emailController.text.trim(),
      'p_first_name': _firstNameController.text.trim(),
      'p_last_name':  _lastNameController.text.trim(),
      'p_phone':     _phoneController.text.trim(),
      'p_inst_id':   instId,
      'p_state_id':  stateId,
      'p_country_id': countryId,
    });

    if (result is Map && result['success'] != true) {
      throw Exception(result['error'] ?? 'Registration failed.');
    }

    _showSuccessMessage('Admin account created successfully!');
    if (mounted) Navigator.pushReplacementNamed(context, '/admin-dashboard');
  }

  void _showSuccessMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green, duration: const Duration(seconds: 3)));
  }

  void _showErrorMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red, duration: const Duration(seconds: 4)));
  }

  // ── Terms & Privacy dialogs (unchanged, kept from original) ─────────
  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Colors.purple.shade50]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _buildDialogHeader('Terms and Conditions', Icons.description, const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)])),
              Expanded(child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildTermsSection('Last Updated: January 15, 2026', '', isDate: true),
                  _buildTermsSection('1. Acceptance of Terms', 'By accessing the Achivo Admin Portal, you agree to these Terms. If you do not agree, do not use our services.'),
                  _buildTermsSection('2. Admin Account Registration', 'You agree to provide accurate information. You are responsible for maintaining account confidentiality.'),
                  _buildTermsSection('3. Authorized Use', 'Admin accounts are for authorized institute personnel only. Do not share credentials with unauthorized individuals.'),
                  _buildTermsSection('4. Data Privacy and Security', 'All data is encrypted and stored securely. You are responsible for maintaining confidentiality of student data.'),
                  _buildTermsSection('5. Prohibited Activities', 'Do not attempt unauthorized access, transmit malicious code, or reverse-engineer any software.'),
                  _buildTermsSection('6. Limitation of Liability', 'Achivo shall not be liable for indirect, incidental, or consequential damages.'),
                  _buildTermsSection('7. Governing Law', 'These terms are governed by the laws of India.'),
                ]),
              )),
              _buildDialogFooter(const Color(0xFF8B5CF6)),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Colors.blue.shade50]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _buildDialogHeader('Privacy Policy', Icons.privacy_tip, const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)])),
              Expanded(child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildTermsSection('Effective Date: January 15, 2026', '', isDate: true),
                  _buildTermsSection('1. Information We Collect', 'Personal identification, institute details, account authentication data, and usage data.'),
                  _buildTermsSection('2. How We Use Your Information', 'To provide services, authenticate access, communicate updates, and improve the platform.'),
                  _buildTermsSection('3. Data Security', 'End-to-end encryption, secure authentication protocols (OTP), and regular security audits.'),
                  _buildTermsSection('4. Data Sharing', 'We do not sell or rent your personal information. Sharing only with your consent or legal requirement.'),
                  _buildTermsSection('5. Your Rights', 'Access, correct, delete, or export your personal data at any time.'),
                ]),
              )),
              _buildDialogFooter(const Color(0xFF3B82F6)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader(String title, IconData icon, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: gradient, borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))),
        IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
      ]),
    );
  }

  Widget _buildDialogFooter(Color color) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('I Understand', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildTermsSection(String title, String content, {bool isDate = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: isDate ? 12 : 16, fontWeight: isDate ? FontWeight.w500 : FontWeight.bold, color: isDate ? Colors.grey[600] : Colors.grey[800])),
        if (content.isNotEmpty) ...[const SizedBox(height: 8), Text(content, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.6))],
      ]),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF3E8FF), Color(0xFFE0E7FF), Color(0xFFDBEAFE)]),
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

  Widget _buildHeader() {
    return Column(children: [
      Row(children: [
        IconButton(onPressed: () => Navigator.pushReplacementNamed(context, '/welcome'), icon: const Icon(Icons.arrow_back, size: 24), color: Colors.black87),
        const Spacer(),
      ]),
      const SizedBox(height: 20),
      const Text('Admin Portal', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 8),
      Text('Manage your institute with Achivo', style: TextStyle(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.center),
    ]);
  }

  Widget _buildTabSelector() {
    return Container(
      height: 50,
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(25)),
      child: Row(children: [
        _buildTab('Register', !_isLogin, () => setState(() { _isLogin = false; _isOtpSent = false; _isOtpVerified = false; _generateCaptcha(); })),
        _buildTab('Login',    _isLogin,  () => setState(() { _isLogin = true;  _isOtpSent = false; _isOtpVerified = false; _generateCaptcha(); })),
      ]),
    );
  }

  Widget _buildTab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: active ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)]) : null,
            borderRadius: BorderRadius.circular(21),
          ),
          child: Center(child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.grey[600], fontWeight: FontWeight.w600))),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // ── Registration-only fields ──────────────────────────────
          if (!_isLogin) ...[
            Row(children: [
              Expanded(child: _buildInputField(controller: _firstNameController, label: 'First Name', placeholder: 'Enter first name', icon: Icons.person_outline,
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null)),
              const SizedBox(width: 16),
              Expanded(child: _buildInputField(controller: _lastNameController, label: 'Last Name', placeholder: 'Enter last name', icon: Icons.person_outline,
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null)),
            ]),
            const SizedBox(height: 20),

            // Email + OTP
            _buildEmailFieldWithOTP(),
            const SizedBox(height: 20),

            // Phone
            _buildInputField(
              controller: _phoneController, label: 'Phone Number',
              placeholder: 'Enter phone number', icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 10) return 'Must be at least 10 digits';
                if (!RegExp(r'^\d+$').hasMatch(v)) return 'Numbers only';
                return null;
              },
            ),
            const SizedBox(height: 20),
          ],

          // Institute ID (both login & register)
          _buildInputField(
            controller: _instituteIdController, label: 'Institute ID (Govt)',
            placeholder: 'Enter government institute ID', icon: Icons.badge_outlined,
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 20),

          // Password (shown after OTP verified for register; always for login)
          if (_isOtpVerified || _isLogin) ...[
            _buildInputField(
              controller: _passwordController,
              label: 'Password',
              placeholder: _isLogin ? 'Enter your password' : 'Create a password',
              icon: Icons.lock_outline,
              obscureText: !_passwordVisible,
              suffixIcon: IconButton(
                icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey[500]),
                onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (!_isLogin && !_isPasswordValid(v)) return 'Min 8 chars with upper, lower, digit & special char';
                return null;
              },
            ),
            const SizedBox(height: 20),
          ],

          // Confirm Password (register only)
          if (!_isLogin && _isOtpVerified) ...[
            _buildInputField(
              controller: _confirmPasswordController,
              label: 'Confirm Password', placeholder: 'Confirm your password',
              icon: Icons.lock_outline, obscureText: !_confirmPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(_confirmPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey[500]),
                onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 20),
          ],

          // Captcha
          _buildEnhancedCaptchaField(),
          const SizedBox(height: 20),

          // Remember me / Forgot (login only)
          if (_isLogin) ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Transform.scale(scale: 0.9, child: Checkbox(
                  value: _rememberMe, onChanged: (v) => setState(() => _rememberMe = v!),
                  activeColor: const Color(0xFF8B5CF6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                )),
                Text('Remember me', style: TextStyle(color: Colors.grey[800], fontSize: 14)),
              ]),
              TextButton(onPressed: null, child: const Text('Forgot password?', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 14))),
            ]),
            const SizedBox(height: 10),
          ] else
            const SizedBox(height: 20),

          // Submit button
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity, height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
        child: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_isLogin ? 'Sign In as Admin' : 'Create Admin Account', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
        ]),
      ),
    );
  }

  Widget _buildFooter() {
    return Text.rich(
      TextSpan(
        text: 'By continuing, you agree to our ',
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
        children: [
          WidgetSpan(child: GestureDetector(onTap: _showTermsAndConditions, child: const Text('Terms of Service', style: TextStyle(color: Color(0xFF8B5CF6), decoration: TextDecoration.underline, fontSize: 14)))),
          const TextSpan(text: ' and '),
          WidgetSpan(child: GestureDetector(onTap: _showPrivacyPolicy, child: const Text('Privacy Policy', style: TextStyle(color: Color(0xFF8B5CF6), decoration: TextDecoration.underline, fontSize: 14)))),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  // ── Form Widgets ─────────────────────────────────────────────────────
  Widget _buildEmailFieldWithOTP() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text('Institute Email', style: TextStyle(color: Colors.grey[800], fontSize: 16, fontWeight: FontWeight.w500))),
      Container(
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
        child: TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(v)) return 'Enter a valid email';
            return null;
          },
          style: TextStyle(color: Colors.grey[800], fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Enter your institute email',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(Icons.mail_outline, color: Colors.grey[500], size: 20),
            suffixIcon: _isOtpVerified
                ? const Icon(Icons.verified, color: Colors.green, size: 20)
                : TextButton(
              onPressed: _isOtpSent ? null : _sendOTP,
              child: Text(_isOtpSent ? 'Sent ✓' : 'Send OTP',
                  style: TextStyle(color: _isOtpSent ? Colors.green : const Color(0xFF8B5CF6), fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
      if (_isOtpSent && !_isOtpVerified) ...[const SizedBox(height: 16), _buildOtpField()],
    ]);
  }

  Widget _buildOtpField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade50, Colors.purple.shade50]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.security, color: Colors.blue.shade600), const SizedBox(width: 8), Text('Email Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blue.shade800))]),
        const SizedBox(height: 12),
        Text('Enter the 6-digit code sent to your email', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: TextFormField(
              controller: _otpController, keyboardType: TextInputType.number, maxLength: 6, textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[800], fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 4),
              decoration: InputDecoration(hintText: '• • • • • •', hintStyle: TextStyle(color: Colors.grey[400], fontSize: 18, letterSpacing: 8), border: InputBorder.none, counterText: '', contentPadding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          )),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)]), borderRadius: BorderRadius.circular(12)),
            child: ElevatedButton(
              onPressed: _verifyOTP,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
              child: const Text('Verify', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_otpCountdown > 0 ? 'Resend in ${_otpCountdown}s' : "Didn't receive code?", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          TextButton(
            onPressed: _otpCountdown == 0 ? _resendOTP : null,
            child: Text('Resend OTP', style: TextStyle(color: _otpCountdown == 0 ? const Color(0xFF8B5CF6) : Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
      ]),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label, required String placeholder, required IconData icon,
    bool obscureText = false, TextInputType? keyboardType,
    String? Function(String?)? validator, Widget? suffixIcon, bool enabled = true,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(label, style: TextStyle(color: Colors.grey[800], fontSize: 16, fontWeight: FontWeight.w500))),
      Container(
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
        child: TextFormField(
          controller: controller, obscureText: obscureText, keyboardType: keyboardType,
          validator: validator, enabled: enabled,
          style: TextStyle(color: Colors.grey[800], fontSize: 16),
          decoration: InputDecoration(
            hintText: placeholder, hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
            prefixIcon: Icon(icon, color: Colors.grey[500], size: 20), suffixIcon: suffixIcon,
            border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    ]);
  }

  Widget _buildEnhancedCaptchaField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text('Security Verification', style: TextStyle(color: Colors.grey[800], fontSize: 16, fontWeight: FontWeight.w500))),
      Container(
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
        child: Row(children: [
          Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(16), child: Container(
            height: 50,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.purple.shade100, Colors.blue.shade100]), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
            child: Center(child: Text(_captchaText, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800], letterSpacing: 2))),
          ))),
          Expanded(flex: 2, child: TextFormField(
            controller: _captchaController,
            validator: (v) { if (v == null || v.isEmpty) return 'Enter captcha'; return null; },
            style: TextStyle(color: Colors.grey[800], fontSize: 16),
            decoration: InputDecoration(hintText: 'Enter captcha', hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
          )),
          Padding(padding: const EdgeInsets.all(8), child: IconButton(
            onPressed: () { _generateCaptcha(); _captchaController.clear(); },
            icon: const Icon(Icons.refresh, color: Color(0xFF8B5CF6)),
            style: IconButton.styleFrom(backgroundColor: Colors.purple.shade50, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          )),
        ]),
      ),
    ]);
  }
}