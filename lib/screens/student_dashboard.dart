// pubspec.yaml dependencies needed:
// flutter:
//   sdk: flutter
// supabase_flutter: ^2.3.4
// fl_chart: ^0.66.2
// file_picker: ^6.1.1
// percent_indicator: ^4.2.3
// cached_network_image: ^3.3.1
// intl: ^0.19.0

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'dart:io';

// Initialize Supabase in main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(AchivoApp());
}

class AchivoApp extends MaterialApp {
  AchivoApp({Key? key}) : super(
    key: key,
    title: 'Achivo - Student Dashboard',
    theme: ThemeData(
      primarySwatch: Colors.purple,
      fontFamily: 'Inter',
    ),
    home: StudentDashboard(),
  );
}

// Models
class Student {
  final String id;
  final String name;
  final String email;
  final String course;
  final int year;
  final double currentGpa;
  final double attendancePercentage;
  final int creditsCompleted;
  final int totalCredits;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.course,
    required this.year,
    required this.currentGpa,
    required this.attendancePercentage,
    required this.creditsCompleted,
    required this.totalCredits,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      course: json['course'] ?? '',
      year: json['year'] ?? 0,
      currentGpa: (json['current_gpa'] ?? 0.0).toDouble(),
      attendancePercentage: (json['attendance_percentage'] ?? 0.0).toDouble(),
      creditsCompleted: json['credits_completed'] ?? 0,
      totalCredits: json['total_credits'] ?? 0,
    );
  }
}

class Certificate {
  final String id;
  final String title;
  final String description;
  final String category;
  final String fileName;
  final DateTime uploadDate;
  final String status;
  final String? hodComments;
  final DateTime? approvedDate;
  final int? points;

  Certificate({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.fileName,
    required this.uploadDate,
    required this.status,
    this.hodComments,
    this.approvedDate,
    this.points,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      fileName: json['file_name'] ?? '',
      uploadDate: DateTime.parse(json['upload_date']),
      status: json['status'] ?? 'pending',
      hodComments: json['hod_comments'],
      approvedDate: json['approved_date'] != null
          ? DateTime.parse(json['approved_date'])
          : null,
      points: json['points'],
    );
  }
}

class Grade {
  final String subject;
  final String grade;
  final double percentage;
  final int credits;

  Grade({
    required this.subject,
    required this.grade,
    required this.percentage,
    required this.credits,
  });
}

// Supabase Service
class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Student Operations
  static Future<Student?> getCurrentStudent() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('students')
          .select()
          .eq('user_id', user.id)
          .single();

      return Student.fromJson(response);
    } catch (e) {
      print('Error fetching student: $e');
      return null;
    }
  }

  // Certificate Operations
  static Future<List<Certificate>> getCertificates(String studentId) async {
    try {
      final response = await _client
          .from('certificates')
          .select()
          .eq('student_id', studentId)
          .order('upload_date', ascending: false);

      return (response as List)
          .map((cert) => Certificate.fromJson(cert))
          .toList();
    } catch (e) {
      print('Error fetching certificates: $e');
      return [];
    }
  }

  static Future<bool> uploadCertificate({
    required String studentId,
    required String title,
    required String description,
    required String category,
    required File file,
  }) async {
    try {
      // Upload file to Supabase Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      await _client.storage
          .from('certificates')
          .upload('$studentId/$fileName', file);

      // Insert certificate record
      await _client.from('certificates').insert({
        'student_id': studentId,
        'title': title,
        'description': description,
        'category': category,
        'file_name': fileName,
        'upload_date': DateTime.now().toIso8601String(),
        'status': 'pending',
      });

      return true;
    } catch (e) {
      print('Error uploading certificate: $e');
      return false;
    }
  }

  // Academic Performance
  static Future<List<Grade>> getCurrentGrades(String studentId) async {
    try {
      final response = await _client
          .from('grades')
          .select()
          .eq('student_id', studentId)
          .eq('semester', 'current');

      return (response as List).map((grade) => Grade(
        subject: grade['subject'],
        grade: grade['grade'],
        percentage: grade['percentage'].toDouble(),
        credits: grade['credits'],
      )).toList();
    } catch (e) {
      print('Error fetching grades: $e');
      return [];
    }
  }

  // Attendance
  static Future<Map<String, double>> getAttendanceData(String studentId) async {
    try {
      final response = await _client
          .from('attendance')
          .select()
          .eq('student_id', studentId);

      double present = 0, absent = 0, late = 0;
      for (var record in response) {
        switch (record['status']) {
          case 'present':
            present++;
            break;
          case 'absent':
            absent++;
            break;
          case 'late':
            late++;
            break;
        }
      }

      double total = present + absent + late;
      return {
        'present': total > 0 ? (present / total) * 100 : 0,
        'absent': total > 0 ? (absent / total) * 100 : 0,
        'late': total > 0 ? (late / total) * 100 : 0,
      };
    } catch (e) {
      print('Error fetching attendance: $e');
      return {'present': 0, 'absent': 0, 'late': 0};
    }
  }
}

