import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // Page control
  bool _showWelcomeForm = false;
  bool _isInitialized = false;
  bool _isCheckingSession = false;

  // Form data
  String? selectedCountry;
  String? selectedState;
  String? selectedInstitute;
  String? selectedRole;

  String? selectedCountryName;
  String? selectedStateName;
  String? selectedInstituteName;

  int? selectedCountryId;
  int? selectedStateId;
  int? selectedInstituteId;

  // Animation controllers
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late AnimationController _floatingController;
  late AnimationController _iconsController;
  late AnimationController _transitionController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _contentAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _iconsAnimation;
  late Animation<Offset> _slideAnimation;

  // Supabase data structures
  List<Map<String, dynamic>> countries = [];
  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> institutes = [];

  final List<String> roles = ['Admin', 'HOD', 'Faculty', 'Student'];

  // Loading states
  bool isLoadingStates = false;
  bool isLoadingInstitutes = false;
  bool isLoadingCountries = false;

  SupabaseClient get supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // Initialize all controllers and animations
    _backgroundController = AnimationController(
        duration: const Duration(seconds: 2), vsync: this);
    _contentController = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this);
    _floatingController = AnimationController(
        duration: const Duration(seconds: 2), vsync: this);
    _iconsController = AnimationController(
        duration: const Duration(seconds: 3), vsync: this);
    _transitionController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);

    _backgroundAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _backgroundController, curve: Curves.easeOut));
    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _contentController, curve: Curves.easeOut));
    _floatingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut));
    _iconsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _iconsController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
        begin: const Offset(1.0, 0.0), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _transitionController, curve: Curves.easeInOut));

    _backgroundController.forward();
    _contentController.forward();
    _iconsController.forward();
    _floatingController.repeat(reverse: true);

    _isInitialized = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized && countries.isEmpty && !isLoadingCountries) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Supabase.instance.isInitialized) {
          _fetchCountries();
        }
      });
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    _floatingController.dispose();
    _iconsController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }

  Future<void> _fetchCountries() async {
    if (!mounted) return;
    try {
      setState(() {
        isLoadingCountries = true;
      });
      final response = await supabase
          .from('countries')
          .select('id, name')
          .order('name');
      if (mounted) {
        setState(() {
          countries = List<Map<String, dynamic>>.from(response as List);
          isLoadingCountries = false;
        });
      }
    } catch (e) {
      print('Error fetching countries: $e');
      if (mounted) {
        setState(() {
          isLoadingCountries = false;
        });
        _showSnackBar(
            "Error loading countries. Please check your database schema.",
            isError: true);
      }
    }
  }

  Future<void> _fetchStates(String countryId) async {
    if (!mounted) return;
    try {
      setState(() {
        isLoadingStates = true;
        states.clear();
        selectedState = null;
        selectedStateName = null;
        selectedStateId = null;
        institutes.clear();
        selectedInstitute = null;
        selectedInstituteName = null;
        selectedInstituteId = null;
      });

      final response = await supabase
          .from('states')
          .select('id, name')
          .eq('country_id', int.parse(countryId))
          .order('name');

      if (mounted) {
        setState(() {
          states = List<Map<String, dynamic>>.from(response as List);
          isLoadingStates = false;
        });
      }
    } catch (e) {
      print('Error fetching states: $e');
      if (mounted) {
        setState(() {
          isLoadingStates = false;
        });
        _showSnackBar("Error loading states: ${e.toString()}", isError: true);
      }
    }
  }

  Future<void> _fetchInstitutes(String stateId) async {
    if (!mounted) return;
    try {
      setState(() {
        isLoadingInstitutes = true;
        institutes.clear();
        selectedInstitute = null;
        selectedInstituteName = null;
        selectedInstituteId = null;
      });

      final response = await supabase
          .from('institutes')
          .select('id, name')
          .eq('state_id', int.parse(stateId))
          .order('name');

      if (mounted) {
        setState(() {
          institutes = List<Map<String, dynamic>>.from(response as List);
          isLoadingInstitutes = false;
        });
      }
    } catch (e) {
      print('Error fetching institutes: $e');
      if (mounted) {
        setState(() {
          isLoadingInstitutes = false;
        });
        _showSnackBar("Error loading institutes: ${e.toString()}",
            isError: true);
      }
    }
  }

  void handleContinue() async {
    if (!isFormComplete) {
      _showSnackBar("Please complete all fields", isError: true);
      return;
    }

    String route;
    switch (selectedRole!.toLowerCase()) {
      case 'admin':
        route = '/auth-admin';
        break;
      case 'hod':
        route = '/auth-hod';
        break;
      case 'faculty':
        route = '/auth-faculty';
        break;
      case 'student':
        route = '/auth-student';
        break;
      default:
        route = '/auth-student';
    }

    Navigator.pushReplacementNamed(context, route, arguments: {
      'country_name': selectedCountryName,
      'state_name': selectedStateName,
      'institute_name': selectedInstituteName,
      'role': selectedRole,
      'country_id': selectedCountryId,
      'state_id': selectedStateId,
      'institute_id': selectedInstituteId,
    });
  }

  // ⭐ CRITICAL FIX: This function checks for existing session and redirects
  Future<void> _checkExistingSessionAndNavigate() async {
    if (_isCheckingSession) return; // Prevent multiple calls

    setState(() {
      _isCheckingSession = true;
    });

    try {
      final session = supabase.auth.currentSession;

      // Check if user has an active session
      if (session != null) {
        print('✅ Found existing session for user: ${session.user.email}');

        // Show loading dialog while checking role
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => WillPopScope(
              onWillPop: () async => false,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blue.shade50.withOpacity(0.9),
                      Colors.purple.shade50.withOpacity(0.9),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.purple.shade500),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Redirecting to your dashboard...',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                          fontFamily: 'System',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        try {
          final user = session.user;

          // Get user profile to determine role
          final profile = await supabase
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .single();

          final role = profile['role'] as String?;
          print('✅ User role: $role');

          // Close loading dialog if still open
          if (mounted) Navigator.of(context, rootNavigator: true).pop();

          // Navigate based on role using pushReplacementNamed
          if (mounted) {
            String route;
            switch (role?.toLowerCase()) {
              case 'admin':
                route = '/admin-dashboard';
                break;
              case 'hod':
                route = '/hod-dashboard';
                break;
              case 'faculty':
                route = '/faculty-dashboard';
                break;
              case 'student':
                route = '/student-dashboard';
                break;
              default:
              // Unknown role or null role, sign out and show form
                print('⚠️ Unknown role: $role, signing out');
                await supabase.auth.signOut();
                _navigateToWelcomeForm();
                return;
            }

            print('✅ Navigating to $route');
            Navigator.pushReplacementNamed(context, route);
          }
        } catch (e) {
          print('❌ Error fetching user profile: $e');
          // Close loading dialog if open
          if (mounted) {
            try {
              Navigator.of(context, rootNavigator: true).pop();
            } catch (_) {}
          }

          // Profile doesn't exist or error occurred, sign out and show form
          await supabase.auth.signOut();
          _showSnackBar('Session expired or profile error. Please sign in again.',
              isError: true);
          _navigateToWelcomeForm();
        }
      } else {
        // No active session, user needs to sign in - show the form
        print('ℹ️ No active session found, showing welcome form');
        _navigateToWelcomeForm();
      }
    } catch (e) {
      print('❌ Error checking session: $e');
      // On any error, show the form
      _showSnackBar('Unable to verify session. Please sign in.', isError: true);
      _navigateToWelcomeForm();
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingSession = false;
        });
      }
    }
  }

  void _navigateToWelcomeForm() {
    if (!mounted) return;

    if (countries.isEmpty && !isLoadingCountries) {
      _showSnackBar("Please wait while we load the data...", isError: true);
      _fetchCountries();
      return;
    }

    setState(() {
      _showWelcomeForm = true;
    });
    _transitionController.forward();
  }

  bool get isFormComplete {
    return selectedCountry != null &&
        selectedState != null &&
        selectedInstitute != null &&
        selectedRole != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildWelcomeScreen(),
          if (_showWelcomeForm)
            SlideTransition(
              position: _slideAnimation,
              child: _buildWelcomeForm(),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _backgroundAnimation,
        _contentAnimation,
        _floatingAnimation,
        _iconsAnimation,
      ]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50.withOpacity(_backgroundAnimation.value),
                Colors.purple.shade50.withOpacity(_backgroundAnimation.value),
                Colors.pink.shade50.withOpacity(_backgroundAnimation.value),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Animated gradient blobs
              Positioned(
                top: -MediaQuery.of(context).size.height * 0.25,
                left: -MediaQuery.of(context).size.width * 0.25,
                child: Transform.scale(
                  scale: _backgroundAnimation.value,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    height: MediaQuery.of(context).size.height * 0.75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.blue.shade400.withOpacity(0.20),
                          Colors.purple.shade400.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Main content
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // App Name
                        Transform.translate(
                          offset: Offset(0, 30 * (1 - _contentAnimation.value)),
                          child: Opacity(
                            opacity: _contentAnimation.value,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 32),
                              child: ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    Colors.grey.shade900,
                                    Colors.purple.shade900,
                                    Colors.grey.shade900,
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  'Achivo',
                                  style: TextStyle(
                                    fontSize:
                                    MediaQuery.of(context).size.width * 0.18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -2,
                                    height: 0.9,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Tagline
                        Transform.translate(
                          offset: Offset(0, 20 * (1 - _contentAnimation.value)),
                          child: Opacity(
                            opacity: _contentAnimation.value,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 80),
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: Text(
                                'Where student activities turn into achievements',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ⭐ CRITICAL: Next Button with Session Check
              Positioned(
                bottom: 48,
                left: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _contentAnimation.value)),
                  child: Opacity(
                    opacity: _contentAnimation.value,
                    child: Center(
                      child: Transform.translate(
                        offset: Offset(0, -4 * _floatingAnimation.value),
                        child: GestureDetector(
                          onTap: _isCheckingSession
                              ? null
                              : _checkExistingSessionAndNavigate,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: _isCheckingSession
                                      ? Colors.grey.shade300.withOpacity(0.6)
                                      : Colors.purple.shade300.withOpacity(0.6),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: LinearGradient(
                                  colors: _isCheckingSession
                                      ? [
                                    Colors.grey.shade400,
                                    Colors.grey.shade500
                                  ]
                                      : [
                                    Colors.purple.shade500,
                                    Colors.blue.shade500
                                  ],
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isCheckingSession)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                      ),
                                    )
                                  else
                                    const Text(
                                      'Next',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  if (!_isCheckingSession)
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Loading indicator
              if (isLoadingCountries)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.orange.shade700,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Loading database...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeForm() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade100,
            Colors.purple.shade100,
            Colors.pink.shade100,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blue.shade400.withOpacity(0.25),
                    Colors.purple.shade400.withOpacity(0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main form content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      onPressed: () {
                        _transitionController.reverse().then((_) {
                          if (mounted) {
                            setState(() {
                              _showWelcomeForm = false;
                            });
                          }
                        });
                      },
                      icon: const Icon(Icons.arrow_back, size: 28),
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Welcome title
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Colors.grey.shade800,
                          Colors.purple.shade800,
                          Colors.grey.shade800,
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'Welcome!',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Subtitle
                  Container(
                    margin: const EdgeInsets.only(bottom: 40),
                    child: Text(
                      'Your journey of achievements starts here',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Form section
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 350),
                        child: Column(
                          children: [
                            // Country dropdown
                            _buildCountryDropdown(),
                            const SizedBox(height: 20),

                            // State dropdown
                            _buildStateDropdown(),
                            const SizedBox(height: 20),

                            // Institute dropdown
                            _buildInstituteDropdown(),
                            const SizedBox(height: 20),

                            // Role selection
                            _buildRoleSelection(),
                            const SizedBox(height: 40),

                            // Continue button
                            _buildContinueButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your country',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: selectedCountry,
            onChanged: (value) {
              if (value != null && countries.isNotEmpty) {
                final country =
                countries.firstWhere((c) => c['id'].toString() == value);
                setState(() {
                  selectedCountry = value;
                  selectedCountryName = country['name'];
                  selectedCountryId = country['id'];
                  selectedState = null;
                  selectedStateName = null;
                  selectedStateId = null;
                  selectedInstitute = null;
                  selectedInstituteName = null;
                  selectedInstituteId = null;
                  states.clear();
                  institutes.clear();
                });
                _fetchStates(value);
              }
            },
            decoration: InputDecoration(
              hintText: isLoadingCountries
                  ? 'Loading countries...'
                  : 'Select country',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.purple.shade300),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: countries.map((country) {
              return DropdownMenuItem(
                value: country['id'].toString(),
                child: Text(country['name']),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your state',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: selectedState,
            onChanged: selectedCountry != null &&
                !isLoadingStates &&
                states.isNotEmpty
                ? (value) {
              if (value != null) {
                final state = states
                    .firstWhere((s) => s['id'].toString() == value);
                setState(() {
                  selectedState = value;
                  selectedStateName = state['name'];
                  selectedStateId = state['id'];
                  selectedInstitute = null;
                  selectedInstituteName = null;
                  selectedInstituteId = null;
                  institutes.clear();
                });
                _fetchInstitutes(value);
              }
            }
                : null,
            decoration: InputDecoration(
              hintText: isLoadingStates ? 'Loading states...' : 'Select state',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: selectedCountry != null
                  ? Colors.white.withOpacity(0.8)
                  : Colors.grey.shade100.withOpacity(0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.purple.shade300),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: states.map((state) {
              return DropdownMenuItem(
                value: state['id'].toString(),
                child: Text(state['name']),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInstituteDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your institute',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: selectedInstitute,
            onChanged: selectedState != null &&
                !isLoadingInstitutes &&
                institutes.isNotEmpty
                ? (value) {
              if (value != null) {
                final institute = institutes
                    .firstWhere((i) => i['id'].toString() == value);
                setState(() {
                  selectedInstitute = value;
                  selectedInstituteName = institute['name'];
                  selectedInstituteId = institute['id'];
                });
              }
            }
                : null,
            decoration: InputDecoration(
              hintText: isLoadingInstitutes
                  ? 'Loading institutes...'
                  : 'Select institute',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: selectedState != null
                  ? Colors.white.withOpacity(0.8)
                  : Colors.grey.shade100.withOpacity(0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.purple.shade300),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: institutes.map((institute) {
              return DropdownMenuItem(
                value: institute['id'].toString(),
                child: Text(institute['name']),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your role',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: roles.map((role) {
              return RadioListTile<String>(
                title: Text(role, style: const TextStyle(fontSize: 16)),
                value: role,
                groupValue: selectedRole,
                onChanged: (value) {
                  setState(() {
                    selectedRole = value;
                  });
                },
                activeColor: Colors.purple.shade600,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isFormComplete
                ? Colors.purple.shade300.withOpacity(0.6)
                : Colors.grey.shade300.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: isFormComplete ? 2 : 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isFormComplete ? handleContinue : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
          isFormComplete ? Colors.purple.shade500 : Colors.grey.shade400,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Continue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward,
              size: 24,
              color: Colors.white.withOpacity(0.9),
            ),
          ],
        ),
      ),
    );
  }
}