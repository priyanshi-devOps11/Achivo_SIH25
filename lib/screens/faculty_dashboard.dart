// lib/screens/faculty_dashboard.dart
// PRODUCTION VERSION - Real-time, department-filtered, subject-based attendance
// FIX: Marks now use courses linked by faculty_id (not ilike name search)
// FIX: Attendance also uses the same course lookup approach

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

SupabaseClient get supabase => Supabase.instance.client;

// ============================================================
// DATA MODELS
// ============================================================

class FacultyProfile {
  final String id;
  final String userId;
  final String facultyId;
  final String firstName;
  final String lastName;
  final String email;
  final int? departmentId;
  final List<String> subjects;
  final String designation;

  FacultyProfile({
    required this.id,
    required this.userId,
    required this.facultyId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.departmentId,
    required this.subjects,
    required this.designation,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory FacultyProfile.fromMap(Map<String, dynamic> m) {
    final subjectsRaw = m['subjects'];
    List<String> subjectsList = [];
    if (subjectsRaw is List) {
      subjectsList = subjectsRaw.map((e) => e.toString()).toList();
    }
    return FacultyProfile(
      id: m['id']?.toString() ?? '',
      userId: m['user_id']?.toString() ?? '',
      facultyId: m['faculty_id']?.toString() ?? '',
      firstName: m['first_name'] ?? '',
      lastName: m['last_name'] ?? '',
      email: m['email'] ?? '',
      departmentId: m['department_id'] is int ? m['department_id'] : null,
      subjects: subjectsList,
      designation: m['designation'] ?? 'Faculty',
    );
  }
}

// A course row fetched from DB, linked to this faculty
class CourseItem {
  final int id;
  final String courseName;
  final String courseCode;

  CourseItem({required this.id, required this.courseName, required this.courseCode});

  factory CourseItem.fromMap(Map<String, dynamic> m) {
    return CourseItem(
      id: m['id'] as int,
      courseName: m['course_name']?.toString() ?? 'Unknown',
      courseCode: m['course_code']?.toString() ?? '',
    );
  }

  /// Display label shown in dropdowns
  String get displayName => courseName;
}

class DeptStudent {
  final String id;
  final String firstName;
  final String lastName;
  final String rollNumber;
  final String year;
  final String email;
  final bool isActive;

  DeptStudent({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.rollNumber,
    required this.year,
    required this.email,
    required this.isActive,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory DeptStudent.fromMap(Map<String, dynamic> m) {
    return DeptStudent(
      id: m['id']?.toString() ?? '',
      firstName: m['first_name'] ?? '',
      lastName: m['last_name'] ?? '',
      rollNumber: m['roll_number'] ?? '',
      year: m['year'] ?? '',
      email: m['email'] ?? '',
      isActive: m['is_active'] == true,
    );
  }
}

class AttendanceSummary {
  final int total;
  final int present;

  AttendanceSummary({required this.total, required this.present});

  double get percentage => total == 0 ? 0 : (present / total) * 100;
}

// ============================================================
// FACULTY DASHBOARD
// ============================================================

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  FacultyProfile? _faculty;
  List<DeptStudent> _students = [];
  // ✅ FIX: Load actual courses linked to this faculty from DB
  List<CourseItem> _courses = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _selectedIndex = 0;

  // Attendance state — uses CourseItem, not raw subject name
  CourseItem? _selectedCourse;
  DateTime _selectedDate = DateTime.now();
  Map<String, String> _attendanceMap = {};
  bool _isSavingAttendance = false;
  Map<String, AttendanceSummary> _attendanceSummaryMap = {};

  // Marks state
  CourseItem? _selectedMarkCourse;
  String _selectedExamType = 'internal';
  Map<String, TextEditingController> _markControllers = {};
  bool _isSavingMarks = false;

  StreamSubscription? _studentsSub;
  StreamSubscription? _attendanceSub;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  @override
  void dispose() {
    _studentsSub?.cancel();
    _attendanceSub?.cancel();
    for (final c in _markControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> _initializeDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/welcome');
        return;
      }

      final resp = await supabase
          .from('faculty')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (resp == null) {
        setState(() {
          _errorMessage = 'Faculty profile not found. Contact admin.';
          _isLoading = false;
        });
        return;
      }

      _faculty = FacultyProfile.fromMap(resp);

      // ✅ FIX: Load courses from DB that belong to this faculty
      await _loadFacultyCourses();

      await _loadStudents();
      await _loadTodaysAttendance();
      await _loadAttendanceSummaries();
      _setupRealTimeListeners();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load dashboard: $e';
        _isLoading = false;
      });
    }
  }

