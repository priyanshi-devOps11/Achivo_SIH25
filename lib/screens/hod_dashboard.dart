import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; // Import for StreamSubscription

// Initialize Supabase (Keep the existing main and MyApp structure)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase - Replace with your actual credentials
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL', // Replace with your Supabase URL
    anonKey: 'YOUR_SUPABASE_ANON_KEY', // Replace with your Supabase anon key
  );

  runApp(MyApp());
}

// Global Supabase client accessor
SupabaseClient get supabase => Supabase.instance.client;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HOD Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          elevation: 2,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: HODDashboardMain(),
    );
  }
}

// Data Models (Keep as is)
// ... Faculty, Student, ApprovalRequest classes ...

// Data Models (Copy the existing Data Models here for completeness, or keep the file structure)
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
    // Check for potential Supabase JSON types in case of real-time update payloads
    final subjectsData = map['subjects'];
    List<String> subjectsList;
    if (subjectsData is List) {
      subjectsList = List<String>.from(subjectsData);
    } else if (subjectsData is String) {
      // Handle string representation if necessary, though list is expected
      subjectsList = [subjectsData];
    } else {
      subjectsList = [];
    }

    return Faculty(
      // Use map['id'].toString() for safety as id might be int or text
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      department: map['department'] ?? '',
      designation: map['designation'] ?? '',
      experience: map['experience'] ?? 0,
      subjects: subjectsList,
      joiningDate: map['joining_date'] ?? '',
      status: map['status'] ?? 'Active', // Default status for safety
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
      id: map['id']?.toString() ?? '',
      name: '${map['first_name'] ?? ''} ${map['last_name'] ?? ''}'.trim(), // Use combined name from DB schema
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      rollNumber: map['roll_number'] ?? '',
      year: map['year'] ?? '',
      semester: map['semester'] ?? 'N/A', // Add semester mapping if available, otherwise N/A
      cgpa: (map['cgpa'] ?? 0.0).toDouble(),
      address: map['address'] ?? 'N/A', // Assuming 'address' is available or use 'N/A'
      parentContact: map['parent_phone'] ?? '', // Using parent_phone from DB schema
      status: map['status'] ?? 'Active', // Status is not explicitly in students table, defaulting to 'Active'
      admissionDate: map['admission_date'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // Note: Supabase students table uses first_name, last_name
      // For simplicity in a dashboard view, we map back to the combined name property in the model.
      // If you needed to update, you would use 'first_name', 'last_name' etc.
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
  final String type; // Map to title for simplicity
  final String title;
  final String description;
  final String submittedDate;
  String status;
  final String urgency; // Not directly in activities, defaulting to 'Medium'
  final List<String>? documents; // Not directly in activities, defaulting to null

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
    // Mapping from 'activities' table and potentially joining 'students' for name
    return ApprovalRequest(
      id: map['id']?.toString() ?? '',
      studentId: map['student_id']?.toString() ?? '',
      studentName: map['students']?['first_name'] != null
          ? '${map['students']['first_name']} ${map['students']['last_name']}'
          : map['student_name'] ?? 'Unknown Student', // Fallback
      type: map['category'] ?? 'General', // Map activity.category to type
      title: map['title'] ?? 'N/A',
      description: map['description'] ?? '',
      submittedDate: map['created_at'] != null
          ? DateTime.parse(map['created_at']).toIso8601String().substring(0, 10)
          : 'N/A', // Use created_at as submitted_date
      status: map['status'] ?? 'Pending',
      urgency: 'Medium', // Default as urgency is not in the DB schema
      documents: [], // Default as documents is not in the DB schema
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


// HOD Dashboard Implementation - Real-Time Version
class HODDashboardMain extends StatefulWidget {
  const HODDashboardMain({super.key});

  @override
  State<HODDashboardMain> createState() => _HODDashboardMainState();
}

class _HODDashboardMainState extends State<HODDashboardMain>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Faculty> faculty = [];
  List<Student> students = [];
  List<ApprovalRequest> approvalRequests = [];
  bool isLoading = true;
  bool isRefreshing = false;

  final SupabaseClient supabase = Supabase.instance.client;

  // Real-time Subscriptions
  StreamSubscription<List<Map<String, dynamic>>>? _facultySubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _studentsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _requestsSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupRealTimeSubscriptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    // 1. **Dispose of Subscriptions**
    _facultySubscription?.cancel();
    _studentsSubscription?.cancel();
    _requestsSubscription?.cancel();
    super.dispose();
  }

  // New method to set up real-time
  Future<void> _setupRealTimeSubscriptions() async {
    setState(() => isLoading = true);

    // 2. Load Initial Data and then Subscribe to Changes
    // The .stream() method handles the initial data fetch and continuous updates.

    try {
      // --- Faculty Real-Time ---
      _facultySubscription = supabase
          .from('faculty')
          .stream(primaryKey: ['id'])
          .order('first_name', ascending: true)
          .listen((List<Map<String, dynamic>> data) {
        setState(() {
          faculty = data.map((d) => Faculty.fromMap(d)).toList();
        });
      });

      // --- Students Real-Time (Using a view/join for full name/info is best practice) ---
      // For simplicity, we are streaming the base table and relying on the model's mapping.
      _studentsSubscription = supabase
          .from('students')
          .stream(primaryKey: ['id'])
          .order('roll_number', ascending: true)
          .listen((List<Map<String, dynamic>> data) {
        setState(() {
          students = data.map((d) => Student.fromMap(d)).toList();
        });
      });

      // --- Approval Requests Real-Time (activities table) ---
      // Real-time view on activities. You'd typically use a complex join here.
      // For a simple real-time update on status, we'll stream the 'activities' table.
      // Note: Fetching student_name for ApprovalRequest will need a JOIN/RPC/View for a robust solution.
      _requestsSubscription = supabase
          .from('activities')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .listen((List<Map<String, dynamic>> data) {
        // Fetch student name separately or use a joined view in Supabase for a robust solution
        setState(() {
          approvalRequests = data.map((d) {
            // Temporary fix for student name: look up in the currently loaded students list
            final student = students.firstWhere(
                  (s) => s.id == d['student_id'],
              orElse: () => Student(
                  id: d['student_id'] ?? 'N/A',
                  name: 'Unknown',
                  email: '', phone: '', rollNumber: '', year: '', semester: '', cgpa: 0.0, address: '', parentContact: '', status: '', admissionDate: ''),
            );
            return ApprovalRequest.fromMap({
              ...d,
              'student_name': student.name
            });
          }).toList();
        });
      });

    } catch (e) {
      print('Error setting up Real-Time subscriptions: $e');
      _loadSampleData(); // Fallback to sample data on error
    } finally {
      // Initial loading is complete once the first data is received or an error occurred.
      // In a real app, you might wait for the first data event to set isLoading to false.
      // We set it here for simplicity and rely on the stream listener to rebuild the widget.
      setState(() => isLoading = false);
    }
  }

  // Fallback sample data functions (Keep as is)
  void _loadSampleData() {
    // ... (Your existing _getSampleFaculty, _getSampleStudents, _getSampleApprovalRequests calls)
  }

  List<Faculty> _getSampleFaculty() { /* ... existing sample data ... */
    return [
      Faculty(id: '1', name: 'Dr. Sarah Johnson', email: 'sarah.johnson@university.edu', phone: '+1 (555) 123-4567', department: 'Computer Science', designation: 'Professor', experience: 12, subjects: ['Data Structures', 'Algorithms', 'Machine Learning'], joiningDate: '2012-08-15', status: 'Active', qualification: 'Ph.D in Computer Science'),
      Faculty(id: '2', name: 'Prof. Michael Chen', email: 'michael.chen@university.edu', phone: '+1 (555) 234-5678', department: 'Computer Science', designation: 'Associate Professor', experience: 8, subjects: ['Database Systems', 'Web Development', 'Software Engineering'], joiningDate: '2016-01-20', status: 'Active', qualification: 'Ph.D in Information Technology'),
    ];
  }

  List<Student> _getSampleStudents() { /* ... existing sample data ... */
    return [
      Student(id: '1', name: 'Alex Thompson', email: 'alex.thompson@student.edu', phone: '+1 (555) 111-2222', rollNumber: 'CS2021001', year: '3rd Year', semester: '6th Semester', cgpa: 8.5, address: '123 University Street, College Town', parentContact: '+1 (555) 111-3333', status: 'Active', admissionDate: '2021-08-15'),
      Student(id: '2', name: 'Priya Sharma', email: 'priya.sharma@student.edu', phone: '+1 (555) 222-3333', rollNumber: 'CS2020015', year: '4th Year', semester: '8th Semester', cgpa: 9.2, address: '456 Campus Road, University City', parentContact: '+1 (555) 222-4444', status: 'Active', admissionDate: '2020-08-15'),
    ];
  }

  List<ApprovalRequest> _getSampleApprovalRequests() { /* ... existing sample data ... */
    return [
      ApprovalRequest(id: '1', studentId: '1', studentName: 'Alex Thompson', type: 'Leave Application', title: 'Medical Leave Request', description: 'Requesting 2 weeks medical leave...', submittedDate: '2024-09-05', status: 'Pending', urgency: 'High', documents: ['medical_certificate.pdf']),
      ApprovalRequest(id: '2', studentId: '2', studentName: 'Priya Sharma', type: 'Fee Waiver', title: 'Financial Assistance Request', description: 'Requesting fee waiver due to family financial difficulties.', submittedDate: '2024-09-10', status: 'Pending', urgency: 'Medium', documents: ['income_certificate.pdf']),
    ];
  }

  // Refresh data is still useful for a manual reload, but now the main load is stream-based.
  Future<void> _refreshData() async {
    setState(() => isRefreshing = true);
    // Cancel existing subscriptions and set them up again to force a fresh load/sync
    _facultySubscription?.cancel();
    _studentsSubscription?.cancel();
    _requestsSubscription?.cancel();
    await _setupRealTimeSubscriptions();
    setState(() => isRefreshing = false);
    _showSuccessSnackbar('Data refreshed successfully');
  }

  // Update Status method
  Future<void> _updateApprovalStatus(String requestId, String newStatus) async {
    try {
      // Update the 'activities' table
      await supabase.from('activities').update({
        'status': newStatus.toLowerCase(), // Ensure status matches DB check constraint
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', int.parse(requestId)); // ID is BIGSERIAL, so it's an integer in the DB

      // The real-time stream will automatically update the UI, so no manual setState is needed for the list.
      _showSuccessSnackbar('Request ${newStatus.toLowerCase()} successfully');
    } catch (e) {
      _showSuccessSnackbar('Error updating status: $e');
      print('Error updating approval status: $e');
    }
  }

  // Keep all other helper methods (_showSuccessSnackbar, getStatusColor, _buildStatCard, _buildSimpleCard, _buildApprovalCard)

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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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

  Widget _buildSimpleCard(String name, String subtitle, String status, IconData leadingIcon) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(leadingIcon, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: getStatusColor(status),
                  width: 1,
                ),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: getStatusColor(status),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard(ApprovalRequest request) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: getStatusColor(request.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: getStatusColor(request.status),
                      width: 1,
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
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Student: ${request.studentName}',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Type: ${request.type}',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
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
            if (request.status.toLowerCase() == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateApprovalStatus(request.id, 'Approved'),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateApprovalStatus(request.id, 'Rejected'),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
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


  @override
  Widget build(BuildContext context) {
    final activeStudents = students.where((s) => s.status.toLowerCase() == 'active').length;
    final pendingRequests = approvalRequests.where((r) => r.status.toLowerCase() == 'pending').length;

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('HOD Dashboard'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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

    // Main dashboard view (rest of the build method is unchanged)
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('HOD Dashboard'),
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
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Faculty'),
              Tab(icon: Icon(Icons.school), text: 'Students'),
              Tab(icon: Icon(Icons.assignment), text: 'Approvals'),
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
                      'Faculty',
                      faculty.length.toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Active Students',
                      activeStudents.toString(),
                      Icons.school,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Pending',
                      pendingRequests.toString(),
                      Icons.access_time,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Total Students',
                      students.length.toString(),
                      Icons.group,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                children: [
                  // Faculty Tab
                  faculty.isEmpty
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No faculty members found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: faculty.length,
                    itemBuilder: (context, index) {
                      final member = faculty[index];
                      return _buildSimpleCard(
                        member.name,
                        '${member.designation} - ${member.email}',
                        member.status,
                        Icons.person,
                      );
                    },
                  ),
                  // Students Tab
                  students.isEmpty
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No students found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return _buildSimpleCard(
                        student.name,
                        '${student.rollNumber} - CGPA: ${student.cgpa}',
                        student.status,
                        Icons.school,
                      );
                    },
                  ),
                  // Approvals Tab
                  approvalRequests.isEmpty
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No approval requests found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: approvalRequests.length,
                    itemBuilder: (context, index) {
                      return _buildApprovalCard(approvalRequests[index]);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper functions (defined outside the class for clarity)
Future<void> _handleSignOut(BuildContext context) async {
  try {
    await supabase.auth.signOut();
    if (context.mounted) {
      // Navigate to the sign-in screen if you have one defined at '/'
      Navigator.popUntil(context, (route) => route.isFirst);
      // For a proper implementation, you should navigate to a login screen.
      // Example: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }
}