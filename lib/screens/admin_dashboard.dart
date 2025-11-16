import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

final supabase = Supabase.instance.client;

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Data variables from Supabase
  List<DepartmentData> departmentData = [];
  List<MonthlyTrendData> monthlyTrendData = [];
  List<RecentActivity> recentActivities = [];
  List<SystemOverviewData> systemOverviewData = [];

  // Stats from Supabase
  int totalDepartments = 0;
  int totalFaculty = 0;
  int totalStudents = 0;
  int pendingApprovals = 0;
  int totalActivities = 0;
  int activeUsers = 0;

  bool _isLoading = true;
  bool _isRefreshing = false;
  String _selectedPeriod = 'Week';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadDashboardStats(),
        _loadDepartmentStats(),
        _loadActivitiesOverview(),
        _loadSystemOverview(),
      ]);
    } catch (error) {
      print('Error loading data: $error');
      _showSnackBar('Error loading data: ${error.toString()}', Colors.red);
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

  Future<void> _loadDashboardStats() async {
    try {
      // Total Departments
      final departmentsResponse = await supabase
          .from('departments')
          .select('id')
          .count(CountOption.exact);
      totalDepartments = departmentsResponse.count;

      // Total Faculty
      final facultyResponse = await supabase
          .from('faculty')
          .select('id')
          .count(CountOption.exact);
      totalFaculty = facultyResponse.count;

      // Total Students
      final studentsResponse = await supabase
          .from('students')
          .select('id')
          .count(CountOption.exact);
      totalStudents = studentsResponse.count;

      // Pending Approvals
      final approvalsResponse = await supabase
          .from('activities')
          .select('id')
          .eq('status', 'pending')
          .count(CountOption.exact);
      pendingApprovals = approvalsResponse.count;

      // Total Activities
      final activitiesResponse = await supabase
          .from('activities')
          .select('id')
          .count(CountOption.exact);
      totalActivities = activitiesResponse.count;

      // Active Users (profiles updated in last 7 days)
      final activeUsersResponse = await supabase
          .from('profiles')
          .select('id')
          .gte('updated_at', DateTime.now().subtract(Duration(days: 7)).toIso8601String())
          .count(CountOption.exact);
      activeUsers = activeUsersResponse.count;

      setState(() {});
    } catch (error) {
      print('Error loading dashboard stats: $error');
    }
  }

  Future<void> _loadDepartmentStats() async {
    try {
      final response = await supabase
          .from('departments')
          .select('name, id');

      if (response != null && response is List) {
        List<DepartmentData> tempData = [];

        for (var dept in response) {
          // Count students for this department
          final studentsCount = await supabase
              .from('students')
              .select('id')
              .eq('department_id', dept['id'])
              .count(CountOption.exact);

          // Count faculty for this department
          final facultyCount = await supabase
              .from('faculty')
              .select('id')
              .eq('department_id', dept['id'])
              .count(CountOption.exact);

          tempData.add(DepartmentData(
            name: dept['name'] ?? 'Unknown',
            students: studentsCount.count,
            faculty: facultyCount.count,
          ));
        }

        setState(() {
          departmentData = tempData;
        });
      }
    } catch (error) {
      print('Error loading department stats: $error');
    }
  }

  Future<void> _loadActivitiesOverview() async {
    try {
      final now = DateTime.now();
      List<MonthlyTrendData> trends = [];

      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final nextMonth = DateTime(now.year, now.month - i + 1, 1);

        final activitiesResponse = await supabase
            .from('activities')
            .select('id, status')
            .gte('created_at', month.toIso8601String())
            .lt('created_at', nextMonth.toIso8601String());

        int totalActivities = 0;
        int approvedActivities = 0;

        if (activitiesResponse is List) {
          totalActivities = activitiesResponse.length;
          approvedActivities = activitiesResponse
              .where((activity) => activity['status'] == 'approved')
              .length;
        }

        trends.add(MonthlyTrendData(
          month: _getMonthName(month.month),
          activities: totalActivities,
          approvals: approvedActivities,
        ));
      }

      setState(() {
        monthlyTrendData = trends;
      });
    } catch (error) {
      print('Error loading activities overview: $error');
    }
  }

  Future<void> _loadSystemOverview() async {
    try {
      // Recent Activities
      final recentActivitiesResponse = await supabase
          .from('activities')
          .select('id, title, status, date, student_id')
          .order('created_at', ascending: false)
          .limit(5);

      if (recentActivitiesResponse is List) {
        List<RecentActivity> tempActivities = [];

        for (var item in recentActivitiesResponse) {
          String studentName = 'Unknown Student';
          String department = 'Unknown';

          if (item['student_id'] != null) {
            try {
              final studentData = await supabase
                  .from('students')
                  .select('first_name, last_name, department_id')
                  .eq('id', item['student_id'])
                  .maybeSingle();

              if (studentData != null) {
                studentName = '${studentData['first_name'] ?? ''} ${studentData['last_name'] ?? ''}'.trim();

                if (studentData['department_id'] != null) {
                  final deptData = await supabase
                      .from('departments')
                      .select('name')
                      .eq('id', studentData['department_id'])
                      .maybeSingle();
                  if (deptData != null) {
                    department = deptData['name'] ?? 'Unknown';
                  }
                }
              }
            } catch (e) {
              print('Error loading student data: $e');
            }
          }

          tempActivities.add(RecentActivity(
            id: item['id'] ?? 0,
            student: studentName,
            activity: item['title'] ?? 'Unknown Activity',
            department: department,
            status: _parseActivityStatus(item['status']),
            date: item['date'] ?? DateTime.now().toIso8601String().substring(0, 10),
          ));
        }

        setState(() {
          recentActivities = tempActivities;
        });
      }

      // Activity Status Counts
      final approvedCount = await supabase
          .from('activities')
          .select('id')
          .eq('status', 'approved')
          .count(CountOption.exact);

      final pendingCount = await supabase
          .from('activities')
          .select('id')
          .eq('status', 'pending')
          .count(CountOption.exact);

      final rejectedCount = await supabase
          .from('activities')
          .select('id')
          .eq('status', 'rejected')
          .count(CountOption.exact);

      setState(() {
        systemOverviewData = [
          SystemOverviewData(name: "Approved", value: approvedCount.count, color: Colors.green.shade600),
          SystemOverviewData(name: "Pending", value: pendingCount.count, color: Colors.orange.shade600),
          SystemOverviewData(name: "Rejected", value: rejectedCount.count, color: Colors.red.shade600),
        ];
      });
    } catch (error) {
      print('Error loading system overview: $error');
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
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
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/welcome',
            (route) => false,
      );
    } catch (error) {
      _showSnackBar('Error signing out', Colors.red);
    }
  }

  void _navigateToPage(String route) {
    Navigator.pop(context);
    _showSnackBar('Navigation to $route - Coming soon', Colors.blue);
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
                'Loading admin dashboard...',
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
                'Achivo',
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
                  'AD',
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
                      Icon(Icons.logout, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sign Out', style: TextStyle(color: Colors.red)),
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
              _buildSystemManagement(),
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
            width: double.infinity,
            color: Colors.blue.shade600,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                      'Achivo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Admin Control Panel',
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
                  onTap: () => _navigateToPage('/admin/departments'),
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Faculty Management',
                  onTap: () => _navigateToPage('/admin/faculty'),
                ),
                _buildDrawerItem(
                  icon: Icons.school,
                  title: 'Student Management',
                  onTap: () => _navigateToPage('/admin/students'),
                ),
                _buildDrawerItem(
                  icon: Icons.verified,
                  title: 'Activity Approvals',
                  onTap: () => _navigateToPage('/admin/activities'),
                ),
                _buildDrawerItem(
                  icon: Icons.manage_accounts,
                  title: 'User Management',
                  onTap: () => _navigateToPage('/admin/user-management'),
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'System Settings',
                  onTap: () => _navigateToPage('/admin/system-settings'),
                ),
                _buildDrawerItem(
                  icon: Icons.history,
                  title: 'Audit Logs',
                  onTap: () => _navigateToPage('/admin/audit-logs'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDrawerItem(
                  icon: Icons.help,
                  title: 'System Status',
                  subtitle: 'All systems operational',
                  onTap: () => _showSystemStatusDialog(),
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

  void _showSystemStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('System Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusItem('Database', 'Online', Colors.green),
            _buildStatusItem('Authentication', 'Online', Colors.green),
            _buildStatusItem('File Storage', 'Online', Colors.green),
            _buildStatusItem('Email Service', 'Online', Colors.green),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String service, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(service),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(status, style: TextStyle(color: color)),
            ],
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
        content: const Text('Are you sure you want to sign out from the admin panel?'),
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
          'Institutional management and system overview',
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
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          title: "Total Departments",
          value: totalDepartments.toString(),
          change: "Active",
          icon: Icons.business,
          color: Colors.blue.shade600,
        ),
        _buildStatCard(
          title: "Total Faculty",
          value: totalFaculty.toString(),
          change: "Active",
          icon: Icons.people,
          color: Colors.green.shade600,
        ),
        _buildStatCard(
          title: "Total Students",
          value: totalStudents.toString(),
          change: "Enrolled",
          icon: Icons.school,
          color: Colors.purple.shade600,
        ),
        _buildStatCard(
          title: "Pending Approvals",
          value: pendingApprovals.toString(),
          change: "Awaiting review",
          icon: Icons.access_time,
          color: Colors.orange.shade600,
        ),
        _buildStatCard(
          title: "Total Activities",
          value: totalActivities.toString(),
          change: "Submitted",
          icon: Icons.verified,
          color: Colors.teal.shade600,
        ),
        _buildStatCard(
          title: "Active Users",
          value: activeUsers.toString(),
          change: "Last 7 days",
          icon: Icons.people_alt,
          color: Colors.indigo.shade600,
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      change,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsRow() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activity Trends',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    _buildChartTab('Week', _selectedPeriod == 'Week'),
                    _buildChartTab('Month', _selectedPeriod == 'Month'),
                    _buildChartTab('Year', _selectedPeriod == 'Year'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Submitted vs approved activities over time',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: monthlyTrendData.isNotEmpty ? LineChart(
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
                    ),
                  ],
                ),
              ) : Center(child: Text('No data available', style: TextStyle(color: Colors.grey[600]))),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Approved', Colors.blue.shade600),
                const SizedBox(width: 20),
                _buildLegendItem('Submitted', Colors.green.shade600),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTab(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = label;
        });
      },
      child: Container(
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
      ),
    );
  }

  Widget _buildSystemManagement() {
    return Column(
      children: [
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
                      'Recent Activity Submissions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _navigateToPage('/admin/activities'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Latest submissions requiring admin review',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                if (recentActivities.isNotEmpty)
                  ...recentActivities.take(3).map((activity) => _buildActivityItem(activity))
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'No recent activities',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                          const Expanded(
                            child: Text(
                              'User Management',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _navigateToPage('/admin/user-management'),
                            child: const Text('Manage'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage user roles and permissions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildManagementItem(Icons.admin_panel_settings, 'System Admins', '3 active'),
                      _buildManagementItem(Icons.supervisor_account, 'HODs', '5 active'),
                      _buildManagementItem(Icons.people, 'Faculty', '$totalFaculty active'),
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
                          const Expanded(
                            child: Text(
                              'System Analytics',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _navigateToPage('/admin/audit-logs'),
                            child: const Text('View Logs'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Activity approval status overview',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: systemOverviewData.isNotEmpty ? PieChart(
                          PieChartData(
                            sections: systemOverviewData.map((data) {
                              final total = systemOverviewData.fold<int>(0, (sum, item) => sum + item.value);
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
                        ) : Center(child: Text('No data', style: TextStyle(color: Colors.grey[600]))),
                      ),
                      const SizedBox(height: 12),
                      if (systemOverviewData.isNotEmpty)
                        Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          children: systemOverviewData
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
            backgroundColor: Colors.blue.shade100,
            child: Text(
              activity.student.isNotEmpty ? activity.student[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
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
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  activity.activity,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${activity.department} • ${activity.date}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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

  Widget _buildManagementItem(IconData icon, String title, String count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            count,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Row(
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

class SystemOverviewData {
  final String name;
  final int value;
  final Color color;

  SystemOverviewData({
    required this.name,
    required this.value,
    required this.color,
  });
}

enum ActivityStatus { approved, pending, rejected }