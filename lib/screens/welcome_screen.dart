import 'package:flutter/material.dart';

// ------------------- WELCOME SCREEN -------------------
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late AnimationController _iconController;
  late AnimationController _buttonController;

  late Animation<double> _backgroundAnimation1;
  late Animation<double> _backgroundAnimation2;
  late Animation<double> _backgroundAnimation3;
  late Animation<double> _contentAnimation;
  late Animation<double> _iconAnimation;
  late Animation<double> _buttonFloatingAnimation;

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _backgroundAnimation1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    _backgroundAnimation2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: const Interval(0.12, 1.0, curve: Curves.easeOut),
      ),
    );

    _backgroundAnimation3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: const Interval(0.24, 1.0, curve: Curves.easeOut),
      ),
    );

    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _iconController, curve: Curves.easeOut));

    _buttonFloatingAnimation = Tween<double>(begin: 0.0, end: -4.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _backgroundController.forward();

    Future.delayed(const Duration(milliseconds: 500), () {
      _contentController.forward();
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      _iconController.forward();
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      _buttonController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    _iconController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEFF6FF),
                  Color(0xFFFAF5FF),
                  Color(0xFFFDF2F8),
                ],
              ),
            ),
          ),

          // Animated gradient shapes
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -MediaQuery.of(context).size.height * 0.25,
                    left: -MediaQuery.of(context).size.width * 0.25,
                    child: Transform.scale(
                      scale: 0.8 + 0.2 * _backgroundAnimation1.value,
                      child: Opacity(
                        opacity: _backgroundAnimation1.value * 0.2,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.75,
                          height: MediaQuery.of(context).size.height * 0.75,
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Color(0x333B82F6),
                                Color(0x26A855F7),
                                Colors.transparent,
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

          // Main content
          SafeArea(
            child: AnimatedBuilder(
              animation: _contentController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - _contentAnimation.value)),
                  child: Opacity(
                    opacity: _contentAnimation.value,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF0F172A),
                                Color(0xFF581C87),
                                Color(0xFF0F172A),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'Achivo',
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width > 600
                                    ? 120
                                    : MediaQuery.of(context).size.width > 400
                                    ? 80
                                    : 70,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Where student activities turn into achievements',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF475569),
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Floating next button
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _contentController,
              builder: (context, child) {
                return Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SetupScreen(
                            onSubmit: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RegisterLoginScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFA855F7), Color(0xFF3B82F6)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Next',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 24,
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
  }
}

// ------------------- SETUP SCREEN -------------------
// ------------------- SETUP SCREEN (Dynamic) -------------------
class SetupScreen extends StatefulWidget {
  final VoidCallback onSubmit;

  const SetupScreen({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String? selectedCountry;
  String? selectedState;
  String? selectedInstitute;

  // Country -> States -> Institutes map
  final Map<String, Map<String, List<String>>> data = {
    "India": {
      "Maharashtra": ["IIT Bombay", "Mumbai University"],
      "Karnataka": ["IISc Bangalore", "NIT Surathkal"],
    },
    "USA": {
      "California": ["Stanford University", "UC Berkeley"],
      "New York": ["Columbia University", "NYU"],
    },
    "UK": {
      "England": ["Oxford", "Cambridge"],
      "Scotland": ["University of Edinburgh", "University of Glasgow"],
    },
  };

  List<String> get states {
    if (selectedCountry != null) {
      return data[selectedCountry!]!.keys.toList();
    }
    return [];
  }

  List<String> get institutes {
    if (selectedCountry != null &&
        selectedState != null &&
        data[selectedCountry!]!.containsKey(selectedState)) {
      return data[selectedCountry!]![selectedState]!;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Setup Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Welcome 🎉",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Let's get you started on your journey 🚀",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Country Dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Select Country",
              ),
              value: selectedCountry,
              items: data.keys.map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedCountry = val;
                  selectedState = null;
                  selectedInstitute = null;
                });
              },
            ),
            const SizedBox(height: 20),

            // State Dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Select State",
              ),
              value: selectedState,
              items: states.map((s) {
                return DropdownMenuItem(value: s, child: Text(s));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedState = val;
                  selectedInstitute = null;
                });
              },
            ),
            const SizedBox(height: 20),

            // Institute Dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Select Institute",
              ),
              value: selectedInstitute,
              items: institutes.map((i) {
                return DropdownMenuItem(value: i, child: Text(i));
              }).toList(),
              onChanged: (val) => setState(() => selectedInstitute = val),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                if (selectedCountry != null &&
                    selectedState != null &&
                    selectedInstitute != null) {
                  widget.onSubmit();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all fields")),
                  );
                }
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- REGISTER / LOGIN SCREEN -------------------
class RegisterLoginScreen extends StatelessWidget {
  const RegisterLoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register / Login")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: () {}, child: const Text("Register")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () {}, child: const Text("Login")),
          ],
        ),
      ),
    );
  }
}
