import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Initialize Supabase
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase - Replace with your actual credentials
  await Supabase.initialize(
    url: 'NEXT_PUBLIC_SUPABASE_URL', // Replace with your Supabase URL
    anonKey:
        'NEXT_PUBLIC_SUPABASE_ANON_KEY', // Replace with your Supabase anon key
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HOD Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 2,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: HODDashboard(),
      routes: {
        '/auth': (context) => AuthScreen(),
      },
    );
  }
}

// Simple Auth Screen
class AuthScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HODDashboard()),
            );
          },
          child: Text('Go to HOD Dashboard'),
        ),
      ),
    );
  }
}

// Data Models
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

  factory Faculty.fromMap(Map<String, dynamic> map) {
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

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'department': department,
      'designation': designation,
      'experience': experience,
      'subjects': subjects,
      'joining_date': joiningDate,
      'status': status,
      'qualification': qualification,
    };
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

  factory Student.fromMap(Map<String, dynamic> map) {
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

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'roll_number': rollNumber,
      'year': year,
      'semester': semester,
      'cgpa': cgpa,
      'address': address,
      'parent_contact': parentContact,
      'status': status,
      'admission_date': admissionDate,
    };
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

  factory ApprovalRequest.fromMap(Map<String, dynamic> map) {
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

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'student_name': studentName,
      'type': type,
      'title': title,
      'description': description,
      'submitted_date': submittedDate,
      'status': status,
      'urgency': urgency,
      'documents': documents,
    };
  }
}

class HODDashboard extends StatefulWidget {
  const HODDashboard({Key? key}) : super(key: key);

  @override
  State<HODDashboard> createState() => _HODDashboardState();
}

