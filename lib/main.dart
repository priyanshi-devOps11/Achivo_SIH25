import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'screens/welcome_form.dart';
import 'screens/auth_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Achivo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          fontFamily: 'System', // Use system default font for better consistency
        ),

        // Define initial route
        initialRoute: '/',

        // Define all routes
        routes: {
          '/': (context) => WelcomeScreen(
            onNext: () => Navigator.pushNamed(context, '/welcome-form'),
          ),
          '/welcome-form': (context) => WelcomeForm(
            onNext: () => Navigator.pushNamed(context, '/auth'),
          ),
          '/auth': (context) => const AuthPage(),
        },

        // Handle route generation for better error handling
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(
                builder: (context) => WelcomeScreen(
                  onNext: () => Navigator.pushNamed(context, '/welcome-form'),
                ),
              );
            case '/welcome-form':
              return MaterialPageRoute(
                builder: (context) => WelcomeForm(
                  onNext: () => Navigator.pushNamed(context, '/auth'),
                ),
              );
            case '/auth':
              return MaterialPageRoute(
                builder: (context) => const AuthPage(),
              );
            default:
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Page not found!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The requested route "${settings.name}" does not exist.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/',
                                (route) => false,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Go to Home'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        );
    }
}