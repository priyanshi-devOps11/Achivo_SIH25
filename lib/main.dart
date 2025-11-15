import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// Import your screens
import 'package:achivo/screens/welcome_screen.dart';
import 'package:achivo/screens/auth_admin_page.dart';
import 'package:achivo/screens/auth_hod_page.dart';
import 'package:achivo/screens/auth_faculty_page.dart';
import 'package:achivo/screens/auth_student_page.dart';
import 'package:achivo/screens/student_dashboard.dart';
import 'package:achivo/screens/admin_dashboard.dart';

// Import admin dashboard pages
import 'package:achivo/dashboards_in_admin/activity_approvals.dart';
import 'package:achivo/dashboards_in_admin/user_management.dart';
import 'package:achivo/dashboards_in_admin/student_management.dart';
import 'package:achivo/dashboards_in_admin/system_settings.dart';
import 'package:achivo/dashboards_in_admin/audit_logs.dart';
import 'package:achivo/dashboards_in_admin/departments_admin_dashboard.dart';
import 'package:achivo/dashboards_in_admin/faculty_management.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: "assets/.env.local");

    final supabaseUrl = dotenv.env['NEXT_PUBLIC_SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseUrl.isEmpty) {
      throw Exception('NEXT_PUBLIC_SUPABASE_URL is not set in .env.local file');
    }

    if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
      throw Exception(
          'NEXT_PUBLIC_SUPABASE_ANON_KEY is not set in .env.local file');
    }

    print('🔄 Initializing Supabase...');
    print('   URL: ${supabaseUrl.substring(0, 30)}...');

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    print('✅ Supabase initialized successfully');

    final client = Supabase.instance.client;
    try {
      await client.from('departments').select('count').count();
      print('✅ Database connection test successful');
    } catch (e) {
      print('⚠️ Database connection test failed: $e');
    }
  } catch (e, stackTrace) {
    print('❌ Error initializing app: $e');
    print('Stack trace: $stackTrace');
  }

  runApp(const MyApp());
}

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
      home: const AppInitializer(),
      routes: {
        // Auth routes
        '/welcome': (context) => WelcomeScreen(onNext: () {}),
        '/auth-admin': (context) => const AuthAdminPage(),
        '/auth-hod': (context) => const AuthHodPage(),
        '/auth-faculty': (context) => const AuthFacultyPage(),
        '/auth-student': (context) => const AuthStudentPage(),

        // Main dashboard routes
        '/admin-dashboard': (context) => AdminDashboard(),
        '/hod-dashboard': (context) => const HODDashboardMain(),
        '/faculty-dashboard': (context) => const FacultyDashboardMain(),
        '/student-dashboard': (context) => StudentDashboard(),

        // Admin sub-pages routes
        '/admin/activities': (context) => const ActivityApprovalsPage(),
        '/admin/user-management': (context) => const UserManagementPage(),
        '/admin/students': (context) => const StudentManagementPage(),
        '/admin/system-settings': (context) => const SystemSettingsPage(),
        '/admin/departments': (context) => const DepartmentsAdminDashboardPage(),
        '/admin/faculty': (context) => const FacultyManagementPage(),
        '/admin/audit-logs': (context) => const AuditLogsPage(),
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

  static Widget _buildErrorScreen(
      BuildContext context, String title, String message) {
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

  static Widget _buildGradientButton({
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
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _checkInitialization();
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  void _setupAuthListener() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.passwordRecovery &&
          session != null &&
          mounted) {
        setState(() {
          _isInitialized = true;
        });

        Navigator.popUntil(context, (route) => route.isFirst);
        _showPasswordUpdateDialog(session.user);
      }
    });
  }

  Future<void> _checkInitialization() async {
    try {
      await Future.delayed(const Duration(milliseconds: 1000));

      if (!Supabase.instance.isInitialized) {
        throw Exception(
            'Supabase initialization failed - check your .env.local file and network connection');
      }

      final client = Supabase.instance.client;

      try {
        final urlHash = Uri.base.fragment;
        if (urlHash.isNotEmpty) {
          await client.auth.getSessionFromUrl(Uri.parse(urlHash));
        }
      } catch (e) {
        // Ignore URL hash errors
      }

      final session = client.auth.currentSession;

      if (_isInitialized) return;

      setState(() {
        _isInitialized = true;
      });

      if (mounted) {
        if (session != null) {
          final user = session.user;

          // Check if this is a password recovery session
          if (session.expiresIn != null && session.expiresIn! < 60) {
            print('Skipping role check: Detected short-lived recovery session.');
            return;
          }

          try {
            final profile = await client
                .from('profiles')
                .select('role')
                .eq('id', user.id)
                .single();

            final role = profile['role'] as String?;

            if (!mounted) return;

            switch (role) {
              case 'admin':
                Navigator.pushReplacementNamed(context, '/admin-dashboard');
                break;
              case 'hod':
                Navigator.pushReplacementNamed(context, '/hod-dashboard');
                break;
              case 'faculty':
                Navigator.pushReplacementNamed(context, '/faculty-dashboard');
                break;
              case 'student':
                Navigator.pushReplacementNamed(context, '/student-dashboard');
                break;
              default:
                await client.auth.signOut();
                Navigator.pushReplacementNamed(context, '/welcome');
            }
          } catch (e) {
            print('Profile lookup failed for user ${user.id}: $e');
            await client.auth.signOut();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/welcome');
            }
          }
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

  void _showPasswordUpdateDialog(User user) {
    final TextEditingController newPasswordController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Set New Password'),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Enter new password',
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Password must be at least 6 characters.';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Update Password'),
              onPressed: () async {
                if (dialogFormKey.currentState!.validate()) {
                  try {
                    await supabase.auth.updateUser(
                        UserAttributes(password: newPasswordController.text));

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    await supabase.auth.signOut();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Password updated successfully! Please log in.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pushReplacementNamed(context, '/welcome');
                    }
                  } catch (e) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Failed to update password: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
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
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.purple.shade500),
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.purple.shade500),
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

// Data Models for HOD Dashboard
class Faculty {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String designation;
  final int experience;
  final List<String> subjects;
  final String joiningDate;
  final String status;
  final String qualification;

  Faculty({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.designation,
    required this.experience,
    required this.subjects,
    required this.joiningDate,
    required this.status,
    required this.qualification,
  });

  static Faculty fromMap(Map<String, dynamic> map) {
    return Faculty(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      department: map['department'] ?? '',
      designation: map['designation'] ?? '',
      experience: map['experience'] ?? 0,
      subjects: List<String>.from(map['subjects'] ?? []),
      joiningDate: map['joining_date'] ?? '',
      status: map['status'] ?? '',
      qualification: map['qualification'] ?? '',
    );
  }
}

class Student {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String rollNumber;
  final String year;
  final String semester;
  final double cgpa;
  final String address;
  final String parentContact;
  final String status;
  final String admissionDate;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.rollNumber,
    required this.year,
    required this.semester,
    required this.cgpa,
    required this.address,
    required this.parentContact,
    required this.status,
    required this.admissionDate,
  });

  static Student fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      rollNumber: map['roll_number'] ?? '',
      year: map['year'] ?? '',
      semester: map['semester'] ?? '',
      cgpa: (map['cgpa'] ?? 0.0).toDouble(),
      address: map['address'] ?? '',
      parentContact: map['parent_contact'] ?? '',
      status: map['status'] ?? '',
      admissionDate: map['admission_date'] ?? '',
    );
  }
}

class ApprovalRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String type;
  final String title;
  final String description;
  final String submittedDate;
  String status;
  final String urgency;
  final List<String>? documents;

  ApprovalRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.type,
    required this.title,
    required this.description,
    required this.submittedDate,
    required this.status,
    required this.urgency,
    this.documents,
  });

  static ApprovalRequest fromMap(Map<String, dynamic> map) {
    return ApprovalRequest(
      id: map['id'].toString(),
      studentId: map['student_id'].toString(),
      studentName: map['student_name'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      submittedDate: map['submitted_date'] ?? '',
      status: map['status'] ?? '',
      urgency: map['urgency'] ?? '',
      documents: List<String>.from(map['documents'] ?? []),
    );
  }
}

// List Views for HOD Dashboard
class FacultyListView extends StatelessWidget {
  final List<Faculty> faculty;
  final String searchTerm;
  final String filterDesignation;

  const FacultyListView({
    super.key,
    required this.faculty,
    required this.searchTerm,
    required this.filterDesignation,
  });

  @override
  Widget build(BuildContext context) {
    final filteredFaculty = faculty.where((member) {
      final matchesSearch = searchTerm.isEmpty ||
          member.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
          member.email.toLowerCase().contains(searchTerm.toLowerCase());

      final matchesDesignation = filterDesignation == 'all' ||
          member.designation == filterDesignation;

      return matchesSearch && matchesDesignation;
    }).toList();

    if (filteredFaculty.isEmpty) {
      return Center(
        child: Text(
          'No faculty found matching the criteria.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredFaculty.length,
      itemBuilder: (context, index) {
        final member = filteredFaculty[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                member.name.substring(0, 1),
                style: TextStyle(
                    color: Colors.blue.shade700, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              member.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${member.designation} - ${member.email}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: member.status == 'Active'
                    ? Colors.green.shade500
                    : Colors.red.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                member.status,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Viewing ${member.name} details')),
              );
            },
          ),
        );
      },
    );
  }
}