  /// ✅ FIX: Fetch courses where faculty_id = this faculty's id
  Future<void> _loadFacultyCourses() async {
    if (_faculty == null) return;
    try {
      final resp = await supabase
          .from('courses')
          .select('id, course_name, course_code')
          .eq('faculty_id', _faculty!.id)
          .eq('is_active', true)
          .order('course_name', ascending: true);

      _courses = (resp as List).map((m) => CourseItem.fromMap(m)).toList();

      if (_courses.isNotEmpty) {
        _selectedCourse     = _courses.first;
        _selectedMarkCourse = _courses.first;
      }

      print('✅ Loaded ${_courses.length} courses for faculty ${_faculty!.fullName}');
    } catch (e) {
      debugPrint('Error loading faculty courses: $e');
    }
  }

  Future<void> _loadStudents() async {
    if (_faculty?.departmentId == null) {
      _students = [];
      return;
    }

    try {
      final resp = await supabase
          .from('students')
          .select()
          .eq('department_id', _faculty!.departmentId!)
          .eq('is_active', true)
          .order('roll_number', ascending: true);

      _students = (resp as List).map((m) => DeptStudent.fromMap(m)).toList();
      _initMarkControllers();
    } catch (e) {
      debugPrint('Error loading students: $e');
    }
  }

  void _initMarkControllers() {
    for (final c in _markControllers.values) {
      c.dispose();
    }
    _markControllers = {};
    for (final s in _students) {
      _markControllers[s.id] = TextEditingController();
    }
  }

  Future<void> _loadTodaysAttendance() async {
    if (_selectedCourse == null || _students.isEmpty) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    try {
      final resp = await supabase
          .from('attendance')
          .select('student_id, status')
          .eq('course_id', _selectedCourse!.id)   // ✅ use real course id
          .eq('date', dateStr)
          .inFilter('student_id', _students.map((s) => s.id).toList());

      final map = <String, String>{};
      for (final r in (resp as List)) {
        map[r['student_id'].toString()] = r['status'].toString();
      }
      if (mounted) setState(() => _attendanceMap = map);
    } catch (e) {
      debugPrint('Error loading attendance: $e');
    }
  }

  Future<void> _loadAttendanceSummaries() async {
    if (_students.isEmpty) return;

    try {
      final resp = await supabase
          .from('attendance')
          .select('student_id, status')
          .inFilter('student_id', _students.map((s) => s.id).toList());

      final grouped = <String, List<String>>{};
      for (final r in (resp as List)) {
        final sid = r['student_id'].toString();
        grouped.putIfAbsent(sid, () => []).add(r['status'].toString());
      }

      final summaryMap = <String, AttendanceSummary>{};
      for (final s in _students) {
        final records = grouped[s.id] ?? [];
        final present = records.where((st) => st == 'present').length;
        summaryMap[s.id] = AttendanceSummary(total: records.length, present: present);
      }

      if (mounted) setState(() => _attendanceSummaryMap = summaryMap);
    } catch (e) {
      debugPrint('Error loading attendance summaries: $e');
    }
  }

