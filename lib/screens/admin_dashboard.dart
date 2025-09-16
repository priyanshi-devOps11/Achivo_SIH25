import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase - Replace with your actual credentials
  await Supabase.initialize(
    url: 'NEXT_PUBLIC_SUPABASE_URL', // Replace with your Supabase URL
    anonKey: 'NEXT_PUBLIC_SUPABASE_ANON_KEY', // Replace with your Supabase anon key
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Student Hub - Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),

        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: AuthWrapper(),
      routes: {
        '/dashboard': (context) => AdminDashboard(),
        '/departments': (context) => DepartmentsPage(),
        '/faculty': (context) => FacultyPage(),
        '/students': (context) => StudentsPage(),
        '/activities': (context) => ActivitiesPage(),
        '/portfolios': (context) => PortfoliosPage(),
        '/reports': (context) => ReportsPage(),
        '/settings': (context) => SettingsPage(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getInitialSession();
    _setupAuthListener();
  }

  void _getInitialSession() {
    final session = supabase.auth.currentSession;
    setState(() {
      _user = session?.user;
      _isLoading = false;
    });
  }

  void _setupAuthListener() {
    supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        _user = data.session?.user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }
    return _user != null ? AdminDashboard() : LoginScreen();
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        // Navigation handled by AuthWrapper
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Smart Student Hub',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      obscureText: true,
                    ),
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Text('Sign In'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Data variables
  List<DepartmentData> departmentData = [];
  List<MonthlyTrendData> monthlyTrendData = [];
  List<RecentActivity> recentActivities = [];
  List<ActivityApprovalData> activityApprovalData = [];

  // Stats
  int totalDepartments = 0;
  int totalFaculty = 0;
  int totalStudents = 0;
  int pendingApprovals = 0;

  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadDepartments(),
        _loadOverallStats(),
      ]);
    } catch (error) {
      print('Error loading data: $error');
      _loadSampleData(); // Fallback to sample data
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _loadData();
    setState(() => _isRefreshing = false);
    _showSnackBar('Data refreshed successfully', Colors.green);
  }

  Future<void> _loadDepartments() async {
    try {
      final response = await supabase
          .from('departments')
          .select('name');

      if (response != null && response is List) {
        departmentData = response
            .map<DepartmentData>((item) => DepartmentData(
          name: item['name'] ?? 'Unknown',
          students: 0, // Default values since we don't have these fields
          faculty: 0,
        ))
            .toList();
      }
    } catch (error) {
      print('Error loading departments: $error');
    }
  }

  Future<void> _loadOverallStats() async {
    try {
      // Get departments count - using simple select and counting in Dart
      final departmentsResponse = await supabase
          .from('departments')
          .select();

      // Get profiles count by role
      final profilesResponse = await supabase
          .from('profiles')
          .select();

      setState(() {
        totalDepartments = (departmentsResponse as List?)?.length ?? 0;
        totalFaculty = 0; // Will be calculated from profiles
        totalStudents = 0; // Will be calculated from profiles
        pendingApprovals = 0; // Default value
      });

      // Calculate role-based counts if we have profile data
      if (profilesResponse != null && profilesResponse is List) {
        final profiles = profilesResponse as List;
        int facultyCount = 0;
        int studentCount = 0;

        for (var profile in profiles) {
          final role = profile['role'] as String?;
          if (role == 'faculty' || role == 'hod') {
            facultyCount++;
          } else if (role == 'student') {
            studentCount++;
          }
        }

        setState(() {
          totalFaculty = facultyCount;
          totalStudents = studentCount;
        });
      }

    } catch (error) {
      print('Error loading overall stats: $error');
    }
  }

  void _loadSampleData() {
    // Sample data for demonstration
    departmentData = [
      DepartmentData(name: "Computer Science", students: 145, faculty: 12),
      DepartmentData(name: "Electronics", students: 98, faculty: 8),
      DepartmentData(name: "Mechanical", students: 112, faculty: 10),
      DepartmentData(name: "Civil", students: 87, faculty: 7),
      DepartmentData(name: "Business", students: 134, faculty: 9),
    ];

    monthlyTrendData = [
      MonthlyTrendData(month: "Jan", activities: 45, approvals: 38),
      MonthlyTrendData(month: "Feb", activities: 52, approvals: 45),
      MonthlyTrendData(month: "Mar", activities: 48, approvals: 41),
      MonthlyTrendData(month: "Apr", activities: 61, approvals: 55),
      MonthlyTrendData(month: "May", activities: 58, approvals: 52),
      MonthlyTrendData(month: "Jun", activities: 67, approvals: 61),
    ];

    recentActivities = [
      RecentActivity(
        id: 1,
        student: "Alice Johnson",
        activity: "Research Paper Publication",
        department: "Computer Science",
        status: ActivityStatus.pending,
        date: "2024-01-15",
      ),
      RecentActivity(
        id: 2,
        student: "Bob Smith",
        activity: "Hackathon Winner",
        department: "Electronics",
        status: ActivityStatus.approved,
        date: "2024-01-14",
      ),
      RecentActivity(
        id: 3,
        student: "Carol Davis",
        activity: "Industry Internship",
        department: "Mechanical",
        status: ActivityStatus.pending,
        date: "2024-01-13",
      ),
    ];

    activityApprovalData = [
      ActivityApprovalData(name: "Completed", value: 65, color: Colors.green.shade600),
      ActivityApprovalData(name: "In Progress", value: 25, color: Colors.orange.shade600),
      ActivityApprovalData(name: "Pending", value: 10, color: Colors.red.shade600),
    ];

    totalDepartments = 5;
    totalFaculty = 46;
    totalStudents = 576;
    pendingApprovals = 23;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (error) {
      _showSnackBar('Error signing out', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading dashboard...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: _buildDrawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.dashboard, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Smart Student Hub',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: _isRefreshing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.refresh, color: Colors.black87),
              onPressed: _isRefreshing ? null : _refreshData,
            ),
            PopupMenuButton<String>(
              icon: CircleAvatar(
                backgroundColor: Colors.blue.shade600,
                radius: 16,
                child: const Text(
                  'JD',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              onSelected: (value) {
                if (value == 'logout') {
                  _showLogoutDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 18),
                      SizedBox(width: 8),
                      Text('Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18),
                      SizedBox(width: 8),
                      Text('Sign Out'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildStatsCards(),
              const SizedBox(height: 20),
              _buildChartsRow(),
              const SizedBox(height: 20),
              _buildBottomRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Smart Student Hub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () => Navigator.pop(context),
                  isSelected: true,
                ),
                _buildDrawerItem(
                  icon: Icons.business,
                  title: 'Departments',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/departments');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Faculty/HOD',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/faculty');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.school,
                  title: 'Students',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/students');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.local_activity,
                  title: 'Activities',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/activities');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.folder,
                  title: 'Portfolios',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/portfolios');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.analytics,
                  title: 'Reports',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/reports');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDrawerItem(
                  icon: Icons.help,
                  title: 'Need Help?',
                  subtitle: 'Check our documentation',
                  onTap: () => _showHelpDialog(),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showLogoutDialog();
                    },
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.blue.shade600 : Colors.grey[700],
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.blue.shade600 : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
          ),
        )
            : null,
        onTap: onTap,
        dense: true,
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.help, color: Colors.blue),
            SizedBox(width: 8),
            Text('Help & Support'),
          ],
        ),
        content: const Text('For technical support and documentation, please contact our support team.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Sign Out'),
          ],
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          'Overview of Smart Student Hub platform',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _buildStatCard(
          title: "Total Departments",
          value: totalDepartments.toString(),
          change: "+1 this month",
          icon: Icons.business,
          color: Colors.blue.shade600,
        ),
        _buildStatCard(
          title: "Total Faculty",
          value: totalFaculty.toString(),
          change: "+3 this month",
          icon: Icons.people,
          color: Colors.green.shade600,
        ),
        _buildStatCard(
          title: "Total Students",
          value: totalStudents.toString(),
          change: "+24 this month",
          icon: Icons.school,
          color: Colors.purple.shade600,
        ),
        _buildStatCard(
          title: "Pending Approvals",
          value: pendingApprovals.toString(),
          change: "-5 from yesterday",
          icon: Icons.access_time,
          color: Colors.orange.shade600,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String change,
    required IconData icon,
    required Color color,
  }) {
    bool isPositiveChange = change.startsWith('+') || change.contains('from yesterday');
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPositiveChange ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    change,
                    style: TextStyle(
                      fontSize: 10,
                      color: isPositiveChange ? Colors.green.shade600 : Colors.orange.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsRow() {
    // Load sample data if empty
    if (monthlyTrendData.isEmpty) {
      monthlyTrendData = [
        MonthlyTrendData(month: "Jan", activities: 45, approvals: 38),
        MonthlyTrendData(month: "Feb", activities: 52, approvals: 45),
        MonthlyTrendData(month: "Mar", activities: 48, approvals: 41),
        MonthlyTrendData(month: "Apr", activities: 61, approvals: 55),
        MonthlyTrendData(month: "May", activities: 58, approvals: 52),
        MonthlyTrendData(month: "Jun", activities: 67, approvals: 61),
      ];
    }

    return Column(
      children: [
        // Activities Overview Chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Activities Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        _buildChartTab('Week', true),
                        _buildChartTab('Month', false),
                        _buildChartTab('Year', false),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Uploaded vs approved activities',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 20,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey[300]!,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 20,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: TextStyle(color: Colors.grey[600], fontSize: 10),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 25,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < monthlyTrendData.length) {
                                return Text(
                                  monthlyTrendData[value.toInt()].month,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: monthlyTrendData.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value.approvals.toDouble());
                          }).toList(),
                          isCurved: true,
                          color: Colors.blue.shade600,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.shade100,
                          ),
                        ),
                        LineChartBarData(
                          spots: monthlyTrendData.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value.activities.toDouble());
                          }).toList(),
                          isCurved: true,
                          color: Colors.green.shade600,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('Approved', Colors.blue.shade600),
                    const SizedBox(width: 20),
                    _buildLegendItem('Uploaded', Colors.green.shade600),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartTab(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade600 : Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBottomRow() {
    // Load sample data if empty
    if (recentActivities.isEmpty) {
      recentActivities = [
        RecentActivity(
          id: 1,
          student: "Alice Johnson",
          activity: "Research Paper Publication",
          department: "Computer Science",
          status: ActivityStatus.pending,
          date: "2024-01-15",
        ),
        RecentActivity(
          id: 2,
          student: "Bob Smith",
          activity: "Hackathon Winner",
          department: "Electronics",
          status: ActivityStatus.approved,
          date: "2024-01-14",
        ),
        RecentActivity(
          id: 3,
          student: "Carol Davis",
          activity: "Industry Internship",
          department: "Mechanical",
          status: ActivityStatus.pending,
          date: "2024-01-13",
        ),
      ];
    }

    if (activityApprovalData.isEmpty) {
      activityApprovalData = [
        ActivityApprovalData(name: "Completed", value: 65, color: Colors.green.shade600),
        ActivityApprovalData(name: "In Progress", value: 25, color: Colors.orange.shade600),
        ActivityApprovalData(name: "Pending", value: 10, color: Colors.red.shade600),
      ];
    }

    return Column(
      children: [
        // Recent Uploads
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Uploads',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Latest activity submissions',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ...recentActivities.map((activity) => _buildActivityItem(activity)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Student Portfolios and Reports Row
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Student Portfolios',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/portfolios'),
                            child: const Text('View All', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Recent submissions and top performers',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPortfolioItem('Alice Johnson', 'Computer Science', '95% complete', 0.95),
                      _buildPortfolioItem('Bob Smith', 'Electronics', '90% complete', 0.90),
                      _buildPortfolioItem('Carol Davis', 'Mechanical', '88% complete', 0.88),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Reports & Analytics',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/reports'),
                            child: const Text('Download Report', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Portfolio completion status',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: PieChart(
                          PieChartData(
                            sections: activityApprovalData.map((data) {
                              final total = activityApprovalData.fold<int>(0, (sum, item) => sum + item.value);
                              final percentage = total > 0 ? (data.value / total * 100).round() : 0;
                              return PieChartSectionData(
                                value: data.value.toDouble(),
                                title: '$percentage%',
                                color: data.color,
                                radius: 40,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: activityApprovalData
                            .map((data) => _buildLegendItem(data.name, data.color))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityItem(RecentActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            child: Text(
              activity.student.isNotEmpty ? activity.student[0] : '',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.student,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  activity.activity,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${activity.department} • ${activity.date}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBadge(activity.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ActivityStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case ActivityStatus.approved:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        text = 'approved';
        break;
      case ActivityStatus.rejected:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        text = 'rejected';
        break;
      case ActivityStatus.pending:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        text = 'pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPortfolioItem(String name, String department, String completion, double progress) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey[300],
            child: Text(
              name.isNotEmpty ? name[0] : '',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  department,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                completion,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                width: 60,
                height: 4,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: progress > 0.9 ? Colors.green.shade600 : Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}

// Placeholder pages for navigation
class DepartmentsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Departments')),
      body: const Center(
        child: Text('Departments page is under development.\nCurrently showing the Admin departments section.'),
      ),
    );
  }
}

class FacultyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Faculty/HOD')),
      body: const Center(
        child: Text('Faculty page is under development.\nCurrently showing the Admin faculty section.'),
      ),
    );
  }
}

class StudentsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: const Center(
        child: Text('Students page is under development.\nCurrently showing the Admin students section.'),
      ),
    );
  }
}

class ActivitiesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activities')),
      body: const Center(
        child: Text('Activities page is under development.\nCurrently showing the Admin activities section.'),
      ),
    );
  }
}

class PortfoliosPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portfolios')),
      body: const Center(
        child: Text('Portfolios page is under development.\nCurrently showing the Admin portfolios section.'),
      ),
    );
  }
}

class ReportsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: const Center(
        child: Text('Reports page is under development.\nCurrently showing the Admin reports section.'),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Text('Settings page is under development.\nCurrently showing the Admin settings section.'),
      ),
    );
  }
}

// Data Models
class DepartmentData {
  final String name;
  final int students;
  final int faculty;

  DepartmentData({
    required this.name,
    required this.students,
    required this.faculty,
  });
}

class MonthlyTrendData {
  final String month;
  final int activities;
  final int approvals;

  MonthlyTrendData({
    required this.month,
    required this.activities,
    required this.approvals,
  });
}

class RecentActivity {
  final int id;
  final String student;
  final String activity;
  final String department;
  final ActivityStatus status;
  final String date;

  RecentActivity({
    required this.id,
    required this.student,
    required this.activity,
    required this.department,
    required this.status,
    required this.date,
  });
}

class ActivityApprovalData {
  final String name;
  final int value;
  final Color color;

  ActivityApprovalData({
    required this.name,
    required this.value,
    required this.color,
  });
}

enum ActivityStatus { approved, pending, rejected }