// Replace your entire StudentDashboard class with this fixed version
class StudentDashboard extends StatefulWidget {
  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  Student? _currentStudent;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final student = await SupabaseService.getCurrentStudent();
    setState(() {
      _currentStudent = student;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(),
      // Remove all SafeArea and padding wrappers from body
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achivo Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [Colors.purple, Colors.blue],
                ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
            ),
          ),
          Text(
            _getPageTitle(),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.normal,
            ),
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
                    _currentStudent?.name ?? 'Student',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${_currentStudent?.course ?? ''} • Year ${_currentStudent?.year ?? ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: Colors.purple,
                child: Text(
                  _currentStudent?.name.substring(0, 1).toUpperCase() ?? 'S',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
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
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.transparent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Achivo Portal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Academic Dashboard',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildDrawerItem(icon: Icons.dashboard, title: 'Overview', index: 0),
            _buildDrawerItem(icon: Icons.book, title: 'Academic Performance', index: 1),
            _buildDrawerItem(icon: Icons.calendar_today, title: 'Attendance', index: 2),
            _buildDrawerItem(icon: Icons.emoji_events, title: 'Credit Activities', index: 3),
            _buildDrawerItem(icon: Icons.groups, title: 'Extra-Curricular', index: 4),
            _buildDrawerItem(icon: Icons.work, title: 'Internships & Seminars', index: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white24 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  // This is the key fix - clean body without extra wrappers
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return OverviewPage(student: _currentStudent);
      case 1:
        return AcademicPerformancePage(studentId: _currentStudent?.id ?? '');
      case 2:
        return AttendancePage(studentId: _currentStudent?.id ?? '');
      case 3:
        return CreditActivitiesPage(studentId: _currentStudent?.id ?? '');
      case 4:
        return ExtraCurricularPage(studentId: _currentStudent?.id ?? '');
      case 5:
        return InternshipsPage(studentId: _currentStudent?.id ?? '');
      default:
        return OverviewPage(student: _currentStudent);
    }
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0: return 'Welcome to your student portal';
      case 1: return 'Academic Performance';
      case 2: return 'Attendance Tracking';
      case 3: return 'Credit Activities';
      case 4: return 'Extra-Curricular Activities';
      case 5: return 'Internships & Seminars';
      default: return 'Student Dashboard';
    }
  }
}

// Replace your OverviewPage class with this completely fixed version
class OverviewPage extends StatelessWidget {
  final Student? student;

