import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// Initialize Supabase client
final supabase = Supabase.instance.client;

// Data Models
class Student {
  final String id;
  final String name;
  final String rollNumber;
  final String year;
  final String branch;
  final String email;
  final String phone;
  final String? parentName;
  final String? parentPhone;
  final DateTime createdAt;

  Student({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.year,
    required this.branch,
    required this.email,
    required this.phone,
    this.parentName,
    this.parentPhone,
    required this.createdAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      rollNumber: json['roll_number'],
      year: json['year'],
      branch: json['branch'],
      email: json['email'],
      phone: json['phone'],
      parentName: json['parent_name'],
      parentPhone: json['parent_phone'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'roll_number': rollNumber,
      'year': year,
      'branch': branch,
      'email': email,
      'phone': phone,
      'parent_name': parentName,
      'parent_phone': parentPhone,
    };
  }
}

class AttendanceRecord {
  final String id;
  final String studentId;
  final DateTime date;
  final bool present;
  final String? subject;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.date,
    required this.present,
    this.subject,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      studentId: json['student_id'],
      date: DateTime.parse(json['date']),
      present: json['present'],
      subject: json['subject'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'date': date.toIso8601String().split('T')[0],
      'present': present,
      'subject': subject,
    };
  }
}

class Mark {
  final String id;
  final String studentId;
  final String subjectId;
  final int marks;
  final int maxMarks;
  final String examType;
  final DateTime createdAt;

  Mark({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.marks,
    required this.maxMarks,
    required this.examType,
    required this.createdAt,
  });

  factory Mark.fromJson(Map<String, dynamic> json) {
    return Mark(
      id: json['id'],
      studentId: json['student_id'],
      subjectId: json['subject_id'],
      marks: json['marks'],
      maxMarks: json['max_marks'],
      examType: json['exam_type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'subject_id': subjectId,
      'marks': marks,
      'max_marks': maxMarks,
      'exam_type': examType,
    };
  }
}

class Subject {
  final String id;
  final String name;
  final int maxMarks;
  final String branch;
  final String year;