  void _setupRealTimeListeners() {
    if (_faculty?.departmentId == null) return;

    _studentsSub = supabase
        .from('students')
        .stream(primaryKey: ['id'])
        .order('roll_number', ascending: true)
        .listen((data) async {
      final filtered = data
          .where((m) => m['department_id'] == _faculty!.departmentId && m['is_active'] == true)
          .map((m) => DeptStudent.fromMap(m))
          .toList();
      if (mounted) {
        setState(() => _students = filtered);
        _initMarkControllers();
        await _loadAttendanceSummaries();
      }
    });

    _attendanceSub = supabase
        .from('attendance')
        .stream(primaryKey: ['id'])
        .listen((_) async {
      await _loadTodaysAttendance();
      await _loadAttendanceSummaries();
    });
  }

  // ============================================================
  // ATTENDANCE ACTIONS
  // ============================================================

  void _toggleAttendance(String studentId, String status) {
    setState(() {
      if (_attendanceMap[studentId] == status) {
        _attendanceMap.remove(studentId);
      } else {
        _attendanceMap[studentId] = status;
      }
    });
  }

  void _markAllPresent() {
    setState(() {
      for (final s in _students) {
        _attendanceMap[s.id] = 'present';
      }
    });
  }

  void _clearAll() {
    setState(() => _attendanceMap.clear());
  }

  Future<void> _saveAttendance() async {
    if (_selectedCourse == null) {
      _showSnack('Please select a course first.', Colors.orange);
      return;
    }
    if (_attendanceMap.isEmpty) {
      _showSnack('Please mark attendance for at least one student.', Colors.orange);
      return;
    }

    setState(() => _isSavingAttendance = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      for (final entry in _attendanceMap.entries) {
        await supabase.from('attendance').upsert(
          {
            'student_id': entry.key,
            'course_id': _selectedCourse!.id,   // ✅ real course id
            'date': dateStr,
            'status': entry.value,
            'marked_by': _faculty!.id,
            'remarks': _selectedCourse!.courseName,
          },
          onConflict: 'student_id,course_id,date',
        );
      }

      _showSnack('Attendance saved for ${_attendanceMap.length} students!', Colors.green);
      await _loadAttendanceSummaries();
    } catch (e) {
      _showSnack('Error saving attendance: $e', Colors.red);
    } finally {
      setState(() => _isSavingAttendance = false);
    }
  }

  // ============================================================
  // MARKS ACTIONS
  // ============================================================

