import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Global Supabase client accessor
SupabaseClient get supabase => Supabase.instance.client;

class AuthHodPage extends StatefulWidget {
  const AuthHodPage({Key? key}) : super(key: key);

  @override
  State<AuthHodPage> createState() => _AuthHodPageState();
}

class _AuthHodPageState extends State<AuthHodPage>
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
  String? selectedGender;
  String? selectedDepartment;
  String _captchaText = '';
  int _otpCountdown = 0;

  // --- State for dynamic department loading ---
  List<String> _departmentNames = [];
  Map<String, int> _departmentIdMap = {};
  bool _departmentsLoaded = false;

  // Data from WelcomeScreen (will be overridden by route args)
  Map<String, dynamic> _profileData = {
    'institute_id': 1,
    'country_id': 1,
    'state_id': 1,
  };
  bool _isDataLoaded = false;

  final _formKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hodIdController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _otpController = TextEditingController();
  final _captchaController = TextEditingController();

  final List<String> genders = ['Male', 'Female', 'Other'];

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
    _hodIdController.dispose();
    _fatherNameController.dispose();
    _otpController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  // ======================================================
  // Data Fetch & Helpers
  // ======================================================

  Future<void> _fetchDepartments() async {
    try {
      final response = await supabase
          .from('departments')
          .select('id, name')
          .order('name', ascending: true);

      if (response is List) {
        final List<String> names = [];
        final Map<String, int> idMap = {};

        for (final dept in response) {
          final name = dept['name'] as String;
          final id = dept['id'] as int;
          names.add(name);
          idMap[name] = id;
        }

        setState(() {
          _departmentNames = names;
          _departmentIdMap = idMap;
          _departmentsLoaded = true;
          if (_departmentNames.isNotEmpty) {
            selectedDepartment = _departmentNames.first;
          }
        });
      } else {
        setState(() {
          _departmentsLoaded = true;
        });
      }
    } catch (e) {
      // Fallback mock data so UI keeps working
      setState(() {
        _departmentNames = [
          'Computer Science',
          'Information Technology',
          'Electronics',
        ];
        _departmentIdMap = {
          'Computer Science': 1,
          'Information Technology': 2,
          'Electronics': 3,
        };
        selectedDepartment = _departmentNames.first;
        _departmentsLoaded = true;
      });
      _showErrorMessage(
          'Error loading departments from DB. Using mock data for now.');
      // ignore: avoid_print
      print('Department fetch error: $e');
    }
  }

  void _generateCaptcha() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    setState(() {
      _captchaText = String.fromCharCodes(
        Iterable.generate(
          6,
              (_) => chars.codeUnitAt(random.nextInt(chars.length)),
        ),
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

  bool _isPasswordValid(String password) {
    final passwordRegex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  // ======================================================
  // OTP FLOW
  // ======================================================

  Future<void> _sendOTP() async {
    if (_emailFormKey.currentState == null ||
        !_emailFormKey.currentState!.validate()) {
      _showErrorMessage('Please enter a valid email first.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if email already registered as HOD
      final response = await supabase
          .from('hods')
          .select('email')
          .eq('email', _emailController.text.trim())
          .maybeSingle();

      if (response != null && !_isLogin) {
        _showErrorMessage(
            'Email already registered as HOD. Please use login instead.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await supabase.auth.signInWithOtp(
        email: _emailController.text.trim(),
      );

      setState(() {
        _isLoading = false;
        _isOtpSent = true;
      });

      _startOtpTimer();
      _showSuccessMessage('OTP sent successfully to your email.');
    } on AuthException catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Failed to send OTP: ${error.message}');
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Failed to send OTP: $error');
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

        // End temp session created by verifyOTP
        await supabase.auth.signOut();

        _showSuccessMessage(
            'Email verified successfully! You can now complete registration.');
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage('OTP verification failed. Please try again.');
      }
    } on AuthException catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Invalid OTP: ${error.message}');
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('OTP verification failed: $error');
    }
  }

  // ======================================================
  // SUBMIT / LOGIN / REGISTER
  // ======================================================

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (!_isLogin && !_isOtpVerified) {
        _showErrorMessage('Please verify your email first.');
        return;
      }

      // Captcha
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
        final message = error.toString().replaceFirst('Exception: ', '');
        _showErrorMessage(message);
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
      final hodResponse = await supabase
          .from('hods')
          .select('email')
          .eq('hod_id', _hodIdController.text.trim())
          .maybeSingle();

      if (hodResponse == null) {
        throw Exception('HOD not found. Please check your HOD ID.');
      }

      final authResponse = await supabase.auth.signInWithPassword(
        email: hodResponse['email'],
        password: _passwordController.text.trim(),
      );

      if (authResponse.user != null) {
        _showSuccessMessage('Login successful!');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/hod-dashboard');
        }
      } else {
        throw Exception('Login failed: Unable to create session.');
      }
    } on AuthException catch (e) {
      throw Exception(
          'Login failed: Invalid credentials or account not confirmed (${e.message}).');
    } catch (error) {
      throw Exception('Login failed: $error');
    }
  }

  /// Registration flow that guarantees the foreign key:
  /// 1. signUp -> returns userId
  /// 2. upsert into `profiles` with that id (insert if missing, update if exists)
  /// 3. insert into `hods` (FK to profiles.id is now satisfied)
  Future<void> _handleRegistration() async {
    if (_profileData['institute_id'] == null) {
      throw Exception(
          'Institute data missing from initial setup. Please go back to the Welcome screen.');
    }

    final departmentName = selectedDepartment;
    if (departmentName == null) {
      throw Exception('Please select a department.');
    }

    final departmentId = _departmentIdMap[departmentName];
    if (departmentId == null) {
      throw Exception('Department ID not found for selected department.');
    }

    final currentTime = DateTime.now().toIso8601String();
    final instituteId = _profileData['institute_id'] as int?;
    final countryId = _profileData['country_id'] as int?;
    final stateId = _profileData['state_id'] as int?;
    final confirmationTime = DateTime.now().toIso8601String();

    try {
      // 1) Sign up the auth user
      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'role': 'hod',
          'email_confirmed_at': confirmationTime,
          'email_verified': true,
        },
      );

      final user = authResponse.user;
      if (user == null) {
        throw Exception(
            'Registration failed: user is null. Check email confirmation settings in Supabase.');
      }

      final userId = user.id;

      // 2) Ensure profile row exists and is populated (UPSERT!)
      // This solves the foreign key issue even if the trigger didn't run.
      await supabase.from('profiles').upsert({
        'id': userId,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'hod',
        'phone': _phoneController.text.trim(),
        'gender': selectedGender,
        'department_id': departmentId,
        'country_id': countryId,
        'state_id': stateId,
        'institute_id': instituteId,
        'email_verified': true,
        'created_at': currentTime,
        'updated_at': currentTime,
      }, onConflict: 'id');

      // 3) Insert into HODs (FK -> profiles.id)
      await supabase.from('hods').insert({
        'user_id': userId,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'father_name': _fatherNameController.text.trim(),
        'gender': selectedGender,
        'phone': _phoneController.text.trim(),
        'hod_id': _hodIdController.text.trim(),
        'department_id': departmentId,
        'created_at': currentTime,
      });

      _showSuccessMessage(
          'Account created successfully! Redirecting to dashboard...');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/hod-dashboard');
      }
    } on AuthException catch (e) {
      throw Exception('Registration failed: ${e.message}');
    } catch (error) {
      throw Exception('Registration failed: $error');
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_hodIdController.text.isEmpty) {
      _showErrorMessage('Please enter your HOD ID first.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase
          .from('hods')
          .select('email')
          .eq('hod_id', _hodIdController.text.trim())
          .maybeSingle();

      if (response != null) {
        await supabase.auth.resetPasswordForEmail(response['email']);
        _showSuccessMessage('Password reset link sent to your email.');
      } else {
        _showErrorMessage('No account found with this HOD ID.');
      }
    } on AuthException catch (e) {
      _showErrorMessage('Failed to send reset link: ${e.message}');
    } catch (error) {
      _showErrorMessage('Failed to send reset link: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ======================================================
  // SNACKBARS
  // ======================================================

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

  // ======================================================
  // BUILD
  // ======================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _backgroundAnimation,
        child: Container(
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
              child: FadeTransition(
                opacity: _contentAnimation,
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
        ),
      ),
    );
  }

  // ======================================================
  // UI SECTIONS
  // ======================================================

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
          'HOD Portal',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Lead your department with Achivo',
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
                    text: 'No departments found (check DB)'),
                label: 'Department',
                placeholder: 'Check DB / seeding',
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
          ],
          _buildInputField(
            controller: _hodIdController,
            label: 'HOD ID',
            placeholder:
            _isLogin ? 'Enter your HOD ID' : 'Create a unique HOD ID',
            icon: Icons.badge_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter HOD ID';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
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
              if (!_isLogin && !_isPasswordValid(value)) {
                return 'Password must be 8+ chars, with upper & lower case, digit, and special char.';
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
                        ? 'Sign In as HOD'
                        : 'Create HOD Account',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.supervised_user_circle,
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
    );
  }

  // ======================================================
  // FIELD BUILDERS
  // ======================================================

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
            'Email',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Form(
          key: _emailFormKey,
          child: Container(
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
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              style: TextStyle(color: Colors.grey[800], fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Enter your email',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                prefixIcon: Icon(Icons.mail_outline,
                    color: Colors.grey[500], size: 20),
                suffixIcon: !_isLogin && !_isOtpVerified
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
                    ? const Icon(Icons.verified,
                    color: Colors.green, size: 20)
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
        if (!_isLogin && _isOtpSent && !_isOtpVerified) ...[
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
