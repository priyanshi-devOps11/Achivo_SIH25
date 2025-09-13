import 'package:flutter/material.dart';

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

  // Form data
  String? selectedCountry;
  String? selectedState;
  String? selectedInstitute;
  String? selectedRole;

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

  // Data structures for form
  final Map<String, String> countries = {
    'us': 'United States',
    'uk': 'United Kingdom',
    'canada': 'Canada',
    'australia': 'Australia',
    'india': 'India',
    'germany': 'Germany',
    'france': 'France',
  };

  final Map<String, Map<String, String>> states = {
    'us': {
      'ca': 'California',
      'ny': 'New York',
      'tx': 'Texas',
      'fl': 'Florida',
    },
    'uk': {'england': 'England', 'scotland': 'Scotland', 'wales': 'Wales'},
    'india': {
      'maharashtra': 'Maharashtra',
      'karnataka': 'Karnataka',
      'delhi': 'Delhi',
      'gujarat': 'Gujarat',
      'up': 'Uttar Pradesh',
    },
  };

  final Map<String, Map<String, List<String>>> institutes = {
    'us': {
      'ca': ['Stanford University', 'UC Berkeley', 'Caltech'],
      'ny': ['Columbia University', 'NYU', 'Cornell University'],
      'tx': ['University of Texas at Austin', 'Rice University'],
      'fl': ['University of Florida', 'Florida State University'],
    },
    'uk': {
      'england': [
        'Oxford University',
        'Cambridge University',
        'Imperial College London',
      ],
      'scotland': ['University of Edinburgh', 'University of Glasgow'],
      'wales': ['Cardiff University', 'Swansea University'],
    },
    'india': {
      'maharashtra': ['IIT Bombay', 'University of Mumbai', 'Pune University'],
      'karnataka': ['IIT Bangalore', 'Indian Institute of Science'],
      'delhi': ['IIT Delhi', 'Delhi University', 'Jawaharlal Nehru University'],
      'gujarat': ['IIT Gandhinagar', 'Gujarat University'],
      'up': ['IIT BHU', 'SCRIET Meerut', 'Lucknow University'],
    },
  };

  final List<String> roles = ['Admin', 'HOD', 'Faculty', 'Student'];

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
    ).animate(CurvedAnimation(parent: _transitionController, curve: Curves.easeInOut));

    _backgroundController.forward();
    _contentController.forward();
    _iconsController.forward();

    // Start floating animation and repeat
    _floatingController.repeat(reverse: true);
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

  List<String> getAvailableInstitutes() {
    if (selectedCountry != null && selectedState != null) {
      return institutes[selectedCountry]?[selectedState] ?? [];
    }
    return [];
  }

  bool get isFormComplete {
    return selectedCountry != null &&
        selectedState != null &&
        selectedInstitute != null &&
        selectedRole != null;
  }

  void handleContinue() {
    if (isFormComplete) {
      Navigator.pushNamed(context, '/auth');
    }
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
                            _buildDropdown(
                              label: 'Choose your country',
                              value: selectedCountry,
                              items: countries,
                              onChanged: (value) {
                                setState(() {
                                  selectedCountry = value;
                                  selectedState = null;
                                  selectedInstitute = null;
                                });
                              },
                              hint: 'Select country',
                            ),

                            const SizedBox(height: 20),

                            // State dropdown
                            _buildDropdown(
                              label: 'Choose your state',
                              value: selectedState,
                              items: selectedCountry != null
                                  ? states[selectedCountry!] ?? {}
                                  : {},
                              onChanged: selectedCountry != null
                                  ? (value) {
                                setState(() {
                                  selectedState = value;
                                  selectedInstitute = null;
                                });
                              }
                                  : null,
                              hint: 'Select state',
                            ),

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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required Map<String, String> items,
    required void Function(String?)? onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
            value: value,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
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
            items: items.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInstituteDropdown() {
    final availableInstitutes = getAvailableInstitutes();

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
            onChanged: availableInstitutes.isNotEmpty
                ? (value) {
              setState(() {
                selectedInstitute = value;
              });
            }
                : null,
            decoration: InputDecoration(
              hintText: 'Select institute',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: availableInstitutes.isNotEmpty
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
            ),
            items: availableInstitutes.map((institute) {
              return DropdownMenuItem(value: institute, child: Text(institute));
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
          backgroundColor: isFormComplete
              ? Colors.purple.shade500
              : Colors.grey.shade400,
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