class _HODDashboardState extends State<HODDashboard>
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      // Load Faculty with error handling
      final facultyResponse = await supabase
          .from('faculty')
          .select()
          .order('name', ascending: true);
      faculty = (facultyResponse as List)
          .map((data) => Faculty.fromMap(data))
          .toList();

      // Load Students with error handling
      final studentsResponse = await supabase
          .from('students')
          .select()
          .order('name', ascending: true);
      students = (studentsResponse as List)
          .map((data) => Student.fromMap(data))
          .toList();

      // Load Approval Requests with error handling
      final requestsResponse = await supabase
          .from('approval_requests')
          .select()
          .order('submitted_date', ascending: false);
      approvalRequests = (requestsResponse as List)
          .map((data) => ApprovalRequest.fromMap(data))
          .toList();
    } catch (e) {
      _showErrorSnackbar('Error loading data: ${e.toString()}');
      print('Error loading data: $e');
      // Load sample data as fallback
      _loadSampleData();
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _loadSampleData() {
    // Fallback sample data
    faculty = [
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
        subjects: [
          'Database Systems',
          'Web Development',
          'Software Engineering'
        ],
        joiningDate: '2016-01-20',
        status: 'Active',
        qualification: 'Ph.D in Information Technology',
      ),
    ];

    students = [
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

    approvalRequests = [
      ApprovalRequest(
        id: '1',
        studentId: '1',
        studentName: 'Alex Thompson',
        type: 'Leave Application',
        title: 'Medical Leave Request',
        description:
            'Requesting 2 weeks medical leave due to surgery. Medical certificate attached.',
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
      _showErrorSnackbar('Error updating request: ${e.toString()}');
      print('Error updating approval status: $e');
    }
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'on leave':
        return Colors.orange;
      case 'inactive':
        return Colors.red;
      case 'suspended':
        return Colors.red;
      case 'graduated':
        return Colors.blue;
      case 'dropped':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.account_circle,
                        size: 50,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Dr. John Smith',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Head of Department',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'hod@university.edu',
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
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Faculty Management',
                  onTap: () {
                    Navigator.pop(context);
                    _tabController.animateTo(0);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.school,
                  title: 'Student Records',
                  onTap: () {
                    Navigator.pop(context);
                    _tabController.animateTo(1);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.assignment,
                  title: 'Approval Requests',
                  onTap: () {
                    Navigator.pop(context);
                    _tabController.animateTo(2);
                  },
                ),
                const Divider(height: 32),
                _buildDrawerItem(
                  icon: Icons.analytics,
                  title: 'Analytics',
                  onTap: () => _showComingSoonDialog('Analytics'),
                ),
                _buildDrawerItem(
                  icon: Icons.calendar_today,
                  title: 'Academic Calendar',
                  onTap: () => _showComingSoonDialog('Academic Calendar'),
                ),
                _buildDrawerItem(
                  icon: Icons.report,
                  title: 'Reports',
                  onTap: () => _showComingSoonDialog('Reports'),
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () => _showComingSoonDialog('Settings'),
                ),
                _buildDrawerItem(
                  icon: Icons.help,
                  title: 'Help & Support',
                  onTap: () => _showComingSoonDialog('Help & Support'),
                ),
              ],
            ),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () => _showLogoutDialog(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _showComingSoonDialog(String feature) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Text('$feature Coming Soon'),
          ],
        ),
        content: Text(
            'The $feature feature is under development and will be available in the next update.'),
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
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                  context, '/auth', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String title, String currentValue,
      List<String> options, Function(String) onChanged) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          icon: const Icon(Icons.filter_list, size: 16, color: Colors.grey),
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          items: options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value == 'all' ? title : value,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacultyCard(Faculty member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  member.name.split(' ').map((n) => n[0]).join(''),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          member.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: getStatusColor(member.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: getStatusColor(member.status),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          member.status,
                          style: TextStyle(
                            color: getStatusColor(member.status),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member.designation,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.email, member.email),
                  const SizedBox(height: 6),
                  _buildInfoRow(Icons.phone, member.phone),
                  const SizedBox(height: 6),
                  _buildInfoRow(
                      Icons.work, '${member.experience} years experience'),
                  const SizedBox(height: 12),
                  Text(
                    'Subjects: ${member.subjects.join(', ')}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Student student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  student.name.split(' ').map((n) => n[0]).join(''),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          student.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              getStatusColor(student.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: getStatusColor(student.status),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          student.status,
                          style: TextStyle(
                            color: getStatusColor(student.status),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student.rollNumber,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.email, student.email),
                  const SizedBox(height: 6),
                  _buildInfoRow(
                      Icons.school, '${student.year} - ${student.semester}'),
                  const SizedBox(height: 6),
                  _buildInfoRow(Icons.grade, 'CGPA: ${student.cgpa}/10'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard(ApprovalRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
                      color: Colors.black87,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: getStatusColor(request.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: getStatusColor(request.status),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        request.status,
                        style: TextStyle(
                          color: getStatusColor(request.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            getUrgencyColor(request.urgency).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: getUrgencyColor(request.urgency),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        request.urgency,
                        style: TextStyle(
                          color: getUrgencyColor(request.urgency),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Student: ${request.studentName}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  'Type: ${request.type}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            if (request.status.toLowerCase() == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _updateApprovalStatus(request.id, 'Approved'),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _updateApprovalStatus(request.id, 'Rejected'),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(String hintText) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => setState(() => searchTerm = value),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeStudents =
        students.where((s) => s.status.toLowerCase() == 'active').length;
    final pendingRequests = approvalRequests
        .where((r) => r.status.toLowerCase() == 'pending')
        .length;

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
      drawer: _buildDrawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.grey.withOpacity(0.1),
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87, size: 24),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'HOD Dashboard',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Computer Science Department',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                      ),
                    )
                  : const Icon(Icons.refresh, color: Colors.black87),
              onPressed: isRefreshing ? null : _refreshData,
              tooltip: 'Refresh Data',
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: _showLogoutDialog,
              tooltip: 'Logout',
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: Column(
        children: [
          // Statistics Cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Faculty',
                    faculty.length.toString(),
                    Icons.people,
                    const Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Active Students',
                    activeStudents.toString(),
                    Icons.school,
                    const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Pending Requests',
                    pendingRequests.toString(),
                    Icons.access_time,
                    const Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Students',
                    students.length.toString(),
                    Icons.group,
                    const Color(0xFF9C27B0),
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1976D2),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF1976D2),
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  icon: Icon(Icons.people, size: 22),
                  text: 'Faculty',
                ),
                Tab(
                  icon: Icon(Icons.school, size: 22),
                  text: 'Students',
                ),
                Tab(
                  icon: Icon(Icons.assignment, size: 22),
                  text: 'Approvals',
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Faculty Tab
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSearchField(
                          'Search faculty by name, email, or subject...'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildFilterDropdown(
                            'All Status',
                            filterStatus,
                            ['all', 'Active', 'On Leave', 'Inactive'],
                            (value) => setState(() => filterStatus = value),
                          ),
                          const SizedBox(width: 12),
                          _buildFilterDropdown(
                            'All Designations',
                            filterDesignation,
                            [
                              'all',
                              'Professor',
                              'Associate Professor',
                              'Assistant Professor'
                            ],
                            (value) =>
                                setState(() => filterDesignation = value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: faculty.where((member) {
                            final matchesSearch = member.name
                                    .toLowerCase()
                                    .contains(searchTerm.toLowerCase()) ||
                                member.email
                                    .toLowerCase()
                                    .contains(searchTerm.toLowerCase()) ||
                                member.subjects.any((subject) => subject
                                    .toLowerCase()
                                    .contains(searchTerm.toLowerCase()));
                            final matchesStatus = filterStatus == 'all' ||
                                member.status.toLowerCase() ==
                                    filterStatus.toLowerCase();
                            final matchesDesignation =
                                filterDesignation == 'all' ||
                                    member.designation == filterDesignation;
                            return matchesSearch &&
                                matchesStatus &&
                                matchesDesignation;
                          }).length,
                          itemBuilder: (context, index) {
                            final filteredFaculty = faculty.where((member) {
                              final matchesSearch = member.name
                                      .toLowerCase()
                                      .contains(searchTerm.toLowerCase()) ||
                                  member.email
                                      .toLowerCase()
                                      .contains(searchTerm.toLowerCase()) ||
                                  member.subjects.any((subject) => subject
                                      .toLowerCase()
                                      .contains(searchTerm.toLowerCase()));
                              final matchesStatus = filterStatus == 'all' ||
                                  member.status.toLowerCase() ==
                                      filterStatus.toLowerCase();
                              final matchesDesignation =
                                  filterDesignation == 'all' ||
                                      member.designation == filterDesignation;
                              return matchesSearch &&
                                  matchesStatus &&
                                  matchesDesignation;
                            }).toList();
                            return _buildFacultyCard(filteredFaculty[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Students Tab
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSearchField(
                          'Search students by name, email, or roll number...'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildFilterDropdown(
                            'All Status',
                            filterStatus,
                            [
                              'all',
                              'Active',
                              'Suspended',
                              'Graduated',
                              'Dropped'
                            ],
                            (value) => setState(() => filterStatus = value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: students.where((student) {
                            final matchesSearch = student.name
                                    .toLowerCase()
                                    .contains(searchTerm.toLowerCase()) ||
                                student.email
                                    .toLowerCase()
                                    .contains(searchTerm.toLowerCase()) ||
                                student.rollNumber
                                    .toLowerCase()
                                    .contains(searchTerm.toLowerCase());
                            final matchesStatus = filterStatus == 'all' ||
                                student.status.toLowerCase() ==
                                    filterStatus.toLowerCase();
                            return matchesSearch && matchesStatus;
                          }).length,
                          itemBuilder: (context, index) {
                            final filteredStudents = students.where((student) {
                              final matchesSearch = student.name
                                      .toLowerCase()
                                      .contains(searchTerm.toLowerCase()) ||
                                  student.email
                                      .toLowerCase()
                                      .contains(searchTerm.toLowerCase()) ||
                                  student.rollNumber
                                      .toLowerCase()
                                      .contains(searchTerm.toLowerCase());
                              final matchesStatus = filterStatus == 'all' ||
                                  student.status.toLowerCase() ==
                                      filterStatus.toLowerCase();
                              return matchesSearch && matchesStatus;
                            }).toList();
                            return _buildStudentCard(filteredStudents[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Approval Requests Tab
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSearchField(
                          'Search requests by student name, title, or type...'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildFilterDropdown(
                            'All Status',
                            filterStatus,
                            ['all', 'Pending', 'Approved', 'Rejected'],
                            (value) => setState(() => filterStatus = value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: approvalRequests.where((request) {
                            final matchesSearch = request.studentName
                                    .toLowerCase()
                                    .contains(searchTerm.toLowerCase()) ||
                                request.title
                                    .toLowerCase()
                                    .contains(searchTerm.toLowerCase()) ||
                                request.type
                                    .toLowerCase()
                                    .contains(searchTerm.toLowerCase());
                            final matchesStatus = filterStatus == 'all' ||
                                request.status.toLowerCase() ==
                                    filterStatus.toLowerCase();
                            return matchesSearch && matchesStatus;
                          }).length,
                          itemBuilder: (context, index) {
                            final filteredRequests =
                                approvalRequests.where((request) {
                              final matchesSearch = request.studentName
                                      .toLowerCase()
                                      .contains(searchTerm.toLowerCase()) ||
                                  request.title
                                      .toLowerCase()
                                      .contains(searchTerm.toLowerCase()) ||
                                  request.type
                                      .toLowerCase()
                                      .contains(searchTerm.toLowerCase());
                              final matchesStatus = filterStatus == 'all' ||
                                  request.status.toLowerCase() ==
                                      filterStatus.toLowerCase();
                              return matchesSearch && matchesStatus;
                            }).toList();
                            return _buildApprovalCard(filteredRequests[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
