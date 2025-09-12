import 'package:flutter/material.dart';

class WelcomeForm extends StatefulWidget {
  final VoidCallback onNext;

  const WelcomeForm({Key? key, required this.onNext}) : super(key: key);

  @override
  State<WelcomeForm> createState() => _WelcomeFormState();
}

class _WelcomeFormState extends State<WelcomeForm>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late AnimationController _iconController;

  late Animation<double> _backgroundAnimation;
  late Animation<double> _contentAnimation;
  late Animation<double> _iconAnimation;

  String _selectedCountry = '';
  String _selectedState = '';
  String _selectedInstitute = '';

  final Map<String, List<Map<String, String>>> _states = {
    'us': [
      {'value': 'ca', 'label': 'California'},
      {'value': 'ny', 'label': 'New York'},
      {'value': 'tx', 'label': 'Texas'},
      {'value': 'fl', 'label': 'Florida'},
    ],
    'uk': [
      {'value': 'england', 'label': 'England'},
      {'value': 'scotland', 'label': 'Scotland'},
      {'value': 'wales', 'label': 'Wales'},
    ],
    'india': [
      {'value': 'maharashtra', 'label': 'Maharashtra'},
      {'value': 'karnataka', 'label': 'Karnataka'},
      {'value': 'delhi', 'label': 'Delhi'},
      {'value': 'gujarat', 'label': 'Gujarat'},
    ],
    'canada': [
      {'value': 'ontario', 'label': 'Ontario'},
      {'value': 'quebec', 'label': 'Quebec'},
      {'value': 'british-columbia', 'label': 'British Columbia'},
    ],
    'australia': [
      {'value': 'nsw', 'label': 'New South Wales'},
      {'value': 'victoria', 'label': 'Victoria'},
      {'value': 'queensland', 'label': 'Queensland'},
    ],
    'germany': [
      {'value': 'bavaria', 'label': 'Bavaria'},
      {'value': 'berlin', 'label': 'Berlin'},
      {'value': 'hamburg', 'label': 'Hamburg'},
    ],
    'france': [
      {'value': 'paris', 'label': 'Île-de-France'},
      {'value': 'provence', 'label': 'Provence-Alpes-Côte d\'Azur'},
      {'value': 'rhone', 'label': 'Auvergne-Rhône-Alpes'},
    ],
  };

  final List<Map<String, String>> _countries = [
    {'value': 'us', 'label': 'United States'},
    {'value': 'uk', 'label': 'United Kingdom'},
    {'value': 'canada', 'label': 'Canada'},
    {'value': 'australia', 'label': 'Australia'},
    {'value': 'india', 'label': 'India'},
    {'value': 'germany', 'label': 'Germany'},
    {'value': 'france', 'label': 'France'},
  ];

  final List<Map<String, String>> _institutes = [
    {'value': 'harvard', 'label': 'Harvard University'},
    {'value': 'mit', 'label': 'MIT'},
    {'value': 'stanford', 'label': 'Stanford University'},
    {'value': 'oxford', 'label': 'Oxford University'},
    {'value': 'cambridge', 'label': 'Cambridge University'},
    {'value': 'iit-bombay', 'label': 'IIT Bombay'},
    {'value': 'iit-delhi', 'label': 'IIT Delhi'},
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
    super.dispose();
  }

  List<Map<String, String>> get _availableStates {
    return _states[_selectedCountry] ?? [];
  }

  bool get _canContinue {
    return _selectedCountry.isNotEmpty &&
        _selectedState.isNotEmpty &&
        _selectedInstitute.isNotEmpty;
  }

  void _handleContinue() {
    if (_canContinue) {
      widget.onNext();
    }
  }

  void _onCountryChanged(String? value) {
    setState(() {
      _selectedCountry = value ?? '';
      _selectedState = ''; // Reset state when country changes
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Brighter gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFDBEAFE), // blue-100
                  Color(0xFFE9D5FF), // purple-100
                  Color(0xFFFCE7F3), // pink-100
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
                    top: -MediaQuery.of(context).size.height * 0.25,
                    left: -MediaQuery.of(context).size.width * 0.25,
                    child: Transform.scale(
                      scale: _backgroundAnimation.value,
                      child: Opacity(
                        opacity: _backgroundAnimation.value * 0.25,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.75,
                          height: MediaQuery.of(context).size.height * 0.75,
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Color(0x403B82F6), // blue-400/25
                                Color(0x33A855F7), // purple-400/20
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
                    bottom: -MediaQuery.of(context).size.height * 0.25,
                    right: -MediaQuery.of(context).size.width * 0.25,
                    child: Transform.scale(
                      scale: _backgroundAnimation.value,
                      child: Opacity(
                        opacity: _backgroundAnimation.value * 0.25,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.75,
                          height: MediaQuery.of(context).size.height * 0.75,
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Color(0x40F472B6), // pink-400/25
                                Color(0x33A855F7), // purple-400/20
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
                    top: MediaQuery.of(context).size.height * 0.5,
                    left: MediaQuery.of(context).size.width * 0.5,
                    child: Transform.translate(
                      offset: Offset(
                        -MediaQuery.of(context).size.width * 0.25,
                        -MediaQuery.of(context).size.height * 0.25,
                      ),
                      child: Transform.scale(
                        scale: _backgroundAnimation.value,
                        child: Opacity(
                          opacity: _backgroundAnimation.value * 0.2,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.5,
                            height: MediaQuery.of(context).size.height * 0.5,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0x336366F1), // indigo-400/20
                                  Color(0x263B82F6), // blue-400/15
                                  Color(0x3306B6D4), // cyan-400/20
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Academic micro-illustrations
          AnimatedBuilder(
            animation: _iconAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Globe icon - top left
                  Positioned(
                    top: 64,
                    left: 48,
                    child: Transform.rotate(
                      angle: -0.175 * (1 - _iconAnimation.value), // -10 degrees
                      child: Opacity(
                        opacity: _iconAnimation.value * 0.1,
                        child: const Icon(
                          Icons.public,
                          size: 100,
                          color: Color(0xFF2563EB), // blue-600
                        ),
                      ),
                    ),
                  ),

                  // University icon - top right
                  Positioned(
                    top: 80,
                    right: 64,
                    child: Transform.translate(
                      offset: Offset(0, -20 * (1 - _iconAnimation.value)),
                      child: Opacity(
                        opacity: _iconAnimation.value * 0.1,
                        child: const Icon(
                          Icons.school,
                          size: 110,
                          color: Color(0xFF9333EA), // purple-600
                        ),
                      ),
                    ),
                  ),

                  // Map icon - bottom left
                  Positioned(
                    bottom: 130,
                    left: 64,
                    child: Transform.scale(
                      scale: 0.8 + 0.2 * _iconAnimation.value,
                      child: Opacity(
                        opacity: _iconAnimation.value * 0.1,
                        child: const Icon(
                          Icons.map_outlined,
                          size: 120,
                          color: Color(0xFF4F46E5), // indigo-600
                        ),
                      ),
                    ),
                  ),

                  // Map pin - bottom right
                  Positioned(
                    bottom: 64,
                    right: 80,
                    child: Transform.scale(
                      scale: 0.5 + 0.5 * _iconAnimation.value,
                      child: Opacity(
                        opacity: _iconAnimation.value * 0.06,
                        child: const Icon(
                          Icons.location_on_outlined,
                          size: 80,
                          color: Color(0xFFEC4899), // pink-600
                        ),
                      ),
                    ),
                  ),

                  // Small globe - middle right
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.5,
                    right: 32,
                    child: Transform.scale(
                      scale: 0.5 + 0.5 * _iconAnimation.value,
                      child: Opacity(
                        opacity: _iconAnimation.value * 0.06,
                        child: const Icon(
                          Icons.public,
                          size: 70,
                          color: Color(0xFF0891B2), // cyan-600
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
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.15,
                          ),

                          // Welcome headline with glow
                          Column(
                            children: [
                              Stack(
                                children: [
                                  // Glow effect
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0x33A855F7), // purple-400/20
                                          Color(0x333B82F6), // blue-400/20
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: ShaderMask(
                                      shaderCallback: (bounds) =>
                                          const LinearGradient(
                                            colors: [
                                              Color(0x33A855F7),
                                              Color(0x333B82F6),
                                            ],
                                          ).createShader(bounds),
                                      child: const Text(
                                        'Welcome!',
                                        style: TextStyle(
                                          fontSize: 50,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Main text
                                  ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                          colors: [
                                            Color(0xFF1E293B), // slate-800
                                            Color(0xFF6B21A8), // purple-800
                                            Color(0xFF1E293B), // slate-800
                                          ],
                                        ).createShader(bounds),
                                    child: const Text(
                                      'Welcome!',
                                      style: TextStyle(
                                        fontSize: 50,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Your journey of achievements starts here',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Color(0xFF334155), // slate-700
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),

                          const SizedBox(height: 48),

                          // Form section
                          Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Column(
                              children: [
                                // Country dropdown
                                _buildDropdown(
                                  label: 'Choose your country',
                                  value: _selectedCountry,
                                  items: _countries,
                                  onChanged: _onCountryChanged,
                                  placeholder: 'Select country',
                                ),

                                const SizedBox(height: 24),

                                // State dropdown
                                _buildDropdown(
                                  label: 'Choose your state',
                                  value: _selectedState,
                                  items: _availableStates,
                                  onChanged: (value) => setState(
                                    () => _selectedState = value ?? '',
                                  ),
                                  placeholder: 'Select state',
                                  enabled: _selectedCountry.isNotEmpty,
                                ),

                                const SizedBox(height: 24),

                                // Institute dropdown
                                _buildDropdown(
                                  label: 'Choose your institute',
                                  value: _selectedInstitute,
                                  items: _institutes,
                                  onChanged: (value) => setState(
                                    () => _selectedInstitute = value ?? '',
                                  ),
                                  placeholder: 'Select institute',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Continue button
                          GestureDetector(
                            onTap: _canContinue ? _handleContinue : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: Stack(
                                children: [
                                  // Glow effect
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFA855F7), // purple-400
                                          Color(0xFF3B82F6), // blue-400
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _canContinue
                                              ? Colors.purple.withOpacity(0.6)
                                              : Colors.grey.withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 48,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: _canContinue
                                              ? [
                                                  const Color(
                                                    0xFFA855F7,
                                                  ), // purple-500
                                                  const Color(
                                                    0xFF3B82F6,
                                                  ), // blue-500
                                                ]
                                              : [
                                                  const Color(
                                                    0xFF9CA3AF,
                                                  ), // gray-400
                                                  const Color(
                                                    0xFF6B7280,
                                                  ), // gray-500
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Continue',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  blurRadius: 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.chevron_right,
                                            color: Colors.white,
                                            size: 24,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(
                                                  0.3,
                                                ),
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 60),
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

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
    required String placeholder,
    bool enabled = true,
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
            color: Colors.white.withOpacity(enabled ? 0.8 : 0.5),
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
          child: DropdownButtonFormField<String>(
            value: value.isEmpty ? null : value,
            onChanged: enabled ? onChanged : null,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)), // slate-400
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
            dropdownColor: Colors.white.withOpacity(0.95),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item['value'],
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    item['label']!,
                    style: const TextStyle(
                      color: Color(0xFF374151), // slate-700
                    ),
                  ),
                ),
              );
            }).toList(),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF94A3B8), // slate-400
            ),
          ),
        ),
      ],
    );
  }
}