  Subject({
    required this.id,
    required this.name,
    required this.maxMarks,
    required this.branch,
    required this.year,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'],
      maxMarks: json['max_marks'],
      branch: json['branch'],
      year: json['year'],
    );
  }
}

// Main Faculty Dashboard App
class FacultyDashboardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Faculty Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF3B82F6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: FacultyDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FacultyDashboard extends StatefulWidget {
  @override
  _FacultyDashboardState createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Student> _students = [];
  List<AttendanceRecord> _attendanceRecords = [];
  List<Mark> _marks = [];
  List<Subject> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _loadStudents(),
        _loadSubjects(),
        _loadAttendance(),
        _loadMarks(),
      ]);
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudents() async {
    final response = await supabase.from('students').select();
    setState(() {
      _students =
          (response as List).map((json) => Student.fromJson(json)).toList();
    });
  }

  Future<void> _loadSubjects() async {
    final response = await supabase.from('subjects').select();
    setState(() {
      _subjects =
          (response as List).map((json) => Subject.fromJson(json)).toList();
    });
  }

  Future<void> _loadAttendance() async {
    final response = await supabase.from('attendance').select();
    setState(() {
      _attendanceRecords = (response as List)
          .map((json) => AttendanceRecord.fromJson(json))
          .toList();
    });
  }

  Future<void> _loadMarks() async {
    final response = await supabase.from('marks').select();
    setState(() {
      _marks = (response as List).map((json) => Mark.fromJson(json)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.school, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
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
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStudentDialog(),
        icon: Icon(Icons.person_add),
        label: Text('Add Student'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  Widget _buildDrawer() {
    final menuItems = [
      {'icon': Icons.dashboard, 'title': 'Dashboard', 'index': 0},
      {'icon': Icons.people, 'title': 'Attendance', 'index': 1},
      {'icon': Icons.history, 'title': 'Attendance History', 'index': 2},
      {'icon': Icons.grade, 'title': 'Marksheet', 'index': 3},
    ];

    return Drawer(
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.school, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Faculty Portal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(8),
              children: menuItems.map((item) {
                final isSelected = _selectedIndex == item['index'];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFF3B82F6) : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(
                      item['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                    title: Text(
                      item['title'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[800],
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedIndex = item['index'] as int;
                      });
                      Navigator.pop(context);
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
      case 0:
        return _buildDashboard();
      case 1:
        return _buildAttendance();
      case 2:
        return _buildAttendanceHistory();
      case 3:
        return _buildMarksheet();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final today = DateTime.now();
    final todayAttendance = _attendanceRecords
        .where((record) =>
            record.date.day == today.day &&
            record.date.month == today.month &&
            record.date.year == today.year)
        .toList();

    final presentToday =
        todayAttendance.where((record) => record.present).length;
    final attendanceRate = todayAttendance.isNotEmpty
        ? (presentToday / todayAttendance.length * 100).round()
        : 0;

    final recentActivities = [
      'Attendance marked for CS101 - 2 hours ago',
      'Grades updated for Database Systems - 4 hours ago',
      'New student enrolled: Sarah Wilson - 1 day ago',
      'Assignment submitted by 45 students - 2 days ago',
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Faculty Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          SizedBox(height: 24),

          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatsCard(
                'Total Students',
                '${_students.length}',
                '+12 this month',
                Icons.people,
                Color(0xFF3B82F6),
              ),
              _buildStatsCard(
                "Today's Attendance",
                '$attendanceRate%',
                '+5% from yesterday',
                Icons.calendar_today,
                Colors.green,
              ),
              _buildStatsCard(
                'Active Courses',
                '${_subjects.length}',
                '2 new this semester',
                Icons.book,
                Colors.purple,
              ),
              _buildStatsCard(
                'Average Grade',
                '85.4%',
                '+2.1% this term',
                Icons.trending_up,
                Colors.orange,
              ),
            ],
          ),

          SizedBox(height: 32),

          // Recent Activities
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Recent Activities',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ...recentActivities.map((activity) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(child: Text(activity)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
      String title, String value, String change, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 20, color: color),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              change,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendance() {
    final today = DateTime.now();
    final todayDate = DateFormat('yyyy-MM-dd').format(today);
    final todayAttendance = _attendanceRecords
        .where((record) =>
            DateFormat('yyyy-MM-dd').format(record.date) == todayDate)
        .toList();

    final Map<String, bool> attendanceStatus = {};
    for (var record in todayAttendance) {
      attendanceStatus[record.studentId] = record.present;
    }

    final presentCount =
        attendanceStatus.values.where((present) => present).length;
    final absentCount = _students.length - presentCount;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Attendance',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Track and manage daily attendance',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16),
                    SizedBox(width: 8),
                    Text(DateFormat('dd-MM-yyyy').format(today)),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Attendance Stats
          Row(
            children: [
              Expanded(
                child: _buildAttendanceStatCard(
                  'Total Students',
                  '${_students.length}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildAttendanceStatCard(
                  'Present',
                  '$presentCount',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildAttendanceStatCard(
                  'Absent',
                  '$absentCount',
                  Icons.cancel,
                  Colors.red,
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Attendance List
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Record - ${DateFormat('dd-MM-yyyy').format(today)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final isPresent = attendanceStatus[student.id] ?? false;

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Roll: ${student.rollNumber} | ${student.branch}',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      _markAttendance(student.id, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isPresent
                                        ? Colors.green
                                        : Colors.grey[200],
                                    foregroundColor: isPresent
                                        ? Colors.white
                                        : Colors.grey[600],
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    minimumSize: Size(0, 32),
                                  ),
                                  child: Text('Present',
                                      style: TextStyle(fontSize: 12)),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () =>
                                      _markAttendance(student.id, false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: !isPresent &&
                                            attendanceStatus
                                                .containsKey(student.id)
                                        ? Colors.red
                                        : Colors.grey[200],
                                    foregroundColor: !isPresent &&
                                            attendanceStatus
                                                .containsKey(student.id)
                                        ? Colors.white
                                        : Colors.grey[600],
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    minimumSize: Size(0, 32),
                                  ),
                                  child: Text('Absent',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceHistory() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance History',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'View and analyze historical attendance patterns',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _exportAttendance(),
                icon: Icon(Icons.download, size: 16),
                label: Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Summary Stats
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2,
            children: [
              _buildHistoryStatCard(
                'Total Classes',
                '${_attendanceRecords.length}',
                Icons.calendar_today,
                Colors.blue,
              ),
              _buildHistoryStatCard(
                'Overall Rate',
                '${_calculateOverallAttendanceRate()}%',
                Icons.trending_up,
                Colors.green,
              ),
            ],
          ),

          SizedBox(height: 24),

          // Student-wise Attendance Summary
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student-wise Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final studentAttendance = _attendanceRecords
                          .where(
                            (record) => record.studentId == student.id,
                          )
                          .toList();

                      final totalClasses = studentAttendance.length;
                      final presentClasses = studentAttendance
                          .where((record) => record.present)
                          .length;
                      final attendanceRate = totalClasses > 0
                          ? (presentClasses / totalClasses * 100).round()
                          : 0;

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${student.rollNumber} | ${student.branch}',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  'Present: $presentClasses',
                                  style: TextStyle(
                                      color: Colors.green, fontSize: 12),
                                ),
                                Text(
                                  'Absent: ${totalClasses - presentClasses}',
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 12),
                                ),
                              ],
                            ),
                            SizedBox(width: 16),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getAttendanceRateColor(attendanceRate),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$attendanceRate%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarksheet() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Internal Marksheet',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Manage student marks and grades',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              DropdownButton<String>(
                value: 'midterm',
                items: [
                  DropdownMenuItem(
                      value: 'midterm', child: Text('Midterm Exam')),
                  DropdownMenuItem(value: 'final', child: Text('Final Exam')),
                  DropdownMenuItem(
                      value: 'assignment', child: Text('Assignment')),
                  DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                ],
                onChanged: (value) {
                  // Handle exam type change
                },
              ),
            ],
          ),

          SizedBox(height: 24),

          // Marksheet Stats
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildMarksheetStatCard(
                'Total Students',
                '${_students.length}',
                Icons.people,
                Colors.blue,
              ),
              _buildMarksheetStatCard(
                'Class Average',
                '${_calculateClassAverage()}%',
                Icons.trending_up,
                Colors.green,
              ),
              _buildMarksheetStatCard(
                'Highest Score',
                '${_getHighestScore()}%',
                Icons.star,
                Colors.orange,
              ),
              _buildMarksheetStatCard(
                'Subjects',
                '${_subjects.length}',
                Icons.book,
                Colors.purple,
              ),
            ],
          ),

          SizedBox(height: 24),

          // Marksheet Table
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marksheet - Midterm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('Student')),
                        ..._subjects.map((subject) => DataColumn(
                              label: Column(
                                children: [
                                  Text(subject.name),
                                  Text('/${subject.maxMarks}',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            )),
                        DataColumn(label: Text('Average')),
                        DataColumn(label: Text('Grade')),
                      ],
                      rows: _students.map((student) {
                        final studentMarks = _marks
                            .where((mark) =>
                                mark.studentId == student.id &&
                                mark.examType == 'midterm')
                            .toList();
                        final average =
                            _calculateStudentAverage(student.id, 'midterm');
                        final grade = _getGrade(average);

                        return DataRow(
                          cells: [
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(student.name),
                                  Text(student.rollNumber,
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                            ..._subjects.map((subject) {
                              final mark = studentMarks.firstWhere(
                                (m) => m.subjectId == subject.id,
                                orElse: () => Mark(
                                  id: '',
                                  studentId: student.id,
                                  subjectId: subject.id,
                                  marks: 0,
                                  maxMarks: subject.maxMarks,
                                  examType: 'midterm',
                                  createdAt: DateTime.now(),
                                ),
                              );

                              return DataCell(
                                GestureDetector(
                                  onTap: () => _showEditMarkDialog(
                                      student, subject, mark),
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.grey[50],
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '${mark.marks}/${subject.maxMarks}',
                                          style: TextStyle(
                                            color: _getMarkColor(
                                                mark.marks, subject.maxMarks),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          _getGrade((mark.marks /
                                                  subject.maxMarks *
                                                  100)
                                              .round()),
                                          style: TextStyle(fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                            DataCell(
                              Text(
                                '$average%',
                                style: TextStyle(
                                  color: _getMarkColor(average, 100),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getGradeColor(grade),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  grade,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarksheetStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Dialog for adding new student
  void _showAddStudentDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _rollNumberController = TextEditingController();
    final _emailController = TextEditingController();
    final _phoneController = TextEditingController();
    final _parentNameController = TextEditingController();
    final _parentPhoneController = TextEditingController();
    String _selectedYear = '1st Year';
    String _selectedBranch = 'Computer Science';

    final years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
    final branches = [
      'Computer Science',
      'Information Technology',
      'Electronics',
      'Mechanical',
      'Civil',
      'Electrical'
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.person_add, color: Color(0xFF3B82F6)),
                  SizedBox(width: 8),
                  Text('Add New Student'),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _rollNumberController,
                          decoration: InputDecoration(
                            labelText: 'Roll Number *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.numbers),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Roll number is required';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedYear,
                                decoration: InputDecoration(
                                  labelText: 'Year *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.school),
                                ),
                                items: years.map((year) {
                                  return DropdownMenuItem(
                                    value: year,
                                    child: Text(year),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedYear = value!;
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedBranch,
                                decoration: InputDecoration(
                                  labelText: 'Branch *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.account_tree),
                                ),
                                items: branches.map((branch) {
                                  return DropdownMenuItem(
                                    value: branch,
                                    child: Text(branch),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedBranch = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Address *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(value)) {
                              return 'Invalid email format';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Phone is required';
                            }
                            if (value.length != 10) {
                              return 'Phone must be 10 digits';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _parentNameController,
                          decoration: InputDecoration(
                            labelText: 'Parent/Guardian Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.family_restroom),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _parentPhoneController,
                          decoration: InputDecoration(
                            labelText: 'Parent/Guardian Phone',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.contact_phone),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => _addStudent(
                    _formKey,
                    _nameController.text,
                    _rollNumberController.text,
                    _selectedYear,
                    _selectedBranch,
                    _emailController.text,
                    _phoneController.text,
                    _parentNameController.text,
                    _parentPhoneController.text,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3B82F6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.save, size: 16),
                      SizedBox(width: 4),
                      Text('Add Student'),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Edit mark dialog
  void _showEditMarkDialog(Student student, Subject subject, Mark currentMark) {
    final _markController =
        TextEditingController(text: currentMark.marks.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Mark'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Student: ${student.name}'),
              Text('Subject: ${subject.name}'),
              SizedBox(height: 16),
              TextFormField(
                controller: _markController,
                decoration: InputDecoration(
                  labelText: 'Marks (out of ${subject.maxMarks})',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newMarks = int.tryParse(_markController.text) ?? 0;
                _updateMark(student.id, subject.id, newMarks, subject.maxMarks);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Database operations
  Future<void> _addStudent(
    GlobalKey<FormState> formKey,
    String name,
    String rollNumber,
    String year,
    String branch,
    String email,
    String phone,
    String parentName,
    String parentPhone,
  ) async {
    if (formKey.currentState!.validate()) {
      try {
        final newStudent = {
          'name': name,
          'roll_number': rollNumber,
          'year': year,
          'branch': branch,
          'email': email,
          'phone': phone,
          'parent_name': parentName.isEmpty ? null : parentName,
          'parent_phone': parentPhone.isEmpty ? null : parentPhone,
        };

        await supabase.from('students').insert(newStudent);
        await _loadStudents();
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Student added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding student: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAttendance(String studentId, bool present) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Check if attendance already exists for today
      final existing = await supabase
          .from('attendance')
          .select()
          .eq('student_id', studentId)
          .eq('date', today)
          .single();

      if (existing != null) {
        // Update existing record
        await supabase
            .from('attendance')
            .update({'present': present})
            .eq('student_id', studentId)
            .eq('date', today);
      } else {
        // Insert new record
        await supabase.from('attendance').insert({
          'student_id': studentId,
          'date': today,
          'present': present,
          'subject': 'General',
        });
      }

      await _loadAttendance();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance marked successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking attendance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateMark(
      String studentId, String subjectId, int marks, int maxMarks) async {
    try {
      // Check if mark already exists
      final existing = await supabase
          .from('marks')
          .select()
          .eq('student_id', studentId)
          .eq('subject_id', subjectId)
          .eq('exam_type', 'midterm')
          .maybeSingle();

      if (existing != null) {
        // Update existing mark
        await supabase
            .from('marks')
            .update({'marks': marks})
            .eq('student_id', studentId)
            .eq('subject_id', subjectId)
            .eq('exam_type', 'midterm');
      } else {
        // Insert new mark
        await supabase.from('marks').insert({
          'student_id': studentId,
          'subject_id': subjectId,
          'marks': marks,
          'max_marks': maxMarks,
          'exam_type': 'midterm',
        });
      }

      await _loadMarks();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mark updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating mark: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper methods
  int _calculateOverallAttendanceRate() {
    if (_attendanceRecords.isEmpty) return 0;
    final presentCount =
        _attendanceRecords.where((record) => record.present).length;
    return (presentCount / _attendanceRecords.length * 100).round();
  }

  Color _getAttendanceRateColor(int rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 80) return Colors.blue;
    if (rate >= 70) return Colors.orange;
    if (rate >= 60) return Colors.yellow[700]!;
    return Colors.red;
  }

  int _calculateClassAverage() {
    if (_students.isEmpty) return 0;
    int totalAverage = 0;
    for (var student in _students) {
      totalAverage += _calculateStudentAverage(student.id, 'midterm');
    }
    return (totalAverage / _students.length).round();
  }

  int _getHighestScore() {
    if (_students.isEmpty) return 0;
    int highest = 0;
    for (var student in _students) {
      final average = _calculateStudentAverage(student.id, 'midterm');
      if (average > highest) highest = average;
    }
    return highest;
  }

  int _calculateStudentAverage(String studentId, String examType) {
    final studentMarks = _marks
        .where(
          (mark) => mark.studentId == studentId && mark.examType == examType,
        )
        .toList();

    if (studentMarks.isEmpty) return 0;

    int total = 0;
    for (var mark in studentMarks) {
      total += (mark.marks / mark.maxMarks * 100).round();
    }

    return (total / studentMarks.length).round();
  }

  String _getGrade(int percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    return 'F';
  }

  Color _getMarkColor(int marks, int maxMarks) {
    final percentage = (marks / maxMarks * 100).round();
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.blue;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 60) return Colors.yellow[700]!;
    return Colors.red;
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return Colors.green;
      case 'B+':
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  void _exportAttendance() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Attendance export feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

// Main function to run the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'NEXT_PUBLIC_SUPABASE_URL', // Replace with your Supabase URL
    anonKey:
        'NEXT_PUBLIC_SUPABASE_ANON_KEY', // Replace with your Supabase anon key
  );

  runApp(FacultyDashboardApp());
}
