// lib/screens/hod_dashboard.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../models/hod_models.dart';
import 'hod_document_review_page.dart';
import '../services/hod_service.dart';

SupabaseClient get supabase => Supabase.instance.client;

// ─────────────────────────────────────────────
// LOCAL MODELS
// ─────────────────────────────────────────────

class Student {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String rollNumber;
  final String year;
  final String branch;
  final double cgpa;
  final BigInt departmentId;
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
    required this.branch,
    required this.cgpa,
    required this.departmentId,
    required this.parentContact,
    required this.status,
    required this.admissionDate,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    final firstName = map['first_name'] ?? '';
    final lastName = map['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final deptId = map['department_id'];
    final departmentBigInt =
    deptId is int ? BigInt.from(deptId) : (deptId is BigInt ? deptId : BigInt.zero);
    return Student(
      id: map['id']?.toString() ?? '',
      name: fullName.isNotEmpty ? fullName : 'Unknown',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      rollNumber: map['roll_number'] ?? '',
      year: map['year'] ?? 'N/A',
      branch: map['branch'] ?? 'N/A',
      cgpa: (map['cgpa'] ?? 0.0).toDouble(),
      departmentId: departmentBigInt,
      parentContact: map['parent_phone'] ?? '',
      status: map['is_active'] == false ? 'Inactive' : 'Active',
      admissionDate: map['admission_date'] ?? '',
    );
  }
}

class Faculty {
  final String id;
  final String name;
  final String email;
  final String phone;
  final BigInt departmentId;
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
    required this.departmentId,
    required this.designation,
    required this.experience,
    required this.subjects,
    required this.joiningDate,
    required this.status,
    required this.qualification,
  });

  factory Faculty.fromMap(Map<String, dynamic> map) {
    final subjectsData = map['subjects'];
    List<String> subjectsList = [];
    if (subjectsData is List) {
      subjectsList = List<String>.from(subjectsData.map((e) => e.toString()));
    }
    final firstName = map['first_name'] ?? '';
    final lastName = map['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final deptId = map['department_id'];
    final departmentBigInt =
    deptId is int ? BigInt.from(deptId) : (deptId is BigInt ? deptId : BigInt.zero);
    return Faculty(
      id: map['id']?.toString() ?? '',
      name: fullName.isNotEmpty ? fullName : 'Unknown',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      departmentId: departmentBigInt,
      designation: map['designation'] ?? '',
      experience: map['experience_years'] ?? 0,
      subjects: subjectsList,
      joiningDate: map['joining_date'] ?? '',
      status: map['is_active'] == false ? 'Inactive' : 'Active',
      qualification: map['qualification'] ?? '',
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
  final int points;

  ApprovalRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.type,
    required this.title,
    required this.description,
    required this.submittedDate,
    required this.status,
    required this.points,
  });

  factory ApprovalRequest.fromMap(Map<String, dynamic> map, String studentName) {
    return ApprovalRequest(
      id: map['id']?.toString() ?? '',
      studentId: map['student_id']?.toString() ?? '',
      studentName: studentName,
      type: map['category'] ?? 'General',
      title: map['title'] ?? 'N/A',
      description: map['description'] ?? '',
      submittedDate: map['created_at'] != null
          ? DateTime.parse(map['created_at']).toIso8601String().substring(0, 10)
          : 'N/A',
      status: map['status'] ?? 'pending',
      points: map['points'] ?? 0,
    );
  }
}

// ─────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────

class HODDashboardMain extends StatefulWidget {
  const HODDashboardMain({super.key});

  @override
  State<HODDashboardMain> createState() => _HODDashboardMainState();
}

