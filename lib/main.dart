import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your screens
import 'package:achivo/screens/welcome_screen.dart';
import 'package:achivo/screens/auth_admin_page.dart';
import 'package:achivo/screens/auth_hod_page.dart';
import 'package:achivo/screens/auth_faculty_page.dart';
import 'package:achivo/screens/auth_student_page.dart';
import 'package:achivo/screens/hod_dashboard.dart';
import 'package:achivo/screens/student_dashboard.dart';
// Import the admin dashboard from your admin_dashboard.dart file
import 'package:achivo/screens/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables - note the path change
    await dotenv.load(fileName: "assets/.env.local");

    // Validate required environment variables
    final supabaseUrl = dotenv.env['NEXT_PUBLIC_SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseUrl.isEmpty) {
      throw Exception('NEXT_PUBLIC_SUPABASE_URL is not set in .env.local file');
    }

    if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
      throw Exception('NEXT_PUBLIC_SUPABASE_ANON_KEY is not set in .env.local file');
    }

    print('🔄 Initializing Supabase...');
    print('   URL: ${supabaseUrl.substring(0, 30)}...');

    // Initialize Supabase with proper configuration
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true, // Enable for debugging
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    print('✅ Supabase initialized successfully');

    // Test connection
    final client = Supabase.instance.client;
    final response = await client.from('countries').select('count').count();
    print('✅ Database connection test successful');

  } catch (e, stackTrace) {
    print('❌ Error initializing app: $e');
    print('Stack trace: $stackTrace');
    // Continue with app but show error state
  }

  runApp(const MyApp());
}

// Global Supabase client accessor
SupabaseClient get supabase => Supabase.instance.client;

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
        fontFamily: 'System',
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: Colors.purple.shade500,
          linearTrackColor: Colors.grey.shade300,
        ),
      ),

      // Start with initialization checker
      home: const AppInitializer(),

      // Define all routes
      routes: {
        '/welcome': (context) => WelcomeScreen(onNext: () {}),
        '/auth-admin': (context) => const AuthAdminPage(),
        '/auth-hod': (context) => const AuthHodPage(),
        '/auth-faculty': (context) => const AuthFacultyPage(),
        '/auth-student': (context) => const AuthStudentPage(),
        '/hod-dashboard': (context) => const HODDashboard(),
        '/admin-dashboard': (context) => AdminDashboard(), // Updated to use the correct AdminDashboard
        '/faculty-dashboard': (context) => const FacultyDashboard(),
        '/student-dashboard': (context) => StudentDashboard(), // Updated to use the correct StudentDashboard

        // Additional routes for admin dashboard sub-pages
        '/admin/departments': (context) => DepartmentsPage(),
        '/admin/faculty': (context) => FacultyPage(),
        '/admin/students': (context) => StudentsPage(),
        '/admin/activities': (context) => ActivitiesPage(),
        '/admin/portfolios': (context) => PortfoliosPage(),
        '/admin/reports': (context) => ReportsPage(),
        '/admin/settings': (context) => SettingsPage(),
      },

      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => _buildErrorScreen(
            context,
            'Page not found!',
            'The requested route "${settings.name}" does not exist.',
          ),
        );
      },
    );
  }

  Widget _buildErrorScreen(BuildContext context, String title, String message) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3E8FF),
              Color(0xFFE0E7FF),
              Color(0xFFDBEAFE),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildGradientButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/welcome',
                        (route) => false,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Go to Home',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFF3B82F6),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
        child: child,
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _checkInitialization();
  }

  Future<void> _checkInitialization() async {
    try {
      // Wait for initialization to complete
      await Future.delayed(const Duration(milliseconds: 1000));

      if (!Supabase.instance.isInitialized) {
        throw Exception('Supabase initialization failed - check your .env.local file and network connection');
      }

      // Test basic connectivity
      final client = Supabase.instance.client;

      // Simple auth check (doesn't require authentication)
      final session = client.auth.currentSession;

      setState(() {
        _isInitialized = true;
      });

      // Navigate after successful initialization
      if (mounted) {
        // Check if user is already logged in and redirect to appropriate dashboard
        if (session != null) {
          final user = session.user;
          // You can add user role checking logic here
          // For now, navigate to welcome screen
          Navigator.pushReplacementNamed(context, '/welcome');
        } else {
          Navigator.pushReplacementNamed(context, '/welcome');
        }
      }

    } catch (e) {
      print('Initialization error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = _getReadableError(e.toString());
          _isRetrying = false;
        });
      }
    }
  }

  String _getReadableError(String error) {
    if (error.contains('env.local')) {
      return 'Environment file not found. Make sure assets/.env.local exists with your Supabase credentials.';
    } else if (error.contains('SUPABASE_URL')) {
      return 'Supabase URL is missing. Check your .env.local file.';
    } else if (error.contains('SUPABASE_ANON_KEY')) {
      return 'Supabase anonymous key is missing. Check your .env.local file.';
    } else if (error.contains('network') || error.contains('connection')) {
      return 'Network connection failed. Check your internet connection.';
    } else {
      return 'Initialization failed: ${error.length > 100 ? error.substring(0, 100) + '...' : error}';
    }
  }

  Future<void> _retryInitialization() async {
    setState(() {
      _errorMessage = null;
      _isInitialized = false;
      _isRetrying = true;
    });
    await _checkInitialization();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3E8FF),
              Color(0xFFE0E7FF),
              Color(0xFFDBEAFE),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.grey.shade900,
                      Colors.purple.shade900,
                      Colors.grey.shade900,
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'Achivo',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -2,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                if (_errorMessage == null && !_isRetrying) ...[
                  // Loading state
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade500),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Initializing app...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ] else if (_isRetrying) ...[
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade500),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Retrying initialization...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ] else ...[
                  // Error state
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to initialize',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _retryInitialization,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade500,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Remove the duplicate dashboard classes since they should be in separate files
// Keep only the original basic dashboard classes or remove them entirely
// if you're using the ones from your separate files

class HODDashboard extends StatelessWidget {
  const HODDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildDashboard(
      context,
      title: 'HOD Dashboard',
      color: Colors.indigo.shade400,
      icon: Icons.supervisor_account,
      welcomeText: 'Welcome to HOD Dashboard',
      subtitle: 'Manage your department here',
    );
  }
}

class FacultyDashboard extends StatelessWidget {
  const FacultyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildDashboard(
      context,
      title: 'Faculty Dashboard',
      color: Colors.green.shade400,
      icon: Icons.school,
      welcomeText: 'Welcome to Faculty Dashboard',
      subtitle: 'Manage your classes and students',
    );
  }
}

Widget _buildDashboard(
    BuildContext context, {
      required String title,
      required Color color,
      required IconData icon,
      required String welcomeText,
      required String subtitle,
    }) {
  return Scaffold(
    appBar: AppBar(
      title: Text(title),
      backgroundColor: color,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: () => _handleSignOut(context),
          icon: const Icon(Icons.logout),
          tooltip: 'Sign Out',
        ),
      ],
    ),
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF3E8FF),
            Color(0xFFE0E7FF),
            Color(0xFFDBEAFE),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 100, color: color),
            const SizedBox(height: 20),
            Text(
              welcomeText,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _handleSignOut(BuildContext context) async {
  try {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/welcome',
            (route) => false,
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }
}