class StudentListView extends StatelessWidget {
  final List<Student> students;
  final String searchTerm;

  const StudentListView({
    super.key,
    required this.students,
    required this.searchTerm,
  });

  @override
  Widget build(BuildContext context) {
    final filteredStudents = students.where((student) {
      return searchTerm.isEmpty ||
          student.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
          student.rollNumber.toLowerCase().contains(searchTerm.toLowerCase()) ||
          student.email.toLowerCase().contains(searchTerm.toLowerCase());
    }).toList();

    if (filteredStudents.isEmpty) {
      return Center(
        child: Text(
          'No students found matching the criteria.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.shade100,
              child: Text(
                student.name.substring(0, 1),
                style: TextStyle(
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              student.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${student.rollNumber} - ${student.year}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: student.status == 'Active'
                    ? Colors.green.shade500
                    : Colors.red.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                student.status,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Viewing ${student.name} details')),
              );
            },
          ),
        );
      },
    );
  }
}

class ApprovalRequestListView extends StatelessWidget {
  final List<ApprovalRequest> approvalRequests;
  final String searchTerm;
  final String filterStatus;
  final Future<void> Function(String, String) updateStatusCallback;

  const ApprovalRequestListView({
    super.key,
    required this.approvalRequests,
    required this.searchTerm,
    required this.filterStatus,
    required this.updateStatusCallback,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange.shade600;
      case 'Approved':
        return Colors.green.shade600;
      case 'Rejected':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRequests = approvalRequests.where((request) {
      final matchesSearch = searchTerm.isEmpty ||
          request.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
          request.studentName.toLowerCase().contains(searchTerm.toLowerCase());

      final matchesStatus =
          filterStatus == 'all' || request.status == filterStatus;

      return matchesSearch && matchesStatus;
    }).toList();

    if (filteredRequests.isEmpty) {
      return Center(
        child: Text(
          'No approval requests found matching the criteria.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredRequests.length,
      itemBuilder: (context, index) {
        final request = filteredRequests[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        request.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _getStatusColor(request.status),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        request.status,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Student: ${request.studentName}',
                    style: TextStyle(color: Colors.grey.shade700)),
                Text(
                    'Type: ${request.type} • Submitted: ${request.submittedDate}',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 8),
                Text(
                  request.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                if (request.status == 'Pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              updateStatusCallback(request.id, 'Approved'),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              updateStatusCallback(request.id, 'Rejected'),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// HOD Dashboard Implementation
class HODDashboardMain extends StatefulWidget {
  const HODDashboardMain({super.key});

  @override
  State<HODDashboardMain> createState() => _HODDashboardMainState();
}

class _HODDashboardMainState extends State<HODDashboardMain>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String searchTerm = '';
  String filterStatus = 'all';
  String filterDesignation = 'all';

  List<Faculty> faculty = [];
  List<Student> students = [];
  List<ApprovalRequest> approvalRequests = [];
  bool isLoading = true;
  bool isRefreshing = false;

  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          searchTerm = '';
          filterStatus = 'all';
          filterDesignation = 'all';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      await _loadFromSupabase();
    } catch (e) {
      print('Error loading data from Supabase: $e');
      _loadSampleData();
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadFromSupabase() async {
    try {
      final facultyResponse = await supabase
          .from('faculty')
          .select()
          .order('name', ascending: true);
      faculty = (facultyResponse as List)
          .map((data) => Faculty.fromMap(data))
          .toList();
    } catch (e) {
      print('Error loading faculty: $e');
      if (faculty.isEmpty) {
        faculty = _getSampleFaculty();
      }
    }

    try {
      final studentsResponse = await supabase
          .from('students')
          .select()
          .order('name', ascending: true);
      students = (studentsResponse as List)
          .map((data) => Student.fromMap(data))
          .toList();
    } catch (e) {
      print('Error loading students: $e');
      if (students.isEmpty) {
        students = _getSampleStudents();
      }
    }

    try {
      final requestsResponse = await supabase
          .from('approval_requests')
          .select()
          .order('submitted_date', ascending: false);
      approvalRequests = (requestsResponse as List)
          .map((data) => ApprovalRequest.fromMap(data))
          .toList();
    } catch (e) {
      print('Error loading approval requests: $e');
      if (approvalRequests.isEmpty) {
        approvalRequests = _getSampleApprovalRequests();
      }
    }
  }

  void _loadSampleData() {
    faculty = _getSampleFaculty();
    students = _getSampleStudents();
    approvalRequests = _getSampleApprovalRequests();
  }

  List<Faculty> _getSampleFaculty() {
    return [
      Faculty(
        id: '1',
        name: 'Dr. Sarah Johnson',
        email: 'sarah.johnson@university.edu',
        phone: '+1 (555) 123-4567',
        department: 'Computer Science',
        designation: 'Professor',
        experience: 12,
        subjects: ['Data Structures', 'Algorithms', 'Machine Learning'],
        joiningDate: '2012-08-15',
        status: 'Active',
        qualification: 'Ph.D in Computer Science',
      ),
      Faculty(
        id: '2',
        name: 'Prof. Michael Chen',
        email: 'michael.chen@university.edu',
        phone: '+1 (555) 234-5678',
        department: 'Computer Science',
        designation: 'Associate Professor',
        experience: 8,
        subjects: ['Database Systems', 'Web Development', 'Software Engineering'],
        joiningDate: '2016-01-20',
        status: 'Active',
        qualification: 'Ph.D in Information Technology',
      ),
    ];
  }

  List<Student> _getSampleStudents() {
    return [
      Student(
        id: '1',
        name: 'Alex Thompson',
        email: 'alex.thompson@student.edu',
        phone: '+1 (555) 111-2222',
        rollNumber: 'CS2021001',
        year: '3rd Year',
        semester: '6th Semester',
        cgpa: 8.5,
        address: '123 University Street, College Town',
        parentContact: '+1 (555) 111-3333',
        status: 'Active',
        admissionDate: '2021-08-15',
      ),
    ];
  }

  List<ApprovalRequest> _getSampleApprovalRequests() {
    return [
      ApprovalRequest(
        id: '1',
        studentId: '1',
        studentName: 'Alex Thompson',
        type: 'Leave Application',
        title: 'Medical Leave Request',
        description:
        'Requesting 2 weeks medical leave due to surgery. Attached medical certificate.',
        submittedDate: '2024-09-05',
        status: 'Pending',
        urgency: 'High',
        documents: ['medical_certificate.pdf'],
      ),
    ];
  }

  Future<void> _refreshData() async {
    setState(() => isRefreshing = true);
    await _loadData();
    setState(() => isRefreshing = false);
    _showSuccessSnackbar('Data refreshed successfully');
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _updateApprovalStatus(String requestId, String newStatus) async {
    try {
      await supabase.from('approval_requests').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', requestId);

      setState(() {
        final index = approvalRequests.indexWhere((r) => r.id == requestId);
        if (index != -1) {
          approvalRequests[index].status = newStatus;
        }
      });

      _showSuccessSnackbar('Request ${newStatus.toLowerCase()} successfully');
    } catch (e) {
      setState(() {
        final index = approvalRequests.indexWhere((r) => r.id == requestId);
        if (index != -1) {
          approvalRequests[index].status = newStatus;
        }
      });
      _showSuccessSnackbar(
          'Request ${newStatus.toLowerCase()} successfully (local update)');
      print('Error updating approval status: $e');
    }
  }

  Widget _buildSearchAndFilterRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchTerm = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name or ID...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1976D2)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF1976D2)),
            onPressed: () => _showFilterOptions(context),
            tooltip: 'Filter Options',
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    String currentTab =
    ['Faculty', 'Students', 'Approvals'][_tabController.index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter $currentTab'),
        content: Text(
            'Implement specific filtering options for the $currentTab tab here. Current Search Term: $searchTerm'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading dashboard data...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('HOD Dashboard'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isRefreshing ? Colors.yellow.shade200 : Colors.white,
            ),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleSignOut(context),
            tooltip: 'Sign Out',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.blue.shade200,
          indicatorColor: Colors.white,
          onTap: (_) {
            setState(() {
              searchTerm = '';
            });
          },
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Faculty'),
            Tab(icon: Icon(Icons.school), text: 'Students'),
            Tab(icon: Icon(Icons.assignment), text: 'Approvals'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilterRow(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                FacultyListView(
                  faculty: faculty,
                  searchTerm: searchTerm,
                  filterDesignation: filterDesignation,
                ),
                StudentListView(
                  students: students,
                  searchTerm: searchTerm,
                ),
                ApprovalRequestListView(
                  approvalRequests: approvalRequests,
                  searchTerm: searchTerm,
                  filterStatus: filterStatus,
                  updateStatusCallback: _updateApprovalStatus,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Faculty Dashboard Implementation
class FacultyDashboardMain extends StatefulWidget {
  const FacultyDashboardMain({super.key});

  @override
  State<FacultyDashboardMain> createState() => _FacultyDashboardMainState();
}

class _FacultyDashboardMainState extends State<FacultyDashboardMain> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'Faculty Portal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => _handleSignOut(context),
            tooltip: 'Logout',
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
              Icon(Icons.school, size: 100, color: Colors.green.shade400),
              const SizedBox(height: 20),
              const Text(
                'Welcome to Faculty Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Manage your classes and students',
                style: TextStyle(
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
}

// Shared sign out function
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