class _HODDashboardMainState extends State<HODDashboardMain>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Auth & Department
  BigInt? _hodDepartmentId;

  // ── NEW: real HOD info ──
  String _hodFullName = 'HOD';
  String _hodEmail = '';
  String _hodDesignation = 'Head of Department';
  String _departmentName = '';
  String _departmentCode = '';
  String _instituteName = '';

  bool isAuthReady = false;
  bool isLoading = true;
  bool isRefreshing = false;

  // Stats
  HODStats? _stats;

  // Data
  List<Student> students = [];
  List<Faculty> faculty = [];
  List<DocumentForReview> documents = [];
  List<LeaveForReview> leaves = [];
  List<ApprovalRequest> activities = [];

  // Real-time subscriptions
  StreamSubscription? _documentsSubscription;
  StreamSubscription? _leavesSubscription;

  // ── Search controllers ──
  final _studentSearchController = TextEditingController();
  final _facultySearchController = TextEditingController();
  String _studentSearch = '';
  String _facultySearch = '';

  @override
  void initState() {
    super.initState();
    // 6 tabs: Overview | Documents | Leaves | Activities | Students | Faculty
    _tabController = TabController(length: 6, vsync: this);
    _checkAuthAndSetupData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _documentsSubscription?.cancel();
    _leavesSubscription?.cancel();
    _studentSearchController.dispose();
    _facultySearchController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // AUTH & INIT
  // ─────────────────────────────────────────────

  Future<void> _checkAuthAndSetupData() async {
    setState(() => isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        if (mounted) Navigator.pushReplacementNamed(context, '/welcome');
        return;
      }

      final hodRecordExists = await HODService.ensureHODRecordExists();
      if (!hodRecordExists) {
        _showSnackbar('Error: Could not verify HOD account.', Colors.red);
        setState(() => isLoading = false);
        return;
      }

      _hodDepartmentId = await HODService.getHODDepartmentId();
      if (_hodDepartmentId == null) {
        _showSnackbar('No department assigned. Contact admin.', Colors.orange);
        setState(() => isLoading = false);
        return;
      }

      // ── Fetch HOD name from hods table (most accurate) ──
      await _fetchHODProfile(user.id);

      // ── Fetch department name ──
      await _fetchDepartmentInfo();

      setState(() => isAuthReady = true);
      await _loadAllData();
      await _setupRealTimeSubscriptions();
      setState(() => isLoading = false);
    } catch (e) {
      _showSnackbar('Failed to load dashboard: $e', Colors.red);
      setState(() => isLoading = false);
    }
  }

  /// Fetch HOD's real name from `hods` table first, fallback to `profiles`.
  Future<void> _fetchHODProfile(String userId) async {
    try {
      // Try hods table first — has first_name / last_name / designation
      final hodRow = await supabase
          .from('hods')
          .select('first_name, last_name, email, designation')
          .eq('user_id', userId)
          .maybeSingle();

      if (hodRow != null) {
        final fn = hodRow['first_name'] ?? '';
        final ln = hodRow['last_name'] ?? '';
        _hodFullName = '$fn $ln'.trim().isNotEmpty ? '$fn $ln'.trim() : 'HOD';
        _hodEmail = hodRow['email'] ?? '';
        _hodDesignation = hodRow['designation'] ?? 'Head of Department';
        return;
      }

      // Fallback to profiles table
      final profileRow = await supabase
          .from('profiles')
          .select('first_name, last_name, email')
          .eq('id', userId)
          .maybeSingle();

      if (profileRow != null) {
        final fn = profileRow['first_name'] ?? '';
        final ln = profileRow['last_name'] ?? '';
        _hodFullName = '$fn $ln'.trim().isNotEmpty ? '$fn $ln'.trim() : 'HOD';
        _hodEmail = profileRow['email'] ?? '';
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching HOD profile: $e');
    }
  }

  /// Fetch department name and institute name from `departments` table.
  Future<void> _fetchDepartmentInfo() async {
    if (_hodDepartmentId == null) return;
    try {
      final deptRow = await supabase
          .from('departments')
          .select('name, code, institutes(name)')
          .eq('id', _hodDepartmentId!.toInt())
          .maybeSingle();

      if (deptRow != null) {
        _departmentName = deptRow['name'] ?? '';
        _departmentCode = deptRow['code'] ?? '';
        final inst = deptRow['institutes'];
        if (inst is Map) {
          _instituteName = inst['name'] ?? '';
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching department: $e');
    }
  }

  // ─────────────────────────────────────────────
  // DATA LOADING
  // ─────────────────────────────────────────────

  Future<void> _loadAllData() async {
    if (_hodDepartmentId == null) return;
    try {
      _stats = await HODService.getHODStats(_hodDepartmentId!);
      await _loadStudents();
      await _loadFaculty();
      documents = await HODService.getDocumentsForReview(departmentId: _hodDepartmentId);
      leaves = await HODService.getLeavesForReview(departmentId: _hodDepartmentId);
      await _loadActivities();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _loadStudents() async {
    try {
      final response = await supabase
          .from('students')
          .select()
          .eq('department_id', _hodDepartmentId!.toInt())
          .order('roll_number', ascending: true);
      students = (response as List).map((s) => Student.fromMap(s)).toList();
    } catch (e) {
      debugPrint('Error loading students: $e');
    }
  }

  Future<void> _loadFaculty() async {
    try {
      final response = await supabase
          .from('faculty')
          .select()
          .eq('department_id', _hodDepartmentId!.toInt())
          .order('first_name', ascending: true);
      faculty = (response as List).map((f) => Faculty.fromMap(f)).toList();
    } catch (e) {
      debugPrint('Error loading faculty: $e');
    }
  }

  Future<void> _loadActivities() async {
    try {
      final response = await supabase
          .from('activities')
          .select('''
            *,
            students!inner(id, first_name, last_name, department_id)
          ''')
          .eq('students.department_id', _hodDepartmentId!.toInt())
          .order('created_at', ascending: false);

      final studentNamesMap = {for (var s in students) s.id: s.name};
      activities = (response as List).map((a) {
        final sid = a['student_id']?.toString() ?? '';
        return ApprovalRequest.fromMap(a, studentNamesMap[sid] ?? 'Unknown');
      }).toList();
    } catch (e) {
      debugPrint('Error loading activities: $e');
    }
  }

  Future<void> _setupRealTimeSubscriptions() async {
    _documentsSubscription = supabase
        .from('student_documents')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((_) async {
      documents = await HODService.getDocumentsForReview(departmentId: _hodDepartmentId);
      if (mounted) setState(() {});
    });

    _leavesSubscription = supabase
        .from('leave_applications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((_) async {
      leaves = await HODService.getLeavesForReview(departmentId: _hodDepartmentId);
      if (mounted) setState(() {});
    });
  }

  Future<void> _refreshData() async {
    if (isRefreshing) return;
    setState(() => isRefreshing = true);
    await _loadAllData();
    setState(() => isRefreshing = false);
    _showSnackbar('Data refreshed', Colors.green);
  }

  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(color == Colors.green ? Icons.check_circle : Icons.error,
                color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (isLoading && !isAuthReady) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Loading HOD Dashboard...', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      // ── Side Drawer ──
      drawer: _buildProfileDrawer(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('HOD Dashboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              // ── Shows real HOD name + department name ──
              'Dr. $_hodFullName  •  ${_departmentName.isNotEmpty ? _departmentName : 'Dept #${_hodDepartmentId ?? "N/A"}'}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: isRefreshing
                ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                : const Icon(Icons.refresh),
            onPressed: isRefreshing ? null : _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleSignOut(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            const Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(
              icon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.description),
                if (_stats != null && _stats!.pendingDocuments > 0)
                  _buildBadge(_stats!.pendingDocuments),
              ]),
              text: 'Documents',
            ),
            Tab(
              icon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.event_busy),
                if (_stats != null && _stats!.pendingLeaves > 0)
                  _buildBadge(_stats!.pendingLeaves),
              ]),
              text: 'Leaves',
            ),
            Tab(
              icon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.star),
                if (_stats != null && _stats!.pendingActivities > 0)
                  _buildBadge(_stats!.pendingActivities),
              ]),
              text: 'Activities',
            ),
            const Tab(icon: Icon(Icons.school), text: 'Students'),
            const Tab(icon: Icon(Icons.people), text: 'Faculty'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildDocumentsTab(),
          _buildLeavesTab(),
          _buildActivitiesTab(),
          _buildStudentsTab(),
          _buildFacultyTab(),
        ],
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Positioned(
      right: -8,
      top: -8,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        child: Text('$count',
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PROFILE DRAWER
  // ─────────────────────────────────────────────

  Widget _buildProfileDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: Text(
                    _hodFullName.isNotEmpty ? _hodFullName[0].toUpperCase() : 'H',
                    style: const TextStyle(
                        fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Dr. $_hodFullName',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(_hodDesignation,
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                if (_hodEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(_hodEmail,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75), fontSize: 12)),
                ],
              ],
            ),
          ),

          // Department Info
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.apartment, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Text('Department',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 6),
                Text(
                  _departmentName.isNotEmpty
                      ? _departmentName
                      : 'Dept #${_hodDepartmentId ?? "N/A"}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (_departmentCode.isNotEmpty)
                  Text('Code: $_departmentCode',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                if (_instituteName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.school, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(_instituteName,
                          style:
                          TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ),
                  ]),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Quick stats in drawer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _drawerStat('${students.length}', 'Students', Colors.blue),
                _drawerStat('${faculty.length}', 'Faculty', Colors.purple),
                _drawerStat(
                    '${(documents.where((d) => d.isPending).length) + (leaves.where((l) => l.isPending).length)}',
                    'Pending',
                    Colors.orange),
              ],
            ),
          ),

          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () => _handleSignOut(context),
          ),
        ],
      ),
    );
  }

  Widget _drawerStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // OVERVIEW TAB
  // ─────────────────────────────────────────────

  Widget _buildOverviewTab() {
    if (_stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Department banner ──
          if (_departmentName.isNotEmpty) _buildDepartmentBanner(),
          const SizedBox(height: 16),

          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard('Total Students', '${_stats!.totalStudents}',
                  Icons.school, Colors.blue),
              _buildStatCard('Active Students', '${_stats!.activeStudents}',
                  Icons.check_circle, Colors.green),
              _buildStatCard('Faculty Members', '${_stats!.totalFaculty}',
                  Icons.people, Colors.purple),
              _buildStatCard('Pending Items', '${_stats!.totalPendingItems}',
                  Icons.pending_actions, Colors.orange),
            ],
          ),
          const SizedBox(height: 20),

          _buildPendingActionsSummary(),
          const SizedBox(height: 20),

          _buildQuickActions(),
          const SizedBox(height: 20),

          _buildTodayActivity(),
        ],
      ),
    );
  }

  Widget _buildDepartmentBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.apartment, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_departmentName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                if (_departmentCode.isNotEmpty)
                  Text('Code: $_departmentCode',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 12)),
                if (_instituteName.isNotEmpty)
                  Text(_instituteName,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75), fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_stats?.totalStudents ?? 0}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const Text('Students',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(
                  color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildPendingActionsSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pending Approvals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildPendingItem(
              'Documents', _stats!.pendingDocuments, Colors.blue, Icons.description,
                  () => _tabController.animateTo(1)),
          _buildPendingItem(
              'Leave Applications', _stats!.pendingLeaves, Colors.orange, Icons.event_busy,
                  () => _tabController.animateTo(2)),
          _buildPendingItem(
              'Activity Requests', _stats!.pendingActivities, Colors.purple, Icons.star,
                  () => _tabController.animateTo(3)),
        ],
      ),
    );
  }

  Widget _buildPendingItem(
      String title, int count, Color color, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: count > 0 ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: count > 0 ? color : Colors.grey,
                borderRadius: BorderRadius.circular(20)),
            child: Text('$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ]),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _quickActionButton(
                  Icons.description_outlined,
                  'Review\nDocuments',
                  Colors.blue,
                      () => _tabController.animateTo(1)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _quickActionButton(
                  Icons.event_busy_outlined,
                  'Review\nLeaves',
                  Colors.orange,
                      () => _tabController.animateTo(2)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _quickActionButton(
                  Icons.star_outline,
                  'Review\nActivities',
                  Colors.purple,
                      () => _tabController.animateTo(3)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _quickActionButton(
                  Icons.bar_chart_outlined,
                  'View\nStats',
                  Colors.teal,
                      () => _showDeptStatsDialog()),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickActionButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showDeptStatsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(children: [
          Icon(Icons.bar_chart, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          const Text('Department Statistics'),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statRow('Department', _departmentName),
              _statRow('Code', _departmentCode),
              _statRow('Institute', _instituteName),
              const Divider(),
              _statRow('Total Students', '${_stats?.totalStudents ?? 0}'),
              _statRow('Active Students', '${_stats?.activeStudents ?? 0}'),
              _statRow(
                  'Inactive Students',
                  '${(_stats?.totalStudents ?? 0) - (_stats?.activeStudents ?? 0)}'),
              const Divider(),
              _statRow('Faculty Members', '${_stats?.totalFaculty ?? 0}'),
              const Divider(),
              _statRow('Pending Documents', '${_stats?.pendingDocuments ?? 0}'),
              _statRow('Pending Leaves', '${_stats?.pendingLeaves ?? 0}'),
              _statRow('Pending Activities', '${_stats?.pendingActivities ?? 0}'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Close'))
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTodayActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.today, color: Colors.blue),
            const SizedBox(width: 8),
            const Text("Today's Activity",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(DateFormat('d MMM y').format(DateTime.now()),
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Column(children: [
                Text('${_stats?.documentsReviewedToday ?? 0}',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
                const Text('Docs Reviewed',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center),
              ]),
            ),
            Container(width: 1, height: 50, color: Colors.grey[300]),
            Expanded(
              child: Column(children: [
                Text('${_stats?.leavesReviewedToday ?? 0}',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue)),
                const Text('Leaves Processed',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center),
              ]),
            ),
            Container(width: 1, height: 50, color: Colors.grey[300]),
            Expanded(
              child: Column(children: [
                Text('${activities.where((a) => a.status == 'approved').length}',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple)),
                const Text('Activities\nApproved',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center),
              ]),
            ),
          ]),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // DOCUMENTS TAB
  // ─────────────────────────────────────────────

  Widget _buildDocumentsTab() {
    final pendingDocs = documents.where((d) => d.isPending).toList();
    final approvedDocs = documents.where((d) => d.isApproved).toList();
    final rejectedDocs = documents.where((d) => d.isRejected).toList();

    return DefaultTabController(
      length: 4,
      child: Column(children: [
        Container(
          color: Colors.white,
          child: TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: 'All (${documents.length})'),
              Tab(text: 'Pending (${pendingDocs.length})'),
              Tab(text: 'Approved (${approvedDocs.length})'),
              Tab(text: 'Rejected (${rejectedDocs.length})'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(children: [
            _buildDocumentsList(documents),
            _buildDocumentsList(pendingDocs),
            _buildDocumentsList(approvedDocs),
            _buildDocumentsList(rejectedDocs),
          ]),
        ),
      ]),
    );
  }

  Widget _buildDocumentsList(List<DocumentForReview> docs) {
    if (docs.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No documents found', style: TextStyle(color: Colors.grey[600])),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (_, i) => _buildDocumentCard(docs[i]),
    );
  }

  Widget _buildDocumentCard(DocumentForReview doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openDocumentReview(doc),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(_getDocumentTypeIcon(doc.documentType),
                    color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(doc.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${doc.studentName} (${doc.rollNumber})',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ]),
              ),
              _buildStatusBadge(doc.status),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _buildInfoChip(doc.displayType, Colors.purple),
              _buildInfoChip(DateFormat('MMM dd, yyyy').format(doc.createdAt), Colors.grey),
              if (doc.pointsAwarded > 0)
                _buildInfoChip('${doc.pointsAwarded} pts', Colors.amber),
            ]),
            if (doc.description != null && doc.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(doc.description!,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            if (doc.isPending) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openDocumentReview(doc),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Review Document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
            if (doc.hodRemarks != null && doc.hodRemarks!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.comment, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(doc.hodRemarks!,
                          style: const TextStyle(fontSize: 12))),
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  IconData _getDocumentTypeIcon(String type) {
    switch (type) {
      case 'technical_skill': return Icons.computer;
      case 'internship': return Icons.work;
      case 'seminar': return Icons.school;
      case 'certification': return Icons.verified;
      default: return Icons.description;
    }
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved': color = Colors.green; break;
      case 'rejected': color = Colors.red; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _openDocumentReview(DocumentForReview doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HODDocumentReviewPage(
          document: doc,
          onReviewComplete: _refreshData,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LEAVES TAB
  // ─────────────────────────────────────────────

  Widget _buildLeavesTab() {
    final pending = leaves.where((l) => l.isPending).toList();
    final approved = leaves.where((l) => l.isApproved).toList();
    final rejected = leaves.where((l) => l.isRejected).toList();

    return DefaultTabController(
      length: 4,
      child: Column(children: [
        Container(
          color: Colors.white,
          child: TabBar(
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
            tabs: [
              Tab(text: 'All (${leaves.length})'),
              Tab(text: 'Pending (${pending.length})'),
              Tab(text: 'Approved (${approved.length})'),
              Tab(text: 'Rejected (${rejected.length})'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(children: [
            _buildLeaveList(leaves),
            _buildLeaveList(pending),
            _buildLeaveList(approved),
            _buildLeaveList(rejected),
          ]),
        ),
      ]),
    );
  }

  Widget _buildLeaveList(List<LeaveForReview> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No leave applications', style: TextStyle(color: Colors.grey[600])),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildLeaveCard(list[i]),
    );
  }

  Widget _buildLeaveCard(LeaveForReview leave) {
    final days = leave.toDate.difference(leave.fromDate).inDays + 1;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.event_busy, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(leave.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(leave.studentName,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ]),
            ),
            _buildStatusBadge(leave.status),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('From', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  Text(DateFormat('dd MMM yyyy').format(leave.fromDate),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(children: [
                Icon(Icons.arrow_forward, size: 18, color: Colors.grey[500]),
                Text('$days day${days > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              ]),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('To', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  Text(DateFormat('dd MMM yyyy').format(leave.toDate),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ),
            ),
          ]),
          if (leave.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(leave.description,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          if (leave.isPending) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _reviewLeave(leave, false),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _reviewLeave(leave, true),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                ),
              ),
            ]),
          ],
          if (leave.hodRemarks != null && leave.hodRemarks!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.comment, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(leave.hodRemarks!,
                        style: const TextStyle(fontSize: 12))),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  Future<void> _reviewLeave(LeaveForReview leave, bool approve) async {
    final remarksController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(approve ? 'Approve Leave' : 'Reject Leave'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            approve
                ? 'Approve leave for ${leave.studentName}?'
                : 'Reject leave for ${leave.studentName}?',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: remarksController,
            decoration: const InputDecoration(
              labelText: 'Remarks (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: approve ? Colors.green : Colors.red,
                foregroundColor: Colors.white),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Matches HODService.reviewLeave(leaveId: String, action: String, remarks: String?)
        final success = await HODService.reviewLeave(
          leaveId: leave.id,
          action: approve ? 'approve' : 'reject',
          remarks: remarksController.text.trim().isEmpty
              ? null
              : remarksController.text.trim(),
        );
        if (success) {
          _showSnackbar(
              approve ? 'Leave approved successfully' : 'Leave rejected',
              approve ? Colors.green : Colors.red);
          await _refreshData();
        } else {
          _showSnackbar('Failed to update leave. Please try again.', Colors.red);
        }
      } catch (e) {
        _showSnackbar('Error: $e', Colors.red);
      }
    }
  }

  // ─────────────────────────────────────────────
  // ACTIVITIES TAB
  // ─────────────────────────────────────────────

  Widget _buildActivitiesTab() {
    final pending = activities.where((a) => a.status == 'pending').toList();
    final approved = activities.where((a) => a.status == 'approved').toList();
    final rejected = activities.where((a) => a.status == 'rejected').toList();

    return DefaultTabController(
      length: 4,
      child: Column(children: [
        Container(
          color: Colors.white,
          child: TabBar(
            labelColor: Colors.purple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.purple,
            tabs: [
              Tab(text: 'All (${activities.length})'),
              Tab(text: 'Pending (${pending.length})'),
              Tab(text: 'Approved (${approved.length})'),
              Tab(text: 'Rejected (${rejected.length})'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(children: [
            _buildActivityList(activities),
            _buildActivityList(pending),
            _buildActivityList(approved),
            _buildActivityList(rejected),
          ]),
        ),
      ]),
    );
  }

  Widget _buildActivityList(List<ApprovalRequest> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.star_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No activities found', style: TextStyle(color: Colors.grey[600])),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildActivityCard(list[i]),
    );
  }

  Widget _buildActivityCard(ApprovalRequest activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.star, color: Colors.purple, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(activity.title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                Text(activity.studentName,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ]),
            ),
            _buildStatusBadge(activity.status),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: [
            _buildInfoChip(activity.type, Colors.indigo),
            _buildInfoChip(activity.submittedDate, Colors.grey),
            if (activity.points > 0)
              _buildInfoChip('${activity.points} pts', Colors.amber),
          ]),
          if (activity.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(activity.description,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          if (activity.status == 'pending') ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _reviewActivity(activity, false),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _reviewActivity(activity, true),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  Future<void> _reviewActivity(ApprovalRequest activity, bool approve) async {
    final remarksController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(approve ? 'Approve Activity' : 'Reject Activity'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('"${activity.title}" by ${activity.studentName}',
              style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 16),
          TextField(
            controller: remarksController,
            decoration: const InputDecoration(
              labelText: 'Remarks (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: approve ? Colors.green : Colors.red,
                foregroundColor: Colors.white),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await supabase.from('activities').update({
          'status': approve ? 'approved' : 'rejected',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', int.parse(activity.id));

        setState(() => activity.status = approve ? 'approved' : 'rejected');
        _showSnackbar(
            approve ? 'Activity approved' : 'Activity rejected',
            approve ? Colors.green : Colors.red);
        await _refreshData();
      } catch (e) {
        _showSnackbar('Error: $e', Colors.red);
      }
    }
  }

  // ─────────────────────────────────────────────
  // STUDENTS TAB
  // ─────────────────────────────────────────────

  Widget _buildStudentsTab() {
    final filtered = students.where((s) {
      if (_studentSearch.isEmpty) return true;
      final q = _studentSearch.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          s.rollNumber.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q);
    }).toList();

    return Column(children: [
      // Search bar
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: _studentSearchController,
          decoration: InputDecoration(
            hintText: 'Search by name, roll number...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _studentSearch.isNotEmpty
                ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _studentSearchController.clear();
                  setState(() => _studentSearch = '');
                })
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          ),
          onChanged: (v) => setState(() => _studentSearch = v),
        ),
      ),

      // Count header
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(children: [
          Text('${filtered.length} student${filtered.length != 1 ? 's' : ''}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ]),
      ),

      Expanded(
        child: filtered.isEmpty
            ? Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.school, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('No students found', style: TextStyle(color: Colors.grey[600])),
            ]))
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: filtered.length,
          itemBuilder: (_, i) => _buildStudentCard(filtered[i]),
        ),
      ),
    ]);
  }

  Widget _buildStudentCard(Student student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(student.name[0].toUpperCase(),
              style: TextStyle(
                  color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
        ),
        title: Text(student.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${student.rollNumber} • Year ${student.year} • CGPA: ${student.cgpa.toStringAsFixed(2)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: student.status == 'Active' ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(student.status,
                  style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ],
        ),
        onTap: () => _showStudentDetail(student),
      ),
    );
  }

  void _showStudentDetail(Student student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        builder: (_, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Row(children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue.shade100,
                child: Text(student.name[0].toUpperCase(),
                    style: TextStyle(
                        fontSize: 24,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(student.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(student.rollNumber,
                      style: TextStyle(color: Colors.grey[600])),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: student.status == 'Active'
                        ? Colors.green
                        : Colors.red,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(student.status,
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ]),
            const Divider(height: 28),
            _detailRow(Icons.email, 'Email', student.email),
            _detailRow(Icons.phone, 'Phone', student.phone),
            _detailRow(Icons.calendar_today, 'Year', student.year),
            _detailRow(Icons.account_tree, 'Branch', student.branch),
            _detailRow(Icons.grade, 'CGPA', student.cgpa.toStringAsFixed(2)),
            _detailRow(
                Icons.contact_phone, 'Parent Contact', student.parentContact),
            if (student.admissionDate.isNotEmpty)
              _detailRow(Icons.event, 'Admission Date', student.admissionDate),
          ]),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.blue.shade400),
        const SizedBox(width: 10),
        Text('$label: ',
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Expanded(
            child: Text(value.isNotEmpty ? value : 'N/A',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  // FACULTY TAB
  // ─────────────────────────────────────────────

  Widget _buildFacultyTab() {
    final filtered = faculty.where((f) {
      if (_facultySearch.isEmpty) return true;
      final q = _facultySearch.toLowerCase();
      return f.name.toLowerCase().contains(q) ||
          f.email.toLowerCase().contains(q) ||
          f.designation.toLowerCase().contains(q);
    }).toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: _facultySearchController,
          decoration: InputDecoration(
            hintText: 'Search by name, designation...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _facultySearch.isNotEmpty
                ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _facultySearchController.clear();
                  setState(() => _facultySearch = '');
                })
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          ),
          onChanged: (v) => setState(() => _facultySearch = v),
        ),
      ),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(children: [
          Text('${filtered.length} faculty member${filtered.length != 1 ? 's' : ''}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ]),
      ),

      Expanded(
        child: filtered.isEmpty
            ? Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.people, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('No faculty members found',
                  style: TextStyle(color: Colors.grey[600])),
            ]))
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: filtered.length,
          itemBuilder: (_, i) => _buildFacultyCard(filtered[i]),
        ),
      ),
    ]);
  }

  Widget _buildFacultyCard(Faculty member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade100,
          child: Text(member.name[0].toUpperCase(),
              style: TextStyle(
                  color: Colors.purple.shade700, fontWeight: FontWeight.bold)),
        ),
        title: Text(member.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${member.designation} • ${member.experience} yrs exp'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: member.status == 'Active' ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(member.status,
                  style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ],
        ),
        onTap: () => _showFacultyDetail(member),
      ),
    );
  }

  void _showFacultyDetail(Faculty member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        builder: (_, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Row(children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.purple.shade100,
                child: Text(member.name[0].toUpperCase(),
                    style: TextStyle(
                        fontSize: 24,
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(member.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(member.designation,
                      style: TextStyle(color: Colors.grey[600])),
                ]),
              ),
            ]),
            const Divider(height: 28),
            _detailRow(Icons.email, 'Email', member.email),
            _detailRow(Icons.phone, 'Phone', member.phone),
            _detailRow(Icons.school, 'Qualification', member.qualification),
            _detailRow(
                Icons.work, 'Experience', '${member.experience} years'),
            if (member.joiningDate.isNotEmpty)
              _detailRow(Icons.event, 'Joined', member.joiningDate),
            if (member.subjects.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Subjects',
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: member.subjects
                    .map((s) => _buildInfoChip(s, Colors.purple))
                    .toList(),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SIGN OUT
// ─────────────────────────────────────────────

Future<void> _handleSignOut(BuildContext context) async {
  try {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (r) => false);
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red),
      );
    }
  }
}