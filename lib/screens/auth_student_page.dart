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
    Random random = Random.secure();
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

  // ============================================================
  // SEND OTP - Create account immediately but don't complete profile
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

    // Validate form fields before sending OTP
    if (!_formKey.currentState!.validate()) {
      _showErrorMessage('Please fill all required fields correctly.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('📧 Sending OTP to: ${_emailController.text.trim()}');

      // Check if email already exists in profiles (completed registrations)
      final profileResponse = await supabase
          .from('profiles')
          .select('email, email_verified')
          .eq('email', _emailController.text.trim())
          .maybeSingle();

      if (profileResponse != null) {
        // If profile exists and is verified, user should login
        if (profileResponse['email_verified'] == true) {
          _showErrorMessage(
              'Email already registered. Please use login instead.');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Use signInWithOtp which creates account and sends OTP
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
      setState(() {
        _isLoading = false;
      });
      print('❌ OTP Send Error: ${e.message}');
      _showErrorMessage('Failed to send verification code: ${e.message}');
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Unexpected Error: $error');
      _showErrorMessage('Failed to send verification code: ${error.toString()}');
    }
  }

  Future<void> _resendOTP() async {
    if (_otpCountdown == 0) {
      await _sendOTP();
    }
  }

  // ============================================================
  // VERIFY OTP - Complete the registration after verification
  // ============================================================
  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      _showErrorMessage('Please enter the 6-digit verification code.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔐 Verifying OTP: ${_otpController.text.trim()}');

      // Verify OTP using Supabase Auth
      final response = await supabase.auth.verifyOTP(
        email: _emailController.text.trim(),
        token: _otpController.text.trim(),
        type: OtpType.email,
      );

      if (response.session == null || response.user == null) {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage('Invalid verification code. Please try again.');
        return;
      }

      final userId = response.user!.id;
      print('✅ OTP verified successfully!');
      print('📧 Email confirmed: ${response.user!.emailConfirmedAt}');
      print('👤 User ID: $userId');

      // Now complete the student registration
      await _completeRegistration(userId);

    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ OTP Verification Error: ${e.message}');
      _showErrorMessage('Verification failed: ${e.message}');
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Unexpected Error: $error');
      _showErrorMessage('Verification failed: ${error.toString()}');
    }
  }

  // ============================================================
  // COMPLETE REGISTRATION - Called after OTP verification
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

      // Update auth user metadata with password
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

      // Wait for trigger to update profile
      await Future.delayed(const Duration(milliseconds: 500));

      // Call registration RPC to create student record
      print('📞 Calling register_student_rpc');
      final rpcResponse = await supabase.rpc('register_student_rpc', params: {
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
        // If registration fails, try to clean up
        try {
          await supabase.auth.signOut();
        } catch (_) {}
        throw Exception(rpcResponse?['error'] ?? 'Registration failed');
      }

      // Sign out the current session
      await supabase.auth.signOut();

      setState(() {
        _isLoading = false;
        _otpTimerController.stop();
      });

      print('✅ Registration completed successfully');

      _showSuccessMessage(
          'Account created successfully! You can now log in with your roll number.');

      // Switch to login tab after brief delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isLogin = true;
          _isOtpSent = false;
          _otpController.clear();
          _emailController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Registration completion error: $e');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  bool _isPasswordValid(String password) {
    RegExp passwordRegex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      // For registration, check OTP was sent
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

      setState(() {
        _isLoading = true;
      });

      try {
        if (_isLogin) {
          await _handleLogin();
        } else {
          // For registration, verify OTP which will complete registration
          await _verifyOTP();
        }
      } catch (error) {
        _showErrorMessage(error is Exception
            ? error.toString().replaceFirst('Exception: ', '')
            : 'An unexpected error occurred.');
      } finally {
        if (_isLogin) {
          setState(() {
            _isLoading = false;
          });
        }
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

      // Get email from roll number
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

      // Use AuthService for login
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
  // REGISTRATION - Now removed, handled by completeRegistration
  // ============================================================
  // This function is no longer needed as registration is completed
  // in _completeRegistration() after OTP verification

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
                  return 'Password must be 8+ chars with uppercase, lowercase, digit & special char';
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
                        : 'Verify OTP & Register',
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
    return Text(
      'By continuing, you agree to our Terms of Service and Privacy Policy',
      style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
              suffixIcon: TextButton(
                onPressed: _isOtpSent ? null : _sendOTP,
                child: Text(
                  _isOtpSent ? 'Sent ✓' : 'Send OTP',
                  style: TextStyle(
                    color:
                    _isOtpSent ? Colors.green : const Color(0xFF8B5CF6),
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
          Container(
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