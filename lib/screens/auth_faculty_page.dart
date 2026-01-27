import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

// Global Supabase client accessor (assuming it's defined in main.dart)
SupabaseClient get supabase => Supabase.instance.client;

class AuthFacultyPage extends StatefulWidget {
  const AuthFacultyPage({Key? key}) : super(key: key);

  @override
  State<AuthFacultyPage> createState() => _AuthFacultyPageState();
}

class _AuthFacultyPageState extends State<AuthFacultyPage>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late AnimationController _otpTimerController;

  late Animation<double> _backgroundAnimation;
  late Animation<double> _contentAnimation;

  bool _isLoading = false;
  bool _isLogin = true;
  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  String? selectedGender;
  String? selectedDepartment;
  List<String> selectedSubjects = [];
  String _captchaText = '';
  int _otpCountdown = 0;

  // --- State for dynamic department loading ---
  List<String> _departmentNames = [];
  Map<String, int> _departmentIdMap = {};
  bool _departmentsLoaded = false;

  // Store data from WelcomeScreen
  Map<String, dynamic> _profileData = {};
  bool _isDataLoaded = false;

  // Supabase client
  final SupabaseClient supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _facultyIdController = TextEditingController();
  final _otpController = TextEditingController();
  final _captchaController = TextEditingController();

  final List<String> genders = ['Male', 'Female', 'Other'];
  final List<String> subjects = [
    'Data Structures (DSC)',
    'Operating Systems (OS)',
    'Object Oriented Programming (OOPS)',
    'Python Programming',
    'Web Technologies (WT)'
  ];

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _otpTimerController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeOut),
    );

    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

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
    _facultyIdController.dispose();
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
    // Only validate email format before sending OTP
    if (_emailController.text.isEmpty) {
      _showErrorMessage('Please enter a valid email first.');
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text.trim())) {
      _showErrorMessage('Please enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Check if email already exists in profiles (for registration only)
      if (!_isLogin) {
        final profileResponse = await supabase
            .from('profiles')
            .select('email')
            .eq('email', _emailController.text.trim())
            .maybeSingle();

        if (profileResponse != null) {
          _showErrorMessage('Email already registered. Please use login instead.');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // 2. Send OTP using Supabase Auth
      print('📧 Sending OTP to: ${_emailController.text.trim()}');

      await supabase.auth.signInWithOtp(
        email: _emailController.text.trim(),
        emailRedirectTo: null, // No redirect needed
      );

      print('✅ OTP sent successfully');

      setState(() {
        _isLoading = false;
        _isOtpSent = true;
      });

      _startOtpTimer();
      _showSuccessMessage('OTP sent successfully! Check your email (including spam folder).');

    } on AuthException catch (error) {
      print('❌ Auth Exception: ${error.message}');
      setState(() {
        _isLoading = false;
      });

      // Handle specific Supabase Auth errors
      if (error.message.contains('Email rate limit exceeded')) {
        _showErrorMessage('Too many attempts. Please wait a few minutes and try again.');
      } else if (error.message.contains('SMTP')) {
        _showErrorMessage('Email service temporarily unavailable. Please try again in a few minutes.');
      } else {
        _showErrorMessage('Failed to send OTP: ${error.message}');
      }
    } catch (error) {
      print('❌ Unexpected error: $error');
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> _resendOTP() async {
    if (_otpCountdown == 0) {
      await _sendOTP();
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      _showErrorMessage('Please enter the 6-digit OTP.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔐 Verifying OTP: ${_otpController.text.trim()}');

      final response = await supabase.auth.verifyOTP(
        email: _emailController.text.trim(),
        token: _otpController.text.trim(),
        type: OtpType.email,
      );

      if (response.user != null) {
        print('✅ OTP verified successfully for user: ${response.user!.id}');

        setState(() {
          _isLoading = false;
          _isOtpVerified = true;
          _otpTimerController.stop();
        });

        // Sign out the temporary session
        await supabase.auth.signOut();

        _showSuccessMessage('Email verified successfully! Complete registration below.');
      }
    } on AuthException catch (error) {
      print('❌ OTP verification failed: ${error.message}');
      setState(() {
        _isLoading = false;
      });

      if (error.message.contains('expired')) {
        _showErrorMessage('OTP has expired. Please request a new one.');
        setState(() {
          _isOtpSent = false;
          _otpController.clear();
        });
      } else if (error.message.contains('invalid')) {
        _showErrorMessage('Invalid OTP. Please check and try again.');
      } else {
        _showErrorMessage('OTP verification failed: ${error.message}');
      }
    } catch (error) {
      print('❌ Unexpected error during OTP verification: $error');
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Verification failed. Please try again.');
    }
  }

  bool _isPasswordValid(String password) {
    RegExp passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      // For registration, check OTP verification
      if (!_isLogin && !_isOtpVerified) {
        _showErrorMessage('Please verify your email with OTP first');
        return;
      }

      if (!_isLogin && selectedSubjects.isEmpty) {
        _showErrorMessage('Please select at least one subject');
        return;
      }

      if (!_isLogin && selectedDepartment == null) {
        _showErrorMessage('Please select your department.');
        return;
      }

      // Captcha check before submission
      if (_captchaController.text.toUpperCase() != _captchaText) {
        _showErrorMessage('Incorrect captcha. Please try again.');
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
        _showErrorMessage(error is Exception ? error.toString().replaceFirst('Exception: ', '') : 'An unexpected error occurred.');
      } finally {
        setState(() {
          _isLoading = false;
        });
        _generateCaptcha();
        _captchaController.clear();
      }
    }
  }

  Future<void> _handleLogin() async {
    try {
      print('🔐 Starting login for Faculty ID: ${_facultyIdController.text.trim()}');

      // 1. Look up email using faculty_id
      final facultyResponse = await supabase
          .from('faculty')
          .select('email, is_active, user_id')
          .eq('faculty_id', _facultyIdController.text.trim())
          .maybeSingle();

      if (facultyResponse == null) {
        throw Exception('Faculty not found. Please check your Faculty ID.');
      }

      print('📧 Found email: ${facultyResponse['email']}');

      // 2. Check if account is active
      if (facultyResponse['is_active'] != true) {
        throw Exception('Your account is not active. Please verify your email first.');
      }

      // 3. Sign in using email and password
      final authResponse = await supabase.auth.signInWithPassword(
        email: facultyResponse['email'],
        password: _passwordController.text.trim(),
      );

      if (authResponse.user != null) {
        print('✅ Login successful');
        _showSuccessMessage('Login successful! Redirecting...');

        if (mounted) {
          // Small delay for better UX
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.pushReplacementNamed(context, '/faculty-dashboard');
        }
      }
    } on AuthException catch (e) {
      print('❌ Auth Exception: ${e.message}');

      if (e.message.contains('Invalid login credentials')) {
        throw Exception('Incorrect password. Please try again.');
      } else if (e.message.contains('Email not confirmed')) {
        throw Exception('Please verify your email before logging in.');
      } else {
        throw Exception('Login failed: ${e.message}');
      }
    } catch (error) {
      print('❌ Login error: $error');
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _handleRegistration() async {
    final departmentId = _departmentIdMap[selectedDepartment];

    if (departmentId == null) {
      throw Exception('Invalid department selection');
    }

    try {
      print('📝 Starting registration for: ${_emailController.text.trim()}');

      // 1. Create auth user with email and password
      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'role': 'faculty',
        },
        emailRedirectTo: null, // We handle verification via OTP
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create account. Please try again.');
      }

      print('👤 User created: ${authResponse.user!.id}');

      // 2. Register faculty profile using RPC
      final rpcResult = await supabase.rpc('register_faculty_rpc', params: {
        'p_user_id': authResponse.user!.id,
        'p_email': _emailController.text.trim(),
        'p_first_name': _firstNameController.text.trim(),
        'p_last_name': _lastNameController.text.trim(),
        'p_gender': selectedGender,
        'p_phone': _phoneController.text.trim(),
        'p_faculty_id': _facultyIdController.text.trim(),
        'p_dept_id': departmentId,
        'p_subjects': selectedSubjects,
        'p_inst_id': _profileData['institute_id'],
        'p_state_id': _profileData['state_id'],
        'p_country_id': _profileData['country_id'],
      });

      print('✅ Faculty registration RPC result: $rpcResult');

      // Check RPC result
      if (rpcResult is Map) {
        if (rpcResult['success'] == true) {
          final emailVerified = rpcResult['email_verified'] == true;

          if (emailVerified) {
            _showSuccessMessage('Registration successful! Redirecting to dashboard...');
            if (mounted) {
              await Future.delayed(const Duration(milliseconds: 500));
              Navigator.pushReplacementNamed(context, '/faculty-dashboard');
            }
          } else {
            _showSuccessMessage(
                'Registration successful! Please check your email to verify your account before logging in.'
            );
            if (mounted) {
              await Future.delayed(const Duration(seconds: 2));
              setState(() {
                _isLogin = true;
                _isOtpSent = false;
                _isOtpVerified = false;
              });
            }
          }
        } else {
          final errorMsg = rpcResult['error'] ?? 'Registration failed';
          throw Exception(errorMsg);
        }
      } else {
        throw Exception('Invalid response from registration');
      }
    } on AuthException catch (e) {
      print('❌ Auth Exception during registration: ${e.message}');

      if (e.message.contains('already registered')) {
        throw Exception('Email already registered. Please use login instead.');
      } else {
        throw Exception('Registration failed: ${e.message}');
      }
    } catch (error) {
      print('❌ Registration error: $error');
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_facultyIdController.text.isEmpty) {
      _showErrorMessage('Please enter your Faculty ID first');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Look up email using faculty_id
      final response = await supabase
          .from('faculty')
          .select('email')
          .eq('faculty_id', _facultyIdController.text.trim())
          .maybeSingle();

      if (response != null) {
        await supabase.auth.resetPasswordForEmail(
          response['email'],
          redirectTo: 'achivo://reset-password',
        );
        _showSuccessMessage('Password reset link sent to your email');
      } else {
        _showErrorMessage('No account found with this Faculty ID');
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

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
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

                  // Header
                  Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/welcome'),
                            icon: const Icon(Icons.arrow_back, size: 24),
                            color: Colors.black87,
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Faculty Portal',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Shape the future with Achivo',
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

                          // Department Dropdown
                          if (!_departmentsLoaded)
                            _buildInputField(
                              controller: TextEditingController(text: 'Loading departments...'),
                              label: 'Department',
                              placeholder: 'Loading...',
                              icon: Icons.business_outlined,
                              enabled: false,
                              validator: (_) => null,
                            )
                          else if (_departmentNames.isEmpty)
                            _buildInputField(
                              controller: TextEditingController(text: 'No departments found'),
                              label: 'Department',
                              placeholder: 'Check database',
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

                          // Gender field
                          _buildDropdownField(
                            label: 'Gender',
                            value: selectedGender,
                            items: genders,
                            onChanged: (value) =>
                                setState(() => selectedGender = value),
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

                          // Subjects field
                          _buildMultiSelectField(
                            label: 'Subjects',
                            selectedItems: selectedSubjects,
                            items: subjects,
                            onChanged: (selected) =>
                                setState(() => selectedSubjects = selected),
                            hint: 'Select subjects you teach',
                            icon: Icons.book_outlined,
                          ),
                          const SizedBox(height: 20),

                          // Faculty ID field
                          _buildInputField(
                            controller: _facultyIdController,
                            label: 'Faculty ID',
                            placeholder: 'Enter Faculty ID',
                            icon: Icons.badge_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter Faculty ID';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Faculty ID field (only for login)
                        if (_isLogin) ...[
                          _buildInputField(
                            controller: _facultyIdController,
                            label: 'Faculty ID',
                            placeholder: 'Enter your Faculty ID',
                            icon: Icons.badge_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your Faculty ID';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Password field
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
                            if (!_isLogin) {
                              if (!_isPasswordValid(value)) {
                                return 'Password must contain uppercase, lowercase, digit & special character';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Confirm Password field (only for registration)
                        if (!_isLogin) ...[
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

                        // Enhanced Captcha field (only for final submission)
                        _buildEnhancedCaptchaField(),
                        const SizedBox(height: 20),

                        // Forgot password (only for login)
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
                                      ? 'Sign In as Faculty'
                                      : 'Create Faculty Account',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.school,
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

  // -------------------------------------------------------------------
  // Helper Widgets
  // -------------------------------------------------------------------

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

  Widget _buildMultiSelectField({
    required String label,
    required List<String> selectedItems,
    required List<String> items,
    required void Function(List<String>) onChanged,
    required String hint,
    required IconData icon,
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
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => _buildSubjectSelectionDialog(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.grey[500], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedItems.isEmpty
                              ? hint
                              : '${selectedItems.length} subjects selected',
                          style: TextStyle(
                            color: selectedItems.isEmpty
                                ? Colors.grey[500]
                                : Colors.grey[800],
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              if (selectedItems.isNotEmpty) ...[
                const Divider(height: 1),
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: selectedItems.map((subject) {
                      return Chip(
                        label: Text(
                          subject,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onDeleted: () {
                          List<String> newSelection = List.from(selectedItems);
                          newSelection.remove(subject);
                          onChanged(newSelection);
                        },
                        backgroundColor: Colors.purple.shade100,
                        deleteIconColor: Colors.purple.shade600,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectSelectionDialog() {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Select Subjects'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: subjects.map((subject) {
                return CheckboxListTile(
                  title: Text(subject),
                  value: selectedSubjects.contains(subject),
                  onChanged: (bool? value) {
                    setDialogState(() {
                      if (value == true) {
                        selectedSubjects.add(subject);
                      } else {
                        selectedSubjects.remove(subject);
                      }
                    });
                    setState(() {});
                  },
                  activeColor: Colors.purple.shade600,
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmailFieldWithOTP() {
    if (_isLogin) {
      return const SizedBox.shrink();
    }

    Widget? emailSuffixIcon;
    if (!_isOtpSent && !_isOtpVerified) {
      emailSuffixIcon = Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: TextButton(
          onPressed: _isLoading ? null : _sendOTP,
          child: _isLoading && _isOtpSent == false
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF8B5CF6),
            ),
          )
              : const Text(
            'Send OTP',
            style: TextStyle(
              color: Color(0xFF8B5CF6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } else if (_isOtpVerified) {
      emailSuffixIcon = const Icon(Icons.check_circle, color: Colors.green);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          controller: _emailController,
          label: 'Email Address',
          placeholder: 'Enter your institutional email',
          icon: Icons.email_outlined,
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
          suffixIcon: emailSuffixIcon,
        ),

        if (_isOtpSent && !_isOtpVerified) ...[
          const SizedBox(height: 20),
          _buildEnhancedOtpField(),
        ],

        if (_isOtpVerified) const SizedBox(height: 10),
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

// Custom painter for captcha background pattern
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
