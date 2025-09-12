import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late AnimationController _iconController;

  late Animation<double> _backgroundAnimation;
  late Animation<double> _contentAnimation;
  late Animation<double> _iconAnimation;

  bool _isLoading = false;
  bool _isLogin = false;
  bool _rememberMe = false;

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeOut),
    );

    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _iconController, curve: Curves.easeOut));

    // Start animations
    _backgroundController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _contentController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      _iconController.forward();
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    _iconController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Enhanced gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF1F5F9), // indigo-50
                  Color(0xFFFAF5FF), // purple-50
                  Color(0xFFEFF6FF), // blue-50
                ],
              ),
            ),
          ),

          // Animated gradient shapes
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Top left gradient blob
                  Positioned(
                    top: -MediaQuery.of(context).size.height * 0.3,
                    left: -MediaQuery.of(context).size.width * 0.25,
                    child: Transform.scale(
                      scale: _backgroundAnimation.value,
                      child: Opacity(
                        opacity: _backgroundAnimation.value * 0.2,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          height: MediaQuery.of(context).size.height * 0.8,
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Color(0x336366F1), // indigo-400/20
                                Color(0x26A855F7), // purple-400/15
                                Colors.transparent,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom right gradient blob
                  Positioned(
                    bottom: -MediaQuery.of(context).size.height * 0.3,
                    right: -MediaQuery.of(context).size.width * 0.25,
                    child: Transform.scale(
                      scale: _backgroundAnimation.value,
                      child: Opacity(
                        opacity: _backgroundAnimation.value * 0.2,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          height: MediaQuery.of(context).size.height * 0.8,
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Color(0x333B82F6), // blue-400/20
                                Color(0x2606B6D4), // cyan-400/15
                                Colors.transparent,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Center gradient blob
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.33,
                    left: MediaQuery.of(context).size.width * 0.33,
                    child: Transform.scale(
                      scale: _backgroundAnimation.value,
                      child: Opacity(
                        opacity: _backgroundAnimation.value * 0.15,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.5,
                          height: MediaQuery.of(context).size.height * 0.5,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0x26A855F7), // purple-400/15
                                Color(0x1A6366F1), // indigo-400/10
                                Color(0x263B82F6), // blue-400/15
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Decorative icons
          AnimatedBuilder(
            animation: _iconAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Book icon - top left
                  Positioned(
                    top: 80,
                    left: 60,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _iconAnimation.value)),
                      child: Transform.rotate(
                        angle:
                            -0.087 * (1 - _iconAnimation.value), // -5 degrees
                        child: Opacity(
                          opacity: _iconAnimation.value * 0.06,
                          child: const Icon(
                            Icons.book_outlined,
                            size: 90,
                            color: Color(0xFF6366F1), // indigo-500
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Award icon - top right
                  Positioned(
                    top: 130,
                    right: 80,
                    child: Transform.scale(
                      scale: 0.8 + 0.2 * _iconAnimation.value,
                      child: Opacity(
                        opacity: _iconAnimation.value * 0.06,
                        child: const Icon(
                          Icons.emoji_events_outlined,
                          size: 80,
                          color: Color(0xFFA855F7), // purple-500
                        ),
                      ),
                    ),
                  ),

                  // Users icon - bottom left
                  Positioned(
                    bottom: 130,
                    left: 50,
                    child: Transform.translate(
                      offset: Offset(-20 * (1 - _iconAnimation.value), 0),
                      child: Opacity(
                        opacity: _iconAnimation.value * 0.06,
                        child: const Icon(
                          Icons.people_outline,
                          size: 85,
                          color: Color(0xFF3B82F6), // blue-500
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Main content
          SafeArea(
            child: AnimatedBuilder(
              animation: _contentAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - _contentAnimation.value)),
                  child: Opacity(
                    opacity: _contentAnimation.value,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 60),

                          // Header
                          Column(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      colors: [
                                        Color(0xFF1E293B), // slate-800
                                        Color(0xFF3730A3), // indigo-800
                                        Color(0xFF1E293B), // slate-800
                                      ],
                                    ).createShader(bounds),
                                child: const Text(
                                  'Join Achivo',
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Start your achievement journey today',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF475569), // slate-600
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          // Auth tabs and form
                          Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Column(
                              children: [
                                // Tab selector
                                Container(
                                  margin: const EdgeInsets.only(bottom: 32),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () =>
                                              setState(() => _isLogin = false),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: !_isLogin
                                                  ? const LinearGradient(
                                                      colors: [
                                                        Color(
                                                          0xFF6366F1,
                                                        ), // indigo-500
                                                        Color(
                                                          0xFFA855F7,
                                                        ), // purple-500
                                                      ],
                                                    )
                                                  : null,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              'Register',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: !_isLogin
                                                    ? Colors.white
                                                    : const Color(0xFF475569),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () =>
                                              setState(() => _isLogin = true),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: _isLogin
                                                  ? const LinearGradient(
                                                      colors: [
                                                        Color(
                                                          0xFF6366F1,
                                                        ), // indigo-500
                                                        Color(
                                                          0xFFA855F7,
                                                        ), // purple-500
                                                      ],
                                                    )
                                                  : null,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              'Login',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: _isLogin
                                                    ? Colors.white
                                                    : const Color(0xFF475569),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Form
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      // Full Name field (only for registration)
                                      if (!_isLogin) ...[
                                        _buildInputField(
                                          controller: _fullNameController,
                                          label: 'Full Name',
                                          placeholder: 'Enter your full name',
                                          icon: Icons.person_outline,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter your full name';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 20),
                                      ],

                                      // Email field
                                      _buildInputField(
                                        controller: _emailController,
                                        label: 'Email',
                                        placeholder: 'Enter your email',
                                        icon: Icons.mail_outline,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your email';
                                          }
                                          if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                          ).hasMatch(value)) {
                                            return 'Please enter a valid email';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),

                                      // Password field
                                      _buildInputField(
                                        controller: _passwordController,
                                        label: 'Password',
                                        placeholder: _isLogin
                                            ? 'Enter your password'
                                            : 'Create a password',
                                        icon: Icons.lock_outline,
                                        obscureText: true,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your password';
                                          }
                                          if (!_isLogin && value.length < 6) {
                                            return 'Password must be at least 6 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),

                                      // Confirm Password field (only for registration)
                                      if (!_isLogin) ...[
                                        _buildInputField(
                                          controller:
                                              _confirmPasswordController,
                                          label: 'Confirm Password',
                                          placeholder: 'Confirm your password',
                                          icon: Icons.lock_outline,
                                          obscureText: true,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please confirm your password';
                                            }
                                            if (value !=
                                                _passwordController.text) {
                                              return 'Passwords do not match';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 20),
                                      ],

                                      // Remember me and forgot password (only for login)
                                      if (_isLogin) ...[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Checkbox(
                                                  value: _rememberMe,
                                                  onChanged: (value) =>
                                                      setState(
                                                        () => _rememberMe =
                                                            value!,
                                                      ),
                                                  activeColor: const Color(
                                                    0xFF6366F1,
                                                  ),
                                                ),
                                                const Text(
                                                  'Remember me',
                                                  style: TextStyle(
                                                    color: Color(0xFF475569),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                // Handle forgot password
                                              },
                                              child: const Text(
                                                'Forgot password?',
                                                style: TextStyle(
                                                  color: Color(0xFF6366F1),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                      ] else
                                        const SizedBox(height: 20),

                                      // Submit button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: _isLoading
                                              ? null
                                              : _handleSubmit,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(
                                                    0xFF6366F1,
                                                  ), // indigo-500
                                                  Color(
                                                    0xFFA855F7,
                                                  ), // purple-500
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 10,
                                                  spreadRadius: 0,
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                  : Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          _isLogin
                                                              ? 'Sign In'
                                                              : 'Create Account',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        const Icon(
                                                          Icons.chevron_right,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Footer
                          Opacity(
                            opacity: _contentAnimation.value,
                            child: Text.rich(
                              TextSpan(
                                text: 'By continuing, you agree to our ',
                                style: const TextStyle(
                                  color: Color(0xFF64748B), // slate-500
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: const TextStyle(
                                      color: Color(0xFF6366F1), // indigo-600
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: const TextStyle(
                                      color: Color(0xFF6366F1), // indigo-600
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF374151), // slate-700
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE2E8F0).withOpacity(0.5), // slate-200/50
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)), // slate-400
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF94A3B8), // slate-400
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
