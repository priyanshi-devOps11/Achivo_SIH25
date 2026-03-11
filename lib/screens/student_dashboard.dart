// lib/screens/student_dashboard.dart
// ✅ NEW: Attendance & Marks tabs added (real data from faculty entries)

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_models.dart';
import '../services/student_service.dart';
import 'leave_application_page.dart';
import 'documents_page.dart';
import 'student_attendance_page.dart';
import 'student_marks_page.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  StudentProfile? _studentProfile;
  DashboardStats? _dashboardStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);
    try {
      await StudentService.ensureStorageBuckets();
      final profile = await StudentService.getCurrentStudentProfile();
      if (profile != null) {
        final stats = await StudentService.getDashboardStats(profile.id);
        if (mounted) {
          setState(() {
            _studentProfile = profile;
            _dashboardStats = stats;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          _showError('Could not load student profile. Please contact support.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load dashboard data');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _handleSignOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/welcome', (r) => false);
      }
    } catch (e) {
      _showError('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_studentProfile == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load profile',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: _loadStudentData,
                  child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: _buildDrawer(),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.purple, Colors.blue],
            ).createShader(bounds),
            child: const Text(
              'Achivo Dashboard',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          Text(
            _getPageTitle(),
            style:
            const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _studentProfile!.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87),
                  ),
                  Text(
                    'Year ${_studentProfile!.displayYear}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundColor: Colors.purple,
                child: Text(
                  _studentProfile!.firstName
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Drawer ─────────────────────────────────────────────────

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple, Colors.blue, Colors.cyan],
          ),
        ),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.school, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Achivo Portal',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text('Academic Dashboard',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_studentProfile!.fullName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  Text(_studentProfile!.rollNumber,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            _drawerItem(Icons.dashboard, 'Overview', 0),
            _drawerItem(Icons.how_to_reg, 'Attendance', 1),
            _drawerItem(Icons.grade, 'Marks', 2),
            _drawerItem(Icons.calendar_today, 'Leave Applications', 3),
            _drawerItem(Icons.folder, 'Documents', 4),
            _drawerItem(Icons.emoji_events, 'Credit Activities', 5),
            const Spacer(),
            _drawerItem(Icons.logout, 'Sign Out', -1,
                onTap: _handleSignOut),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, int index,
      {VoidCallback? onTap}) {
    final bool isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white24 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500)),
        onTap: onTap ??
                () {
              setState(() => _selectedIndex = index);
              Navigator.pop(context);
            },
      ),
    );
  }



  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return OverviewPage(
          student: _studentProfile!,
          stats: _dashboardStats!,
          onRefresh: _loadStudentData,
        );
      case 1:
        return StudentAttendancePage(studentId: _studentProfile!.id);
      case 2:
        return StudentMarksPage(studentId: _studentProfile!.id);
      case 3:
        return LeaveApplicationPage(studentId: _studentProfile!.id);
      case 4:
        return DocumentsPage(studentId: _studentProfile!.id);
      case 5:
        return CreditActivitiesPage(studentId: _studentProfile!.id);
      default:
        return OverviewPage(
          student: _studentProfile!,
          stats: _dashboardStats!,
          onRefresh: _loadStudentData,
        );
    }
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0: return 'Welcome to your student portal';
      case 1: return 'My Attendance';
      case 2: return 'My Marks';
      case 3: return 'Leave Applications';
      case 4: return 'Documents Management';
      case 5: return 'Credit Activities';
      default: return 'Student Dashboard';
    }
  }
}



class OverviewPage extends StatelessWidget {
  final StudentProfile student;
  final DashboardStats stats;
  final VoidCallback onRefresh;

  const OverviewPage({
    Key? key,
    required this.student,
    required this.stats,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.blue, Colors.cyan],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${student.firstName}! 🎓',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Here's an overview of your academic journey",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                  title: 'Current GPA',
                  value:
                  stats.cgpa?.toStringAsFixed(2) ?? '0.0',
                  subtitle: 'Keep it up!',
                  color: Colors.purple,
                  icon: Icons.book),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _statCard(
                  title: 'Attendance',
                  value:
                  '${stats.attendancePercentage.toInt()}%',
                  subtitle: stats.attendancePercentage >= 75
                      ? 'Above average'
                      : 'Needs improvement',
                  color: Colors.indigo,
                  icon: Icons.how_to_reg),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _statCard(
                  title: 'Credits',
                  value:
                  '${stats.creditsCompleted}/${stats.totalCredits}',
                  subtitle:
                  '${stats.totalCredits == 0 ? 0 : ((stats.creditsCompleted / stats.totalCredits) * 100).toInt()}% completed',
                  color: Colors.teal,
                  icon: Icons.emoji_events),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _statCard(
                  title: 'Pending Leaves',
                  value: '${stats.pendingLeaves}',
                  subtitle: 'Awaiting approval',
                  color: Colors.orange,
                  icon: Icons.pending_actions),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          const Text('Quick Actions ⚡',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _actionCard('Attendance',
                    Icons.how_to_reg, Colors.indigo, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentAttendancePage(
                              studentId: student.id),
                        ),
                      );
                    }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionCard(
                    'Marks', Icons.grade, Colors.teal, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          StudentMarksPage(studentId: student.id),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionCard('Apply Leave',
                    Icons.event_busy, Colors.purple, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LeaveApplicationPage(
                              studentId: student.id),
                        ),
                      );
                    }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionCard('Upload Documents',
                    Icons.upload_file, Colors.blue, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DocumentsPage(studentId: student.id),
                        ),
                      );
                    }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionCard(String title, IconData icon, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}


class CreditActivitiesPage extends StatelessWidget {
  final String studentId;

  const CreditActivitiesPage({Key? key, required this.studentId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Credit Activities — Coming Soon'));
  }
}