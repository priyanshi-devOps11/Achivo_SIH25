import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

// Global Supabase client accessor (assuming it's defined in main.dart or imported)
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
  late Animation<double> _backgroundAnimation;
  late Animation<double> _contentAnimation;
  late AnimationController _otpTimerController;

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

  VoidCallback? get _handleForgotPassword => null;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);
    _contentController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _otpTimerController = AnimationController(duration: const Duration(seconds: 60), vsync: this);

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _backgroundController, curve: Curves.easeOut));
    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOut));

    _generateCaptcha();
    _backgroundController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _contentController.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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
    _instituteIdController.dispose();
    _otpController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  void _generateCaptcha() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    setState(() {
      _captchaText = String.fromCharCodes(
        Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
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
    if (_emailController.text.isEmpty || !_formKey.currentState!.validate()) {
      _showErrorMessage('Please enter a valid email first.');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      await supabase.auth.signInWithOtp(
        email: _emailController.text.trim(),
        emailRedirectTo: Uri.parse('http://localhost:5248/#/auth-admin').toString(),
      );

      setState(() {
        _isLoading = false;
        _isOtpSent = true;
      });

      _startOtpTimer();
      _showSuccessMessage('OTP sent successfully! Check your email inbox. 📧');

    } on AuthException catch (error) {
      setState(() { _isLoading = false; });
      _showErrorMessage('OTP Error: ${error.message}');
    } catch (error) {
      setState(() { _isLoading = false; });
      _showErrorMessage('Failed to send OTP: ${error.toString()}');
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      _showErrorMessage('Please enter the 6-digit OTP.');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final response = await supabase.auth.verifyOTP(
        email: _emailController.text.trim(),
        token: _otpController.text.trim(),
        type: OtpType.email,
      );

      if (response.user != null) {
        setState(() {
          _isLoading = false;
          _isOtpVerified = true;
          _otpTimerController.stop();
        });
        await supabase.auth.signOut();

        _showSuccessMessage('Email verified successfully! 🎉 You can now create your account.');
      } else {
        setState(() { _isLoading = false; });
        _showErrorMessage('Invalid OTP. Please try again.');
      }
    } on AuthException catch (e) {
      setState(() { _isLoading = false; });
      _showErrorMessage('OTP verification failed: ${e.message}');
    } catch (error) {
      setState(() { _isLoading = false; });
      _showErrorMessage('OTP verification failed: ${error.toString()}');
    }
  }

  Future<void> _resendOTP() async {
    if (_otpCountdown == 0) {
      await _sendOTP();
    }
  }

  bool _isPasswordValid(String password) {
    RegExp passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (!_isLogin && !_isOtpVerified) {
        _showErrorMessage('Please verify your email first 📧');
        return;
      }

      // Captcha validation
      if (_captchaController.text.toUpperCase() != _captchaText) {
        _showErrorMessage('Incorrect captcha. Please try again.');
        _generateCaptcha();
        _captchaController.clear();
        return;
      }

      setState(() { _isLoading = true; });

      try {
        if (_isLogin) {
          await _handleLogin();
        } else {
          await _handleRegistration();
        }
      } catch (error) {
        _showErrorMessage(error is Exception ? error.toString().replaceFirst('Exception: ', '') : 'An unexpected error occurred.');
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

  // Two-step lookup for BIGINT ID to fix the previous data type error
  Future<void> _handleLogin() async {
    try {
      final instituteCode = _instituteIdController.text.trim();

      // 1. Find the Institute ID (BIGINT) using the Institute Code (String)
      final instituteResponse = await supabase
          .from('institutes')
          .select('id')
          .eq('institute_code', instituteCode)
          .maybeSingle();

      if (instituteResponse == null) {
        throw Exception('Institute ID not found or invalid. Check your ID.');
      }

      final instituteBigIntId = instituteResponse['id'] as int;

      // 2. Find the admin's profile (which contains the email) using the BIGINT ID
      final adminProfile = await supabase
          .from('profiles')
          .select('email, first_name')
          .eq('institute_id', instituteBigIntId) // Filter by the BIGINT ID
          .eq('role', 'admin')
          .maybeSingle();

      if (adminProfile == null) {
        throw Exception('Admin account not registered for this Institute. Please register first.');
      }

      final adminEmail = adminProfile['email'] as String;

      // 3. Sign in with the retrieved email and the provided password
      final authResponse = await supabase.auth.signInWithPassword(
        email: adminEmail,
        password: _passwordController.text.trim(),
      );

      if (authResponse.user != null) {
        // 4. Update profile for consistency (optional)
        await supabase.from('profiles').update({
          'last_login': DateTime.now().toIso8601String(),
        }).eq('id', authResponse.user!.id);

        _showSuccessMessage('Login successful! Welcome Admin.');
        if (mounted) Navigator.pushReplacementNamed(context, '/admin-dashboard');
      }
    } on AuthException catch (e) {
      throw Exception('Login failed: Invalid credentials. (${e.message})');
    } catch (error) {
      throw Exception('Login failed: ${error.toString()}');
    }
  }

  // >>>>>>>>>>>>>> FIX APPLIED HERE: REMOVED PASSWORD FROM INSERTION MAPS <<<<<<<<<<<<<<
  Future<void> _handleRegistration() async {
    if (_profileData['institute_id'] == null) {
      throw Exception('Institute data missing from initial setup.');
    }

    try {
      final currentTime = DateTime.now().toIso8601String();
      final instituteCode = _instituteIdController.text.trim();
      final initialInstituteId = _profileData['institute_id'] as int;

      // 1. Find the Institute ID (BIGINT) using the Institute Code (String)
      final instituteResponse = await supabase
          .from('institutes')
          .select('id, state_id, country_id')
          .eq('institute_code', instituteCode)
          .maybeSingle();

      if (instituteResponse == null) {
        throw Exception('Institute ID not found or invalid.');
      }

      final instituteBigIntId = instituteResponse['id'] as int;
      final stateId = instituteResponse['state_id'] as int;
      final countryId = instituteResponse['country_id'] as int;

      // 2. Check if an admin already exists for this institute_id (BIGINT)
      final existingAdmin = await supabase
          .from('profiles')
          .select('id')
          .eq('institute_id', instituteBigIntId) // Filter by the BIGINT ID
          .eq('role', 'admin')
          .maybeSingle();

      if (existingAdmin != null) {
        throw Exception('An admin is already registered for this Institute ID.');
      }

      // 3. Sign up with email and password (Creates the user and password hash in auth.users)
      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (authResponse.user != null) {
        final userId = authResponse.user!.id;

        // 4. Insert admin data into admins table
        // NOTE: 'password' REMOVED to match corrected schema and prevent NOT NULL error
        await supabase.from('admins').insert({
          'user_id': userId,
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'institute_id': instituteBigIntId, // Use the BIGINT ID
          'created_at': currentTime,
        });

        // 5. Create profile in the main 'profiles' table
        // NOTE: 'password' REMOVED to match corrected schema and prevent NOT NULL error
        await supabase.from('profiles').insert({
          'id': userId,
          'role': 'admin',
          'email': _emailController.text.trim(),
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email_verified': true,

          // Use IDs retrieved from step 1
          'institute_id': instituteBigIntId, // Use the BIGINT ID
          'state_id': stateId,
          'country_id': countryId,

          // Using data from initial screen state (optional, for consistency)
          'country': _profileData['country_name'],
          'state': _profileData['state_name'],
          'institute': _profileData['institute_name'],

          'created_at': currentTime,
        });

        _showSuccessMessage('Admin account created successfully! Redirecting...');
        if (mounted) Navigator.pushReplacementNamed(context, '/admin-dashboard');
      }
    } on AuthException catch (e) {
      throw Exception('Registration failed: ${e.message}');
    } catch (error) {
      throw Exception('Registration failed: ${error.toString()}');
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
                  Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, size: 24),
                            color: Colors.black87,
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Admin Portal',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your institute with Achivo',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Tab selector
                  Container(
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
                                    color: !_isLogin
                                        ? Colors.white
                                        : Colors.grey[600],
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
                                    color: _isLogin
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Registration fields
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

                          // Email field with OTP
                          _buildEmailFieldWithOTP(),
                          const SizedBox(height: 20),

                          // Phone field
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

                          // Institute ID field
                          _buildInputField(
                            controller: _instituteIdController,
                            label: 'Institute ID (Govt)',
                            placeholder: 'Enter government institute ID',
                            icon: Icons.badge_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter institute ID';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Institute ID field (only for login)
                        if (_isLogin) ...[
                          _buildInputField(
                            controller: _instituteIdController,
                            label: 'Institute ID (Govt)',
                            placeholder: 'Enter government institute ID',
                            icon: Icons.badge_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your institute ID';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Password field
                        // Only show password fields if email is verified OR if it's a login attempt
                        if (_isOtpVerified || _isLogin) ...[
                          _buildInputField(
                            controller: _passwordController,
                            label: 'Password',
                            placeholder: _isLogin
                                ? 'Enter your password'
                                : 'Create a password',
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
                              if (!_isLogin && !_isPasswordValid(value)) {
                                return 'Password must contain uppercase, lowercase, digit & special character';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Confirm Password (registration only)
                        if (!_isLogin && _isOtpVerified) ...[
                          _buildInputField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            placeholder: 'Confirm your password',
                            icon: Icons.lock_outline,
                            obscureText: !_confirmPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
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

                        // Captcha field
                        _buildEnhancedCaptchaField(),
                        const SizedBox(height: 20),

                        // Remember me and forgot password (login only)
                        if (_isLogin) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Transform.scale(
                                    scale: 0.9,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) =>
                                          setState(() => _rememberMe = value!),
                                      activeColor: const Color(0xFF8B5CF6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Remember me',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
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
                            ],
                          ),
                          const SizedBox(height: 10),
                        ] else
                          const SizedBox(height: 20),

                        // Submit button
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
                                      ? 'Sign In as Admin'
                                      : 'Create Admin Account',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.admin_panel_settings,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Footer
                  Text.rich(
                    TextSpan(
                      text: 'By continuing, you agree to our ',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      children: const [
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: Color(0xFF8B5CF6),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: Color(0xFF8B5CF6),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
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

  Widget _buildEmailFieldWithOTP() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Institute Email',
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
                return 'Please enter your institute email';
              }
              // Relaxed Regex for general validation
              if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                  .hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
            style: TextStyle(color: Colors.grey[800], fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Enter your institute email',
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

        // OTP Field (only shows when OTP is sent and not verified, and not on login)
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
            'Enter the 6-digit code sent to your email inbox.',
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    ? 'Resend in ${_otpCountdown}s'
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
                    child: Center(
                      child: Text(
                        _captchaText,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          letterSpacing: 2,
                        ),
                      ),
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
                    // Captcha validation is handled in _handleSubmit for better UX
                    return null;
                  },
                  style: TextStyle(color: Colors.grey[800], fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Enter captcha',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
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