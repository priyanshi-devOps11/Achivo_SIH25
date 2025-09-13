import 'package:flutter/material.dart';

class WelcomeForm extends StatefulWidget {
  final VoidCallback onNext;

  const WelcomeForm({Key? key, required this.onNext}) : super(key: key);

  @override
  State<WelcomeForm> createState() => _WelcomeFormState();
}

class _WelcomeFormState extends State<WelcomeForm>
    with TickerProviderStateMixin {
  String? selectedCountry;
  String? selectedState;
  String? selectedInstitute;
  String? selectedRole;

  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late AnimationController _glowController;

  late Animation<double> _backgroundAnimation;
  late Animation<double> _contentAnimation;
  late Animation<double> _glowAnimation;

  // Data structures
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

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeOut),
    );

    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeOut));

    _backgroundController.forward();
    _contentController.forward();
    _glowController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    _glowController.dispose();
    super.dispose();
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
      // Direct navigation to auth page
      Navigator.pushNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade100.withOpacity(_backgroundAnimation.value),
                  Colors.purple.shade100.withOpacity(
                    _backgroundAnimation.value,
                  ),
                  Colors.pink.shade100.withOpacity(_backgroundAnimation.value),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Animated gradient blobs
                Positioned(
                  top: -100,
                  left: -100,
                  child: Transform.scale(
                    scale: _backgroundAnimation.value,
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
                ),
                Positioned(
                  bottom: -100,
                  right: -100,
                  child: Transform.scale(
                    scale: _backgroundAnimation.value,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.pink.shade400.withOpacity(0.25),
                            Colors.purple.shade400.withOpacity(0.20),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height / 2 - 100,
                  left: MediaQuery.of(context).size.width / 2 - 100,
                  child: Transform.scale(
                    scale: _backgroundAnimation.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.indigo.shade400.withOpacity(0.20),
                            Colors.blue.shade400.withOpacity(0.15),
                            Colors.cyan.shade400.withOpacity(0.20),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Decorative icons
                Positioned(
                  top: 60,
                  left: 30,
                  child: AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 0.1 * _glowAnimation.value,
                        child: Icon(
                          Icons.public,
                          size: 80,
                          color: Colors.blue.shade600,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 70,
                  right: 40,
                  child: AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 0.1 * _glowAnimation.value,
                        child: Icon(
                          Icons.school,
                          size: 90,
                          color: Colors.purple.shade600,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 120,
                  left: 40,
                  child: AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 0.1 * _glowAnimation.value,
                        child: Icon(
                          Icons.map,
                          size: 100,
                          color: Colors.indigo.shade600,
                        ),
                      );
                    },
                  ),
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
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Welcome title with glow
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Stack(
                                    children: [
                                      // Glow effect
                                      Text(
                                        'Welcome!',
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          foreground: Paint()
                                            ..style = PaintingStyle.stroke
                                            ..strokeWidth = 6
                                            ..color = Colors.purple.shade200
                                                .withOpacity(0.3),
                                        ),
                                      ),
                                      // Main text
                                      ShaderMask(
                                        shaderCallback: (bounds) =>
                                            LinearGradient(
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
                                    ],
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
                                Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 350,
                                  ),
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
        },
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