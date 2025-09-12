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
      debugShowCheckedModeBanner: false, // removes the red debug banner
      title: 'Achivo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      // first screen when app launches
      initialRoute: '/',

      // define all routes
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/form': (context) => WelcomeForm(
          onNext: () {
            Navigator.pushNamed(context, '/auth');
          },
        ),
        '/auth': (context) => const AuthPage(),
      },
    );
  }
}