  const OverviewPage({Key? key, this.student}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 24),
          _buildStatsGrid(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 100), // Extra space for safe scrolling
        ],
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
            'Welcome back, ${student?.name ?? 'Student'}! 🎓',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Here's an overview of your academic journey",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        // First row of cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Current GPA',
                value: student?.currentGpa.toString() ?? '0.0',
                subtitle: '+0.1 from last semester',
                color: Colors.purple,
                icon: Icons.book,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Attendance',
                value: '${student?.attendancePercentage.toInt() ?? 0}%',
                subtitle: 'Above average',
                color: Colors.blue,
                icon: Icons.calendar_today,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Second row of cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Credits',
                value: '${student?.creditsCompleted ?? 0}/${student?.totalCredits ?? 0}',
                subtitle: '${((student?.creditsCompleted ?? 0) / (student?.totalCredits ?? 1) * 100).toInt()}% completed',
                color: Colors.green,
                icon: Icons.emoji_events,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Active Clubs',
                value: '3',
                subtitle: '1 leadership role',
                color: Colors.orange,
                icon: Icons.groups,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      height: 140, // Fixed height to prevent overflow
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Quick Actions ⚡',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Replace GridView with Column and Rows
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard('View Grades', Icons.book, Colors.purple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard('Mark Attendance', Icons.calendar_today, Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard('Join Event', Icons.groups, Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard('Apply Internship', Icons.work, Colors.cyan),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color) {
    return Container(
      height: 80, // Fixed height
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
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Academic Performance Page
class AcademicPerformancePage extends StatefulWidget {
  final String studentId;

  const AcademicPerformancePage({Key? key, required this.studentId}) : super(key: key);

  @override
  _AcademicPerformancePageState createState() => _AcademicPerformancePageState();
}

class _AcademicPerformancePageState extends State<AcademicPerformancePage> {
  List<Grade> _grades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    final grades = await SupabaseService.getCurrentGrades(widget.studentId);
    setState(() {
      _grades = grades;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            _buildGradesList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.blue],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Academic Performance 📊',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Track your academic progress and performance metrics',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradesList() {
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Semester Grades',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _grades.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final grade = _grades[index];
              return _buildGradeCard(grade);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGradeCard(Grade grade) {
    Color gradeColor = _getGradeColor(grade.grade);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                grade.subject,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: gradeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      grade.grade,
                      style: TextStyle(
                        color: gradeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${grade.credits} credits',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearPercentIndicator(
                  animation: true,
                  lineHeight: 8.0,
                  animationDuration: 1000,
                  percent: grade.percentage / 100,
                  backgroundColor: Colors.grey[200]!,
                  progressColor: gradeColor,
                  barRadius: const Radius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${grade.percentage.toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    if (grade.startsWith('A')) return Colors.green;
    if (grade.startsWith('B')) return Colors.blue;
    if (grade.startsWith('C')) return Colors.orange;
    return Colors.red;
  }
}

// Certificate Upload Page
class CertificateUploadPage extends StatefulWidget {
  final String studentId;
  final String category;

  const CertificateUploadPage({
    Key? key,
    required this.studentId,
    required this.category,
  }) : super(key: key);

  @override
  _CertificateUploadPageState createState() => _CertificateUploadPageState();
}

class _CertificateUploadPageState extends State<CertificateUploadPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = '';
  File? _selectedFile;
  bool _isUploading = false;
  List<Certificate> _certificates = [];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category;
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    final certificates = await SupabaseService.getCertificates(widget.studentId);
    setState(() {
      _certificates = certificates;
    });
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadCertificate() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select a file'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    final success = await SupabaseService.uploadCertificate(
      studentId: widget.studentId,
      title: _titleController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      file: _selectedFile!,
    );

    setState(() {
      _isUploading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Certificate submitted for HOD approval!'),
          backgroundColor: Colors.green,
        ),
      );
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedFile = null;
      });
      _loadCertificates(); // Reload certificates
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_selectedCategory} Certificates'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUploadForm(),
            const SizedBox(height: 24),
            _buildCertificatesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadForm() {
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload New Certificate',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Certificate Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.check_circle : Icons.upload_file,
                        color: _selectedFile != null ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFile != null
                              ? _selectedFile!.path.split('/').last
                              : 'No file selected',
                          style: TextStyle(
                            color: _selectedFile != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _pickFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Browse'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _uploadCertificate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit for Approval'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificatesList() {
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Certificates',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_certificates.isEmpty)
            const Center(
              child: Text(
                'No certificates uploaded yet',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _certificates.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final certificate = _certificates[index];
                return _buildCertificateCard(certificate);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(Certificate certificate) {
    Color statusColor = _getStatusColor(certificate.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  certificate.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  certificate.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            certificate.description,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Uploaded: ${DateFormat('MMM dd, yyyy').format(certificate.uploadDate)}',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
          if (certificate.hodComments != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HOD Comments:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    certificate.hodComments!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          if (certificate.points != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${certificate.points} points awarded',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }
}

// Attendance Page
class AttendancePage extends StatefulWidget {
  final String studentId;

  const AttendancePage({Key? key, required this.studentId}) : super(key: key);

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  Map<String, double> _attendanceData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    final data = await SupabaseService.getAttendanceData(widget.studentId);
    setState(() {
      _attendanceData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            _buildAttendanceChart(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.cyan],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Tracking 📅',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Monitor your class attendance and punctuality',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAttendanceCard(
                'Present',
                _attendanceData['present']?.toInt() ?? 0,
                Colors.green,
                Icons.check_circle,
              ),
              _buildAttendanceCard(
                'Late',
                _attendanceData['late']?.toInt() ?? 0,
                Colors.orange,
                Icons.access_time,
              ),
              _buildAttendanceCard(
                'Absent',
                _attendanceData['absent']?.toInt() ?? 0,
                Colors.red,
                Icons.cancel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(String title, int percentage, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// Credit Activities Page
class CreditActivitiesPage extends StatelessWidget {
  final String studentId;

  const CreditActivitiesPage({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildCategoryGrid(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.pink],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Credit Activities 🏆',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Upload certificates and earn credit points',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final categories = [
      {'title': 'Technical Skills', 'icon': Icons.computer, 'color': Colors.blue},
      {'title': 'Leadership', 'icon': Icons.star, 'color': Colors.amber},
      {'title': 'Sports & Fitness', 'icon': Icons.sports, 'color': Colors.green},
      {'title': 'Arts & Culture', 'icon': Icons.palette, 'color': Colors.purple},
      {'title': 'Community Service', 'icon': Icons.volunteer_activism, 'color': Colors.red},
      {'title': 'Academic Excellence', 'icon': Icons.school, 'color': Colors.indigo},
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: categories.map((category) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CertificateUploadPage(
                  studentId: studentId,
                  category: category['title'] as String,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (category['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    color: category['color'] as Color,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  category['title'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Extra-Curricular Page
class ExtraCurricularPage extends StatelessWidget {
  final String studentId;

  const ExtraCurricularPage({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildActivitiesList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.teal],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Extra-Curricular Activities 🎭',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Explore and join various clubs and activities',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesList() {
    final activities = [
      {'name': 'Drama Club', 'members': 45, 'status': 'Joined'},
      {'name': 'Photography Society', 'members': 32, 'status': 'Joined'},
      {'name': 'Debate Team', 'members': 28, 'status': 'Available'},
      {'name': 'Music Band', 'members': 15, 'status': 'Available'},
      {'name': 'Art & Craft Club', 'members': 38, 'status': 'Available'},
    ];

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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Activities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _buildActivityCard(activity);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    bool isJoined = activity['status'] == 'Joined';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${activity['members']} members',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isJoined ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isJoined ? 'Joined' : 'Join',
              style: TextStyle(
                color: isJoined ? Colors.green : Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Internships Page
class InternshipsPage extends StatelessWidget {
  final String studentId;

  const InternshipsPage({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildOpportunitiesList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.cyan, Colors.blue],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Internships & Seminars 💼',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Explore career opportunities and skill development',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunitiesList() {
    final opportunities = [
      {
        'title': 'Software Development Internship',
        'company': 'Tech Corp',
        'duration': '3 months',
        'type': 'Internship',
        'status': 'Open'
      },
      {
        'title': 'AI & Machine Learning Seminar',
        'company': 'University',
        'duration': '2 days',
        'type': 'Seminar',
        'status': 'Registered'
      },
      {
        'title': 'Web Development Bootcamp',
        'company': 'Code Academy',
        'duration': '1 week',
        'type': 'Seminar',
        'status': 'Open'
      },
      {
        'title': 'Data Science Internship',
        'company': 'Analytics Inc',
        'duration': '6 months',
        'type': 'Internship',
        'status': 'Applied'
      },
    ];

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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Opportunities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: opportunities.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final opportunity = opportunities[index];
              return _buildOpportunityCard(opportunity);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunityCard(Map<String, dynamic> opportunity) {
    Color statusColor = _getStatusColor(opportunity['status']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  opportunity['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  opportunity['status'],
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.business, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                opportunity['company'],
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                opportunity['duration'],
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: opportunity['type'] == 'Internship'
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              opportunity['type'],
              style: TextStyle(
                color: opportunity['type'] == 'Internship' ? Colors.blue : Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.green;
      case 'applied':
        return Colors.orange;
      case 'registered':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}