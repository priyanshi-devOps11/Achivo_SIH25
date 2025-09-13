import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onNext;

  const WelcomeScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late AnimationController _floatingController;
  late AnimationController _iconsController;

  late Animation<double> _backgroundAnimation;
  late Animation<double> _contentAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _iconsAnimation;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
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
                Positioned(
                  top:
                      MediaQuery.of(context).size.height * 0.5 -
                      MediaQuery.of(context).size.height * 0.25,
                  left:
                      MediaQuery.of(context).size.width * 0.5 -
                      MediaQuery.of(context).size.width * 0.25,
                  child: Transform.scale(
                    scale: _backgroundAnimation.value,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: MediaQuery.of(context).size.height * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.indigo.shade400.withOpacity(0.15),
                            Colors.blue.shade400.withOpacity(0.10),
                            Colors.cyan.shade400.withOpacity(0.15),
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
                Positioned(
                  bottom: 80,
                  right: 40,
                  child: Transform.scale(
                    scale: _iconsAnimation.value > 0.66 ? 1.0 : 0.5,
                    child: Opacity(
                      opacity: _iconsAnimation.value > 0.66 ? 0.05 : 0.0,
                      child: Icon(
                        Icons.menu_book,
                        size: 80,
                        color: Colors.indigo.shade600,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.5,
                  left: 20,
                  child: Transform.scale(
                    scale: _iconsAnimation.value > 0.76 ? 1.0 : 0.5,
                    child: Opacity(
                      opacity: _iconsAnimation.value > 0.76 ? 0.05 : 0.0,
                      child: Icon(
                        Icons.emoji_events,
                        size: 70,
                        color: Colors.cyan.shade600,
                      ),
                    ),
                  ),
                ),

                // Main content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                            onTap: widget.onNext,
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

                // Subtle overlay for depth
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.20),
                        Colors.transparent,
                        Colors.white.withOpacity(0.10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