  Future<void> _loadExistingMarks() async {
    if (_selectedMarkCourse == null || _students.isEmpty) return;

    try {
      final resp = await supabase
          .from('course_enrollments')
          .select('student_id, internal_marks, external_marks, marks')
          .eq('course_id', _selectedMarkCourse!.id)   // ✅ use real course id
          .inFilter('student_id', _students.map((s) => s.id).toList());

      for (final r in (resp as List)) {
        final sid = r['student_id']?.toString() ?? '';
        if (_markControllers.containsKey(sid)) {
          final val = _selectedExamType == 'internal'
              ? r['internal_marks']
              : r['external_marks'] ?? r['marks'];
          if (val != null) {
            _markControllers[sid]!.text = val.toString().replaceAll('.0', '');
          } else {
            _markControllers[sid]!.clear();
          }
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading marks: $e');
    }
  }

  Future<void> _saveMarks() async {
    // ✅ FIX: No more ilike search — we already have the course id
    if (_selectedMarkCourse == null) {
      _showSnack('Please select a course.', Colors.orange);
      return;
    }

    setState(() => _isSavingMarks = true);

    int saved = 0;
    int failed = 0;

    for (final s in _students) {
      final text = _markControllers[s.id]?.text.trim() ?? '';
      if (text.isEmpty) continue;

      final marks = int.tryParse(text);
      if (marks == null) {
        failed++;
        continue;
      }

      try {
        final updateData = _selectedExamType == 'internal'
            ? {'internal_marks': marks.toDouble()}
            : {'external_marks': marks.toDouble()};

        await supabase.from('course_enrollments').upsert(
          {
            'student_id': s.id,
            'course_id': _selectedMarkCourse!.id,   // ✅ real course id
            ...updateData,
          },
          onConflict: 'student_id,course_id',
        );
        saved++;
      } catch (e) {
        failed++;
        debugPrint('Error saving mark for ${s.fullName}: $e');
      }
    }

    setState(() => _isSavingMarks = false);

    if (failed > 0) {
      _showSnack('Saved $saved marks. $failed failed.', Colors.orange);
    } else {
      _showSnack('Marks saved for $saved students!', Colors.green);
    }
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _attendanceMap.clear();
      });
      await _loadTodaysAttendance();
    }
  }

  Future<void> _handleSignOut() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (r) => false);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(_errorMessage!, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _initializeDashboard,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: _buildDrawer(),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            ).createShader(b),
            child: const Text(
              'Faculty Portal',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          Text(
            _faculty?.fullName ?? '',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 1,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: () async {
            await _loadFacultyCourses();
            await _loadStudents();
            await _loadTodaysAttendance();
            await _loadAttendanceSummaries();
            _showSnack('Data refreshed!', Colors.green);
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.red),
          tooltip: 'Sign Out',
          onPressed: _handleSignOut,
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    final items = [
      {'icon': Icons.dashboard, 'title': 'Overview', 'index': 0},
      {'icon': Icons.how_to_reg, 'title': 'Mark Attendance', 'index': 1},
      {'icon': Icons.history, 'title': 'Attendance History', 'index': 2},
      {'icon': Icons.grade, 'title': 'Marks', 'index': 3},
    ];

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: Text(
                    (_faculty?.firstName.isNotEmpty == true)
                        ? _faculty!.firstName[0].toUpperCase()
                        : 'F',
                    style: const TextStyle(
                        fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _faculty?.fullName ?? 'Faculty',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  _faculty?.designation ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  'ID: ${_faculty?.facultyId ?? ''}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_students.length} Students  •  ${_courses.length} Courses',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: items.map((item) {
                final isSelected = _selectedIndex == item['index'];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(
                      item['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                    title: Text(
                      item['title'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[800],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      setState(() => _selectedIndex = item['index'] as int);
                      Navigator.pop(context);
                      if (item['index'] == 3) _loadExistingMarks();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return _buildOverviewTab();
      case 1: return _buildAttendanceTab();
      case 2: return _buildAttendanceHistoryTab();
      case 3: return _buildMarksTab();
      default: return _buildOverviewTab();
    }
  }

  // ============================================================
  // OVERVIEW TAB
  // ============================================================

  Widget _buildOverviewTab() {
    final todayPresent = _attendanceMap.values.where((v) => v == 'present').length;
    final todayMarked  = _attendanceMap.length;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadFacultyCourses();
        await _loadStudents();
        await _loadTodaysAttendance();
        await _loadAttendanceSummaries();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${_faculty?.firstName ?? 'Faculty'}! 👋',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _statCard('Total Students', '${_students.length}', Icons.school, Colors.blue),
                _statCard('Active Students', '${_students.where((s) => s.isActive).length}', Icons.check_circle, Colors.green),
                _statCard('Your Courses', '${_courses.length}', Icons.book, Colors.purple),
                _statCard('Marked Today', '$todayMarked', Icons.today, Colors.orange),
              ],
            ),

            const SizedBox(height: 20),

            // ✅ Show actual DB courses (not just subjects array)
            if (_courses.isNotEmpty) ...[
              const Text('Your Courses',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _courses.map((c) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                    ),
                    child: Text(c.displayName,
                        style: const TextStyle(
                            color: Color(0xFF2563EB), fontWeight: FontWeight.w500)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ] else ...[
              // ✅ Helpful message when no courses are linked in DB
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No courses linked to your account in the database.\n'
                            'Ask admin to add courses and assign them to you.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            _buildLowAttendanceWarnings(),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildLowAttendanceWarnings() {
    final low = _students.where((s) {
      final summary = _attendanceSummaryMap[s.id];
      return summary != null && summary.total > 0 && summary.percentage < 75;
    }).toList();

    if (low.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
            const SizedBox(width: 6),
            Text('Low Attendance (${low.length} students)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        ...low.map((s) {
          final summary = _attendanceSummaryMap[s.id]!;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade100,
                child: Text(s.firstName[0].toUpperCase(),
                    style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
              ),
              title: Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Roll: ${s.rollNumber}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${summary.percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // ============================================================
  // ATTENDANCE TAB
  // ============================================================

  Widget _buildAttendanceTab() {
    final presentCount = _attendanceMap.values.where((v) => v == 'present').length;
    final absentCount  = _attendanceMap.values.where((v) => v == 'absent').length;
    final leaveCount   = _attendanceMap.values.where((v) => v == 'leave').length;
    final lateCount    = _attendanceMap.values.where((v) => v == 'late').length;
    final unmarkedCount = _students.length - _attendanceMap.length;

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // ✅ Course dropdown from DB
              Row(
                children: [
                  const Icon(Icons.book, color: Color(0xFF3B82F6), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _courses.isEmpty
                        ? const Text('No courses linked — contact admin',
                        style: TextStyle(color: Colors.orange))
                        : DropdownButtonHideUnderline(
                      child: DropdownButton<CourseItem>(
                        value: _selectedCourse,
                        hint: const Text('Select Course'),
                        isExpanded: true,
                        items: _courses.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(c.displayName),
                          );
                        }).toList(),
                        onChanged: (val) async {
                          setState(() {
                            _selectedCourse = val;
                            _attendanceMap.clear();
                          });
                          await _loadTodaysAttendance();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF3B82F6), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy (EEEE)').format(_selectedDate),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.edit_calendar, size: 16),
                    label: const Text('Change'),
                  ),
                ],
              ),
            ],
          ),
        ),

        Container(
          color: Colors.grey[50],
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat('Present', presentCount, Colors.green),
              _miniStat('Absent', absentCount, Colors.red),
              _miniStat('Leave', leaveCount, Colors.orange),
              _miniStat('Late', lateCount, Colors.purple),
              _miniStat('Unmarked', unmarkedCount, Colors.grey),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _markAllPresent,
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text('All Present'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear All'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _students.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('No students in your department.',
                    style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: _students.length,
            itemBuilder: (context, index) {
              final student = _students[index];
              final status = _attendanceMap[student.id];
              return _buildStudentAttendanceCard(student, status);
            },
          ),
        ),

        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSavingAttendance ? null : _saveAttendance,
              icon: _isSavingAttendance
                  ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_isSavingAttendance ? 'Saving...' : 'Save Attendance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniStat(String label, int count, Color color) {
    return Column(
      children: [
        Text('$count',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStudentAttendanceCard(DeptStudent student, String? status) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: status == 'present'
              ? Colors.green.withOpacity(0.4)
              : status == 'absent'
              ? Colors.red.withOpacity(0.4)
              : status == 'leave'
              ? Colors.orange.withOpacity(0.4)
              : status == 'late'
              ? Colors.purple.withOpacity(0.4)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
              child: Text(
                student.firstName.isNotEmpty ? student.firstName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.fullName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('${student.rollNumber} • Year ${student.year}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _attBtn('P', 'present', status, Colors.green, student.id),
                const SizedBox(width: 4),
                _attBtn('A', 'absent', status, Colors.red, student.id),
                const SizedBox(width: 4),
                _attBtn('L', 'leave', status, Colors.orange, student.id),
                const SizedBox(width: 4),
                _attBtn('La', 'late', status, Colors.purple, student.id),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _attBtn(String label, String value, String? current, Color color, String studentId) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => _toggleAttendance(studentId, value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ATTENDANCE HISTORY TAB
  // ============================================================

  Widget _buildAttendanceHistoryTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const Icon(Icons.history, color: Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Attendance Summary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () async {
                  await _loadAttendanceSummaries();
                  _showSnack('Refreshed!', Colors.green);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _students.isEmpty
              ? Center(
            child: Text('No students found.',
                style: TextStyle(color: Colors.grey[500])),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _students.length,
            itemBuilder: (context, index) {
              final student = _students[index];
              final summary = _attendanceSummaryMap[student.id] ??
                  AttendanceSummary(total: 0, present: 0);
              return _buildAttendanceHistoryCard(student, summary);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceHistoryCard(DeptStudent student, AttendanceSummary summary) {
    final pct = summary.percentage;
    final pctColor = pct >= 75 ? Colors.green : pct >= 60 ? Colors.orange : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: pctColor.withOpacity(0.1),
              child: Text(
                student.firstName.isNotEmpty ? student.firstName[0].toUpperCase() : '?',
                style: TextStyle(color: pctColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.fullName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('${student.rollNumber} • Year ${student.year}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(pctColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.present} / ${summary.total} classes attended',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: pctColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${pct.toStringAsFixed(1)}%',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MARKS TAB
  // ============================================================

  Widget _buildMarksTab() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // ✅ Course dropdown from DB
              Row(
                children: [
                  const Icon(Icons.book, color: Color(0xFF3B82F6), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _courses.isEmpty
                        ? const Text('No courses linked — contact admin',
                        style: TextStyle(color: Colors.orange))
                        : DropdownButtonHideUnderline(
                      child: DropdownButton<CourseItem>(
                        value: _selectedMarkCourse,
                        hint: const Text('Select Course'),
                        isExpanded: true,
                        items: _courses.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(c.displayName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedMarkCourse = val);
                          _loadExistingMarks();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 12),
              Row(
                children: [
                  const Text('Exam Type:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Internal'),
                    selected: _selectedExamType == 'internal',
                    onSelected: (_) {
                      setState(() => _selectedExamType = 'internal');
                      _loadExistingMarks();
                    },
                    selectedColor: const Color(0xFF3B82F6),
                    labelStyle: TextStyle(
                      color: _selectedExamType == 'internal' ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('External'),
                    selected: _selectedExamType == 'external',
                    onSelected: (_) {
                      setState(() => _selectedExamType = 'external');
                      _loadExistingMarks();
                    },
                    selectedColor: const Color(0xFF3B82F6),
                    labelStyle: TextStyle(
                      color: _selectedExamType == 'external' ? Colors.white : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[100],
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('Student', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 1, child: Text('Roll No.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              SizedBox(width: 8),
              SizedBox(width: 80, child: Text('Marks /100', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
            ],
          ),
        ),

        Expanded(
          child: _students.isEmpty
              ? Center(
            child: Text('No students found.',
                style: TextStyle(color: Colors.grey[500])),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: _students.length,
            itemBuilder: (context, index) => _buildMarkRow(_students[index]),
          ),
        ),

        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSavingMarks ? null : _saveMarks,
              icon: _isSavingMarks
                  ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_isSavingMarks ? 'Saving...' : 'Save All Marks'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarkRow(DeptStudent student) {
    final controller = _markControllers[student.id] ?? TextEditingController();
    final marksText = controller.text;
    final marks = int.tryParse(marksText);
    Color? gradeColor;
    String grade = '';
    if (marks != null) {
      if (marks >= 90) { grade = 'A+'; gradeColor = Colors.green.shade700; }
      else if (marks >= 80) { grade = 'A';  gradeColor = Colors.green; }
      else if (marks >= 70) { grade = 'B+'; gradeColor = Colors.blue; }
      else if (marks >= 60) { grade = 'B';  gradeColor = Colors.blue.shade300; }
      else if (marks >= 50) { grade = 'C';  gradeColor = Colors.orange; }
      else { grade = 'F'; gradeColor = Colors.red; }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(student.fullName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 1,
              child: Text(student.rollNumber,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '0-100',
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 28,
              child: grade.isNotEmpty
                  ? Text(grade,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: gradeColor),
                  textAlign: TextAlign.center)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}