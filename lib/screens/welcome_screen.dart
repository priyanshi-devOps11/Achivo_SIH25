import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onNext;

  const WelcomeScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // Page control
  bool _showWelcomeForm = false;

  // ✅ Save form data to Supabase
  Future<void> _saveUserDataToSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No user logged in")),
        );
        return;
      }

      final updates = {
        'id': user.id,
        'country': selectedCountryName,
        'state': selectedStateName,
        'institute': selectedInstituteName,
        'role': selectedRole?.toLowerCase(),
        'country_id': int.tryParse(selectedCountry ?? ''),
        'state_id': int.tryParse(selectedState ?? ''),
        'institute_id': int.tryParse(selectedInstitute ?? ''),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase.from('profiles').upsert(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving profile: $e")),
        );
      }
    }
  }

  // ✅ Continue button logic
  void handleContinue() async {
    if (isFormComplete) {
      await _saveUserDataToSupabase();

      // Navigate to role-specific auth page
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

      if (mounted) {
        Navigator.pushNamed(context, route, arguments: {
          'country': selectedCountryName,
          'state': selectedStateName,
          'institute': selectedInstituteName,
          'role': selectedRole,
        });
      }
    }
  }

  // Form data
  String? selectedCountry; // This will store the ID
  String? selectedState; // This will store the ID
  String? selectedInstitute; // This will store the ID
  String? selectedRole;

  // Store names for display and saving
  String? selectedCountryName;
  String? selectedStateName;
  String? selectedInstituteName;

  // Animation controllers
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late AnimationController _floatingController;
  late AnimationController _iconsController;
  late AnimationController _transitionController;

  // Animations
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

  // Supabase data fetching functions
  Future<void> _fetchCountries() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('countries')
          .select('id, name')
          .order('name');

      if (mounted) {
        setState(() {
          countries = List<Map<String, dynamic>>.from(response as List);
        });
      }
    } catch (e) {
      print('Error fetching countries: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching countries: $e")),
        );
      }
    }
  }

  Future<void> _fetchStates(String countryId) async {
    try {
      setState(() {
        isLoadingStates = true;
        states.clear();
        selectedState = null;
        selectedStateName = null;
        institutes.clear();
        selectedInstitute = null;
        selectedInstituteName = null;
      });

      final supabase = Supabase.instance.client;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching states: $e")),
        );
      }
    }
  }

  Future<void> _fetchInstitutes(String stateId) async {
    try {
      setState(() {
        isLoadingInstitutes = true;
        institutes.clear();
        selectedInstitute = null;
        selectedInstituteName = null;
      });

      final supabase = Supabase.instance.client;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching institutes: $e")),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _iconsController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeOut),
    );

    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _floatingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _iconsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _iconsController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _transitionController, curve: Curves.easeInOut));

    _backgroundController.forward();
    _contentController.forward();
    _iconsController.forward();

    // Start floating animation and repeat
    _floatingController.repeat(reverse: true);

    // Fetch countries on init
    _fetchCountries();
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

  void _navigateToWelcomeForm() {
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
          // Welcome Screen (always present as background)
          _buildWelcomeScreen(),

          // Welcome Form (slides in from right)
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
              Positioned(
                bottom: -MediaQuery.of(context).size.height * 0.25,
                right: -MediaQuery.of(context).size.width * 0.25,
                child: Transform.scale(
                  scale: _backgroundAnimation.value,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    height: MediaQuery.of(context).size.height * 0.75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.pink.shade400.withOpacity(0.20),
                          Colors.purple.shade400.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Decorative icons
              Positioned(
                top: 80,
                left: 40,
                child: Transform.translate(
                  offset: Offset(0, _iconsAnimation.value > 0.33 ? 0 : -20),
                  child: Opacity(
                    opacity: _iconsAnimation.value > 0.33 ? 0.08 : 0.0,
                    child: Icon(
                      Icons.menu_book,
                      size: 120,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 120,
                right: 50,
                child: Transform.translate(
                  offset: Offset(0, _iconsAnimation.value > 0.43 ? 0 : -20),
                  child: Opacity(
                    opacity: _iconsAnimation.value > 0.43 ? 0.08 : 0.0,
                    child: Icon(
                      Icons.emoji_events,
                      size: 100,
                      color: Colors.purple.shade600,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 160,
                left: 50,
                child: Transform.translate(
                  offset: Offset(0, _iconsAnimation.value > 0.53 ? 0 : 20),
                  child: Opacity(
                    opacity: _iconsAnimation.value > 0.53 ? 0.08 : 0.0,
                    child: Icon(
                      Icons.groups,
                      size: 110,
                      color: Colors.pink.shade600,
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
                                    MediaQuery.of(context).size.width *
                                        0.18,
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

              // Floating Next Button
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
                          onTap: _navigateToWelcomeForm,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.shade300.withOpacity(
                                    0.6,
                                  ),
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
                                  colors: [
                                    Colors.purple.shade500,
                                    Colors.blue.shade500,
                                  ],
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Next',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
          // Background elements for form
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
                          setState(() {
                            _showWelcomeForm = false;
                          });
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
              if (value != null) {
                final country = countries.firstWhere((c) => c['id'].toString() == value);
                setState(() {
                  selectedCountry = value;
                  selectedCountryName = country['name'];
                  selectedState = null;
                  selectedStateName = null;
                  selectedInstitute = null;
                  selectedInstituteName = null;
                  states.clear();
                  institutes.clear();
                });
                _fetchStates(value);
              }
            },
            decoration: InputDecoration(
              hintText: 'Select country',
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
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
            onChanged: selectedCountry != null && !isLoadingStates && states.isNotEmpty
                ? (value) {
              if (value != null) {
                final state = states.firstWhere((s) => s['id'].toString() == value);
                setState(() {
                  selectedState = value;
                  selectedStateName = state['name'];
                  selectedInstitute = null;
                  selectedInstituteName = null;
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
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: isLoadingStates
                  ? Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade300),
                  ),
                ),
              )
                  : null,
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
            onChanged: selectedState != null && !isLoadingInstitutes && institutes.isNotEmpty
                ? (value) {
              if (value != null) {
                final institute = institutes.firstWhere((i) => i['id'].toString() == value);
                setState(() {
                  selectedInstitute = value;
                  selectedInstituteName = institute['name'];
                });
              }
            }
                : null,
            decoration: InputDecoration(
              hintText: isLoadingInstitutes ? 'Loading institutes...' : 'Select institute',
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
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: isLoadingInstitutes
                  ? Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade300),
                  ),
                ),
              )
                  : null,
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
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