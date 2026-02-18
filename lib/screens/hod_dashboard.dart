// lib/screens/hod_dashboard.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../models/hod_models.dart';
import 'hod_document_review_page.dart';
import '../services/hod_service.dart';

// Get Supabase client
SupabaseClient get supabase => Supabase.instance.client;

// Import your existing models from main.dart or create separate files
// For now, we'll use these simplified versions that should match your DB

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
    final departmentBigInt = deptId is int ? BigInt.from(deptId) : (deptId is BigInt ? deptId : BigInt.zero);

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
    final departmentBigInt = deptId is int ? BigInt.from(deptId) : (deptId is BigInt ? deptId : BigInt.zero);

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
  String? _hodName;
  bool isAuthReady = false;

  // Loading states
  bool isLoading = true;
  bool isRefreshing = false;

  // Stats
  HODStats? _stats;

  // Data lists
  List<Student> students = [];
  List<Faculty> faculty = [];
  List<DocumentForReview> documents = [];
  List<LeaveForReview> leaves = [];
  List<ApprovalRequest> activities = [];

  // Real-time subscriptions
  StreamSubscription? _documentsSubscription;
  StreamSubscription? _leavesSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _checkAuthAndSetupData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _documentsSubscription?.cancel();
    _leavesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthAndSetupData() async {
    setState(() => isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      // Get HOD department
      _hodDepartmentId = await HODService.getHODDepartmentId();

      if (_hodDepartmentId == null) {
        _showSnackbar('Error: HOD department not found', Colors.red);
        setState(() => isLoading = false);
        return;
      }

      // Get HOD name
      final profileResponse = await supabase
          .from('profiles')
          .select('first_name, last_name')
          .eq('id', user.id)
          .single();

      _hodName = '${profileResponse['first_name'] ?? ''} ${profileResponse['last_name'] ?? ''}'.trim();

      setState(() => isAuthReady = true);

      // Load all data
      await _loadAllData();
      await _setupRealTimeSubscriptions();

      setState(() => isLoading = false);
    } catch (e) {
      print('Setup error: $e');
      _showSnackbar('Failed to load dashboard', Colors.red);
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadAllData() async {
    if (_hodDepartmentId == null) return;

    try {
      // Load stats
      _stats = await HODService.getHODStats(_hodDepartmentId!);

      // Load students
      await _loadStudents();

      // Load faculty
      await _loadFaculty();

      // Load documents
      documents = await HODService.getDocumentsForReview(
        departmentId: _hodDepartmentId,
      );

      // Load leaves
      leaves = await HODService.getLeavesForReview(
        departmentId: _hodDepartmentId,
      );

      // Load activities
      await _loadActivities();

      setState(() {});
    } catch (e) {
      print('Error loading data: $e');
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
      print('Error loading students: $e');
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
      print('Error loading faculty: $e');
    }
  }

  Future<void> _loadActivities() async {
    try {
      final response = await supabase
          .from('activities')
          .select('''
            *,
            students!inner(
              id,
              first_name,
              last_name,
              department_id
            )
          ''')
          .eq('students.department_id', _hodDepartmentId!.toInt())
          .order('created_at', ascending: false);

      final studentNamesMap = {
        for (var student in students) student.id: student.name
      };

      activities = (response as List).map((a) {
        final studentId = a['student_id']?.toString() ?? '';
        final studentName = studentNamesMap[studentId] ?? 'Unknown Student';
        return ApprovalRequest.fromMap(a, studentName);
      }).toList();
    } catch (e) {
      print('Error loading activities: $e');
    }
  }

  Future<void> _setupRealTimeSubscriptions() async {
    // Documents subscription
    _documentsSubscription = supabase
        .from('student_documents')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((data) async {
      documents = await HODService.getDocumentsForReview(
        departmentId: _hodDepartmentId,
      );
      if (mounted) setState(() {});
    });

    // Leaves subscription
    _leavesSubscription = supabase
        .from('leave_applications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((data) async {
      leaves = await HODService.getLeavesForReview(
        departmentId: _hodDepartmentId,
      );
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
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
              Text(
                'Loading HOD Dashboard...',
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HOD Dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Welcome, ${_hodName ?? 'HOD'} • Dept ID: ${_hodDepartmentId ?? 'N/A'}',
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
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Icon(Icons.refresh),
            onPressed: isRefreshing ? null : _refreshData,
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
            const Tab(
              icon: Icon(Icons.dashboard),
              text: 'Overview',
            ),
            Tab(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.description),
                  if (_stats != null && _stats!.pendingDocuments > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${_stats!.pendingDocuments}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              text: 'Documents',
            ),
            Tab(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.event_busy),
                  if (_stats != null && _stats!.pendingLeaves > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${_stats!.pendingLeaves}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              text: 'Leaves',
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
          _buildStudentsTab(),
          _buildFacultyTab(),
        ],
      ),
    );
  }

  // Overview Tab
  Widget _buildOverviewTab() {
    if (_stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard(
                'Total Students',
                _stats!.totalStudents.toString(),
                Icons.school,
                Colors.blue,
              ),
              _buildStatCard(
                'Active Students',
                _stats!.activeStudents.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatCard(
                'Faculty Members',
                _stats!.totalFaculty.toString(),
                Icons.people,
                Colors.purple,
              ),
              _buildStatCard(
                'Pending Items',
                _stats!.totalPendingItems.toString(),
                Icons.pending_actions,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Pending Actions Summary
          _buildPendingActionsSummary(),

          const SizedBox(height: 24),

          // Today's Activity
          _buildTodayActivity(),
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
            color: color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
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
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pending Approvals',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPendingItem(
            'Documents',
            _stats!.pendingDocuments,
            Colors.blue,
            Icons.description,
                () => _tabController.animateTo(1),
          ),
          _buildPendingItem(
            'Leave Applications',
            _stats!.pendingLeaves,
            Colors.orange,
            Icons.event_busy,
                () => _tabController.animateTo(2),
          ),
          _buildPendingItem(
            'Activity Requests',
            _stats!.pendingActivities,
            Colors.purple,
            Icons.star,
                () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPendingItem(
      String title,
      int count,
      Color color,
      IconData icon,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: count > 0 ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: count > 0 ? color : Colors.grey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ],
        ),
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                "Today's Activity",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_stats!.documentsReviewedToday}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Text(
                      'Documents Reviewed',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 50, color: Colors.grey[300]),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_stats!.leavesReviewedToday}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      'Leaves Processed',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Documents Tab
  Widget _buildDocumentsTab() {
    final pendingDocs = documents.where((d) => d.isPending).toList();
    final approvedDocs = documents.where((d) => d.isApproved).toList();
    final rejectedDocs = documents.where((d) => d.isRejected).toList();

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
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
            child: TabBarView(
              children: [
                _buildDocumentsList(documents),
                _buildDocumentsList(pendingDocs),
                _buildDocumentsList(approvedDocs),
                _buildDocumentsList(rejectedDocs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList(List<DocumentForReview> docs) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No documents found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return _buildDocumentCard(doc);
      },
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getDocumentTypeIcon(doc.documentType),
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${doc.studentName} (${doc.rollNumber})',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(doc.status),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(doc.displayType, Colors.purple),
                  _buildInfoChip(
                    DateFormat('MMM dd, yyyy').format(doc.createdAt),
                    Colors.grey,
                  ),
                  if (doc.pointsAwarded > 0)
                    _buildInfoChip('${doc.pointsAwarded} pts', Colors.amber),
                ],
              ),
              if (doc.description != null && doc.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  doc.description!,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.comment, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          doc.hodRemarks!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDocumentTypeIcon(String type) {
    switch (type) {
      case 'technical_skill':
        return Icons.computer;
      case 'internship':
        return Icons.work;
      case 'seminar':
        return Icons.school;
      case 'certification':
        return Icons.verified;
      default:
        return Icons.description;
    }
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _openDocumentReview(DocumentForReview doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HODDocumentReviewPage(
          document: doc,
          onReviewComplete: () {
            _refreshData();
          },
        ),
      ),
    );
  }

  // Leaves Tab (simplified for now)
  Widget _buildLeavesTab() {
    return Center(
      child: Text('Leaves tab - ${leaves.length} total'),
    );
  }

  // Students Tab
  Widget _buildStudentsTab() {
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No students found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                student.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              student.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${student.rollNumber} • Year ${student.year} • CGPA: ${student.cgpa}',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: student.status == 'Active' ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                student.status,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        );
      },
    );
  }

  // Faculty Tab
  Widget _buildFacultyTab() {
    if (faculty.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No faculty members found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: faculty.length,
      itemBuilder: (context, index) {
        final member = faculty[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.shade100,
              child: Text(
                member.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Colors.purple.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              member.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${member.designation} • ${member.experience} years exp',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: member.status == 'Active' ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                member.status,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        );
      },
    );
  }
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
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}