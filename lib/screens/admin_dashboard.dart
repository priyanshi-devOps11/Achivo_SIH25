// pubspec.yaml dependencies:
/*
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.3.4
  fl_chart: ^0.65.0
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
*/

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
  final supabaseUrl = dotenv.env['NEXT_PUBLIC_SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY'];
  );

  runApp(MyApp());
}.

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _user;

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
        // User will be automatically navigated via AuthWrapper
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
      body: Center(
        child: Card(
          margin: EdgeInsets.all(32),
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Admin Login',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 16),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? CircularProgressIndicator()
                        : Text('Sign In'),
                  ),
                ),
              ],
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadDepartments(),
        _loadMonthlyTrends(),
        _loadRecentActivities(),
        _loadApprovalStats(),
        _loadOverallStats(),
      ]);
    } catch (error) {
      print('Error loading data: $error');
      // Fallback to sample data if backend fails
      _loadSampleData();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDepartments() async {
    try {
      final response = await supabase
          .from('departments')
          .select('name, student_count, faculty_count')
          .order('name');

      departmentData = response
          .map<DepartmentData>((item) => DepartmentData(
        name: item['name'],
        students: item['student_count'] ?? 0,
        faculty: item['faculty_count'] ?? 0,
      ))
          .toList();
    } catch (error) {
      print('Error loading departments: $error');
    }
  }

  Future<void> _loadMonthlyTrends() async {
    try {
      final response = await supabase
          .from('monthly_trends')
          .select('month, activities, approvals')
          .order('created_at');

      monthlyTrendData = response
          .map<MonthlyTrendData>((item) => MonthlyTrendData(
        month: item['month'],
        activities: item['activities'] ?? 0,
        approvals: item['approvals'] ?? 0,
      ))
          .toList();
    } catch (error) {
      print('Error loading monthly trends: $error');
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      final response = await supabase
          .from('activities')
          .select('''
            id,
            students (name),
            activity_name,
            departments (name),
            status,
            created_at
          ''')
          .order('created_at', ascending: false)
          .limit(5);

      recentActivities = response
          .map<RecentActivity>((item) => RecentActivity(
        id: item['id'],
        student: item['students']?['name'] ?? 'Unknown',
        activity: item['activity_name'],
        department: item['departments']?['name'] ?? 'Unknown',
        status: _parseActivityStatus(item['status']),
        date: _formatDate(item['created_at']),
      ))
          .toList();
    } catch (error) {
      print('Error loading recent activities: $error');
    }
  }

  Future<void> _loadApprovalStats() async {
    try {
      final response = await supabase
          .from('activities')
          .select('status')
          .not('status', 'is', null);

      Map<String, int> statusCount = {};
      for (var item in response) {
        String status = item['status'];
        statusCount[status] = (statusCount[status] ?? 0) + 1;
      }

      activityApprovalData = [
        ActivityApprovalData(
          name: "Approved",
          value: statusCount['approved'] ?? 0,
          color: Colors.green,
        ),
        ActivityApprovalData(
          name: "Pending",
          value: statusCount['pending'] ?? 0,
          color: Colors.orange,
        ),
        ActivityApprovalData(
          name: "Rejected",
          value: statusCount['rejected'] ?? 0,
          color: Colors.red,
        ),
      ];
    } catch (error) {
      print('Error loading approval stats: $error');
    }
  }

  Future<void> _loadOverallStats() async {
    try {
      final departmentsCount = await supabase
          .from('departments')
          .select('id', const FetchOptions(count: CountOption.exact));

      final facultyCount = await supabase
          .from('faculty')
          .select('id', const FetchOptions(count: CountOption.exact));

      final studentsCount = await supabase
          .from('students')
          .select('id', const FetchOptions(count: CountOption.exact));

      final pendingCount = await supabase
          .from('activities')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('status', 'pending');

      setState(() {
        totalDepartments = departmentsCount.count ?? 0;
        totalFaculty = facultyCount.count ?? 0;
        totalStudents = studentsCount.count ?? 0;
        pendingApprovals = pendingCount.count ?? 0;
      });
    } catch (error) {
      print('Error loading overall stats: $error');
    }
  }

  void _loadSampleData() {
    // Fallback sample data
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
      RecentActivity(
        id: 4,
        student: "David Wilson",
        activity: "Conference Presentation",
        department: "Civil",
        status: ActivityStatus.rejected,
        date: "2024-01-12",
      ),
      RecentActivity(
        id: 5,
        student: "Eva Brown",
        activity: "Startup Founder",
        department: "Business",
        status: ActivityStatus.approved,
        date: "2024-01-11",
      ),
    ];

    activityApprovalData = [
      ActivityApprovalData(name: "Approved", value: 65, color: Colors.green),
      ActivityApprovalData(name: "Pending", value: 23, color: Colors.orange),
      ActivityApprovalData(name: "Rejected", value: 12, color: Colors.red),
    ];

    totalDepartments = 5;
    totalFaculty = 46;
    totalStudents = 576;
    pendingApprovals = 23;
  }

  Future<void> _approveActivity(int activityId) async {
    try {
      await supabase
          .from('activities')
          .update({'status': 'approved'})
          .eq('id', activityId);
      _loadData(); // Refresh data
    } catch (error) {
      print('Error approving activity: $error');
    }
  }

  Future<void> _rejectActivity(int activityId) async {
    try {
      await supabase
          .from('activities')
          .update({'status': 'rejected'})
          .eq('id', activityId);
      _loadData(); // Refresh data
    } catch (error) {
      print('Error rejecting activity: $error');
    }
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
  }

  ActivityStatus _parseActivityStatus(String? status) {
    switch (status) {
      case 'approved':
        return ActivityStatus.approved;
      case 'rejected':
        return ActivityStatus.rejected;
      default:
        return ActivityStatus.pending;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              SizedBox(height: 24),

              // Stats Cards
              _buildStatsCards(),
              SizedBox(height: 24),

              // Analytics Chart and Recent Uploads Row
              _buildAnalyticsAndRecentUploads(context),
              SizedBox(height: 24),

              // Portfolio Overview and Reports Row
              _buildPortfolioAndReports(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Dashboard',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Overview of Smart Student Hub platform',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth < 600 ? 1 :
        constraints.maxWidth < 900 ? 2 : 4;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            StatCard(
              title: "Total Departments",
              value: totalDepartments.toString(),
              change: "+1 this month",
              changeType: ChangeType.positive,
              icon: Icons.business,
            ),
            StatCard(
              title: "Total Faculty",
              value: totalFaculty.toString(),
              change: "+3 this month",
              changeType: ChangeType.positive,
              icon: Icons.people,
            ),
            StatCard(
              title: "Total Students",
              value: totalStudents.toString(),
              change: "+24 this month",
              changeType: ChangeType.positive,
              icon: Icons.school,
            ),
            StatCard(
              title: "Pending Approvals",
              value: pendingApprovals.toString(),
              change: "-5 from yesterday",
              changeType: ChangeType.positive,
              icon: Icons.access_time,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsAndRecentUploads(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1024) {
          return Column(
            children: [
              _buildAnalyticsChart(),
              SizedBox(height: 24),
              _buildRecentUploads(),
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAnalyticsChart()),
              SizedBox(width: 24),
              Expanded(child: _buildRecentUploads()),
            ],
          );
        }
      },
    );
  }

  Widget _buildAnalyticsChart() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activities Uploaded vs Approved',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Monthly trends of activity submissions and approvals',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),
            Container(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300]!,
                        strokeWidth: 1,
                        dashArray: [3, 3],
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300]!,
                        strokeWidth: 1,
                        dashArray: [3, 3],
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < monthlyTrendData.length) {
                            return Text(
                              monthlyTrendData[value.toInt()].month,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: monthlyTrendData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.activities.toDouble());
                      }).toList(),
                      isCurved: false,
                      color: Colors.blue,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.blue,
                          );
                        },
                      ),
                    ),
                    LineChartBarData(
                      spots: monthlyTrendData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.approvals.toDouble());
                      }).toList(),
                      isCurved: false,
                      color: Colors.green,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.green,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentUploads() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Uploads',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Latest activity submissions with approve/reject actions',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),
            Column(
              children: recentActivities.map((activity) {
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.student,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              activity.activity,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 2),
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
                      SizedBox(width: 12),
                      Row(
                        children: [
                          _buildStatusBadge(activity.status),
                          if (activity.status == ActivityStatus.pending) ...[
                            SizedBox(width: 8),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check_circle_outline, color: Colors.green),
                                  iconSize: 20,
                                  padding: EdgeInsets.all(4),
                                  constraints: BoxConstraints(),
                                  onPressed: () => _approveActivity(activity.id),
                                ),
                                SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(Icons.cancel_outlined, color: Colors.red),
                                  iconSize: 20,
                                  padding: EdgeInsets.all(4),
                                  constraints: BoxConstraints(),
                                  onPressed: () => _rejectActivity(activity.id),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ActivityStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case ActivityStatus.approved:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        text = 'approved';
        break;
      case ActivityStatus.rejected:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        text = 'rejected';
        break;
      case ActivityStatus.pending:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        text = 'pending';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPortfolioAndReports() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1024) {
          return Column(
            children: [
              _buildPortfolioOverview(),
              SizedBox(height: 24),
              _buildReportsAnalytics(),
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPortfolioOverview()),
              SizedBox(width: 24),
              Expanded(child: _buildReportsAnalytics()),
            ],
          );
        }
      },
    );
  }

  Widget _buildPortfolioOverview() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portfolio Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Department-wise student and faculty distribution',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),
            Container(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: departmentData.isNotEmpty
                      ? departmentData.map((d) => d.students).reduce((a, b) => a > b ? a : b).toDouble() + 20
                      : 160,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() < departmentData.length) {
                            String name = departmentData[value.toInt()].name;
                            String shortName = name.length > 8 ? name.substring(0, 8) : name;
                            return Text(
                              shortName,
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: departmentData.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.students.toDouble(),
                          color: Colors.blue,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsAnalytics() {
    final totalActivities = activityApprovalData.fold(0, (sum, item) => sum + item.value);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports & Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Activity approval statistics and insights',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),
            Container(
              height: 300,
              child: totalActivities > 0 ? PieChart(
                PieChartData(
                  sections: activityApprovalData.map((data) {
                    final percentage = (data.value / totalActivities * 100).round();
                    return PieChartSectionData(
                      value: data.value.toDouble(),
                      title: '$percentage%',
                      color: data.color,
                      radius: 100,
                      titleStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ) : Center(child: Text('No data available')),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: activityApprovalData.map((data) =>
                  _buildLegendItem(data.name, data.color)
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final ChangeType changeType;
  final IconData icon;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.change,
    required this.changeType,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  icon,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            SizedBox(height: 4),
            Text(
              change,
              style: TextStyle(
                fontSize: 12,
                color: changeType == ChangeType.positive ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
enum ChangeType { positive, negative }

// Supabase Database Schema SQL (Run these in your Supabase SQL Editor)
/*
-- Create departments table
CREATE TABLE departments (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  student_count INTEGER DEFAULT 0,
  faculty_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create students table
CREATE TABLE students (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  department_id INTEGER REFERENCES departments(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create faculty table
CREATE TABLE faculty (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  department_id INTEGER REFERENCES departments(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create activities table
CREATE TABLE activities (
  id SERIAL PRIMARY KEY,
  student_id INTEGER REFERENCES students(id),
  activity_name VARCHAR(200) NOT NULL,
  description TEXT,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create monthly_trends table
CREATE TABLE monthly_trends (
  id SERIAL PRIMARY KEY,
  month VARCHAR(10) NOT NULL,
  activities INTEGER DEFAULT 0,
  approvals INTEGER DEFAULT 0,
  year INTEGER DEFAULT EXTRACT(YEAR FROM NOW()),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert sample data

-- Sample departments
INSERT INTO departments (name, student_count, faculty_count) VALUES
('Computer Science', 145, 12),
('Electronics', 98, 8),
('Mechanical', 112, 10),
('Civil', 87, 7),
('Business', 134, 9);

-- Sample students
INSERT INTO students (name, email, department_id) VALUES
('Alice Johnson', 'alice@example.com', 1),
('Bob Smith', 'bob@example.com', 2),
('Carol Davis', 'carol@example.com', 3),
('David Wilson', 'david@example.com', 4),
('Eva Brown', 'eva@example.com', 5);

-- Sample faculty
INSERT INTO faculty (name, email, department_id) VALUES
('Dr. John Doe', 'john@example.com', 1),
('Dr. Jane Smith', 'jane@example.com', 2),
('Dr. Mike Johnson', 'mike@example.com', 3);

-- Sample activities
INSERT INTO activities (student_id, activity_name, description, status) VALUES
(1, 'Research Paper Publication', 'Published research on AI', 'pending'),
(2, 'Hackathon Winner', 'Won first place in tech hackathon', 'approved'),
(3, 'Industry Internship', 'Completed internship at major company', 'pending'),
(4, 'Conference Presentation', 'Presented paper at international conference', 'rejected'),
(5, 'Startup Founder', 'Founded tech startup', 'approved');

-- Sample monthly trends
INSERT INTO monthly_trends (month, activities, approvals, year) VALUES
('Jan', 45, 38, 2024),
('Feb', 52, 45, 2024),
('Mar', 48, 41, 2024),
('Apr', 61, 55, 2024),
('May', 58, 52, 2024),
('Jun', 67, 61, 2024);

-- Enable Row Level Security (RLS)
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE faculty ENABLE ROW LEVEL SECURITY;
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_trends ENABLE ROW LEVEL SECURITY;

-- Create policies for authenticated users (admins)
CREATE POLICY "Enable all operations for authenticated users" ON departments FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all operations for authenticated users" ON students FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all operations for authenticated users" ON faculty FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all operations for authenticated users" ON activities FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Enable all operations for authenticated users" ON monthly_trends FOR ALL USING (auth.role() = 'authenticated');

-- Create functions to update counts automatically
CREATE OR REPLACE FUNCTION update_department_counts()
RETURNS TRIGGER AS $
BEGIN
  -- Update student count
  UPDATE departments
  SET student_count = (
    SELECT COUNT(*) FROM students WHERE department_id = departments.id
  );

  -- Update faculty count
  UPDATE departments
  SET faculty_count = (
    SELECT COUNT(*) FROM faculty WHERE department_id = departments.id
  );

  RETURN NULL;
END;
$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER update_student_count
  AFTER INSERT OR UPDATE OR DELETE ON students
  FOR EACH STATEMENT EXECUTE FUNCTION update_department_counts();

CREATE TRIGGER update_faculty_count
  AFTER INSERT OR UPDATE OR DELETE ON faculty
  FOR EACH STATEMENT EXECUTE FUNCTION update_department_counts();
*/