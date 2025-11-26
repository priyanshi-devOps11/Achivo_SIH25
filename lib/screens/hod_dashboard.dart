import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// Get Supabase client instance
SupabaseClient get supabase => Supabase.instance.client;

// ==============================
// DATA MODELS
// ==============================

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
    // Handle subjects array
    final subjectsData = map['subjects'];
    List<String> subjectsList = [];
    if (subjectsData is List) {
      subjectsList = List<String>.from(subjectsData);
    } else if (subjectsData is String) {
      subjectsList = [subjectsData];
    }

    // Build full name
    final firstName = map['first_name'] ?? '';
    final lastName = map['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    return Faculty(
      id: map['id']?.toString() ?? '',
      name: fullName.isNotEmpty ? fullName : 'Unknown',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      department: map['department_id']?.toString() ?? '',
      designation: map['designation'] ?? '',
      experience: map['experience_years'] ?? 0,
      subjects: subjectsList,
      joiningDate: map['joining_date'] ?? '',
      status: 'Active', // Default status
      qualification: map['qualification'] ?? '',
    );
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
    final firstName = map['first_name'] ?? '';
    final lastName = map['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    return Student(
      id: map['id']?.toString() ?? '',
      name: fullName.isNotEmpty ? fullName : 'Unknown',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      rollNumber: map['roll_number'] ?? '',
      year: map['year'] ?? '',
      semester: map['semester'] ?? 'N/A',
      cgpa: (map['cgpa'] ?? 0.0).toDouble(),
      address: map['address'] ?? 'N/A',
      parentContact: map['parent_phone'] ?? '',
      status: 'Active', // Default status
      admissionDate: map['admission_date'] ?? '',
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

  factory ApprovalRequest.fromMap(
      Map<String, dynamic> map, String studentName) {
    return ApprovalRequest(
      id: map['id']?.toString() ?? '',
      studentId: map['student_id']?.toString() ?? '',
      studentName: studentName,
      type: map['category'] ?? 'General',
      title: map['title'] ?? 'N/A',
      description: map['description'] ?? '',
      submittedDate: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          .toIso8601String()
          .substring(0, 10)
          : 'N/A',
      status: map['status'] ?? 'Pending',
      urgency: 'Medium', // Default urgency
      documents: [],
    );
  }
}

// ==============================
// MAIN HOD DASHBOARD
// ==============================

class HODDashboardMain extends StatefulWidget {
  const HODDashboardMain({super.key});

  @override
  State<HODDashboardMain> createState() => _HODDashboardMainState();
}

class _HODDashboardMainState extends State<HODDashboardMain>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Data lists
  List<Faculty> faculty = [];
  List<Student> students = [];
  List<ApprovalRequest> approvalRequests = [];

  // Loading states
  bool isLoading = true;
  bool isRefreshing = false;

  // Debug information
  String diagnosticMessage = '';

  // Student names map for activities
  Map<String, String> studentNamesMap = {};

  // Real-time subscriptions
  StreamSubscription<List<Map<String, dynamic>>>? _facultySubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _studentsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _requestsSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkAuthAndSetupData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _facultySubscription?.cancel();
    _studentsSubscription?.cancel();
    _requestsSubscription?.cancel();
    super.dispose();
  }

  // ==============================
  // AUTHENTICATION & DATA SETUP
  // ==============================

  Future<void> _checkAuthAndSetupData() async {
    setState(() => isLoading = true);

    try {
      // Check authentication
      final session = supabase.auth.currentSession;
      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() {
          diagnosticMessage = '⚠️ NOT AUTHENTICATED\n\n'
              'No user is logged in. Please sign in first.';
          isLoading = false;
        });
        return;
      }

      setState(() {
        diagnosticMessage = '✅ AUTHENTICATED\n'
            'User ID: ${user.id}\n'
            'Email: ${user.email}\n\n'
            'Loading data...';
      });

      // Test direct queries
      await _testDirectQueries();

      // Setup real-time subscriptions
      await _setupRealTimeSubscriptions();
    } catch (e) {
      setState(() {
        diagnosticMessage += '\n\n❌ ERROR:\n$e';
        isLoading = false;
      });
    }
  }

  // ==============================
  // TEST DIRECT QUERIES
  // ==============================

  Future<void> _testDirectQueries() async {
    try {
      // Test Faculty query
      final facultyResponse =
      await supabase.from('faculty').select().limit(5);
      setState(() {
        diagnosticMessage += '\n\n✅ Faculty Query OK\n'
            'Records: ${facultyResponse.length}';
      });

      // Test Students query
      final studentsResponse =
      await supabase.from('students').select().limit(5);
      setState(() {
        diagnosticMessage += '\n\n✅ Students Query OK\n'
            'Records: ${studentsResponse.length}';
      });

      // Test Activities query
      final activitiesResponse =
      await supabase.from('activities').select().limit(5);
      setState(() {
        diagnosticMessage += '\n\n✅ Activities Query OK\n'
            'Records: ${activitiesResponse.length}';
      });
    } catch (e) {
      setState(() {
        diagnosticMessage += '\n\n❌ Query Failed:\n$e\n\n'
            'Check RLS policies in Supabase.';
      });
    }
  }

  // ==============================
  // SETUP REAL-TIME SUBSCRIPTIONS
  // ==============================

  Future<void> _setupRealTimeSubscriptions() async {
    try {
      setState(() {
        diagnosticMessage += '\n\n🔄 Setting up real-time streams...';
      });

      // Faculty Stream
      _facultySubscription = supabase
          .from('faculty')
          .stream(primaryKey: ['id'])
          .order('first_name', ascending: true)
          .listen(
            (List<Map<String, dynamic>> data) {
          if (mounted) {
            setState(() {
              faculty = data.map((d) => Faculty.fromMap(d)).toList();
              diagnosticMessage +=
              '\n📊 Faculty: ${faculty.length} records';
              print('✅ Faculty loaded: ${faculty.length}');
            });
          }
        },
        onError: (error) {
          print('❌ Faculty stream error: $error');
          if (mounted) {
            setState(() {
              faculty = [];
              diagnosticMessage += '\n❌ Faculty stream error: $error';
            });
          }
        },
      );

      // Students Stream
      _studentsSubscription = supabase
          .from('students')
          .stream(primaryKey: ['id'])
          .order('roll_number', ascending: true)
          .listen(
            (List<Map<String, dynamic>> data) {
          if (mounted) {
            setState(() {
              students = data.map((d) => Student.fromMap(d)).toList();
              studentNamesMap = {
                for (var student in students) student.id: student.name
              };
              diagnosticMessage +=
              '\n📊 Students: ${students.length} records';
              print('✅ Students loaded: ${students.length}');
            });
          }
        },
        onError: (error) {
          print('❌ Students stream error: $error');
          if (mounted) {
            setState(() {
              students = [];
              studentNamesMap = {};
              diagnosticMessage += '\n❌ Students stream error: $error';
            });
          }
        },
      );

      // Activities Stream
      _requestsSubscription = supabase
          .from('activities')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .listen(
            (List<Map<String, dynamic>> data) {
          if (mounted) {
            setState(() {
              approvalRequests = data.map((d) {
                final studentId = d['student_id']?.toString() ?? '';
                final studentName =
                    studentNamesMap[studentId] ?? 'Unknown Student';
                return ApprovalRequest.fromMap(d, studentName);
              }).toList();
              diagnosticMessage +=
              '\n📊 Activities: ${approvalRequests.length} records';
              print('✅ Activities loaded: ${approvalRequests.length}');
            });
          }
        },
        onError: (error) {
          print('❌ Activities stream error: $error');
          if (mounted) {
            setState(() {
              approvalRequests = [];
              diagnosticMessage +=
              '\n❌ Activities stream error: $error';
            });
          }
        },
      );

      // Wait for initial data to load
      await Future.delayed(const Duration(milliseconds: 1500));

      setState(() {
        diagnosticMessage +=
        '\n\n✅ Setup Complete!\nCheck other tabs for your data.';
      });
    } catch (e) {
      print('❌ Error setting up streams: $e');
      if (mounted) {
        setState(() {
          diagnosticMessage += '\n\n❌ Setup Error: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ==============================
  // REFRESH DATA
  // ==============================

  Future<void> _refreshData() async {
    if (isRefreshing) return;
    setState(() => isRefreshing = true);

    try {
      await _facultySubscription?.cancel();
      await _studentsSubscription?.cancel();
      await _requestsSubscription?.cancel();

      await _checkAuthAndSetupData();

      if (mounted) {
        _showSnackbar('Data refreshed successfully', Colors.green);
      }
    } catch (e) {
      print('Refresh error: $e');
      if (mounted) {
        _showSnackbar('Failed to refresh data', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => isRefreshing = false);
      }
    }
  }

  // ==============================
  // UPDATE APPROVAL STATUS
  // ==============================

  Future<void> _updateApprovalStatus(
      String requestId, String newStatus) async {
    try {
      final statusValue = newStatus.toLowerCase();

      await supabase.from('activities').update({
        'status': statusValue,
      }).eq('id', int.parse(requestId));

      if (mounted) {
        _showSnackbar('Request $statusValue successfully', Colors.green);
      }
    } catch (e) {
      print('Error updating approval status: $e');
      if (mounted) {
        _showSnackbar('Error updating status: $e', Colors.red);
      }
    }
  }

  // ==============================
  // HELPER METHODS
  // ==============================

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'on leave':
        return Colors.orange;
      case 'inactive':
      case 'suspended':
        return Colors.red;
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

  // ==============================
  // UI BUILDERS
  // ==============================

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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

  Widget _buildSimpleCard(
      String name, String subtitle, String status, IconData leadingIcon) {
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      onPressed: () =>
                          _updateApprovalStatus(request.id, 'Approved'),
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
                      onPressed: () =>
                          _updateApprovalStatus(request.id, 'Rejected'),
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

  // ==============================
  // MAIN BUILD METHOD
  // ==============================

  @override
  Widget build(BuildContext context) {
    final activeStudents = students.length;
    final pendingRequests = approvalRequests
        .where((r) => r.status.toLowerCase() == 'pending')
        .length;

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

    return DefaultTabController(
      length: 4,
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
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.white),
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
            tabs: const [
              Tab(icon: Icon(Icons.people), text: 'Faculty'),
              Tab(icon: Icon(Icons.school), text: 'Students'),
              Tab(icon: Icon(Icons.assignment), text: 'Approvals'),
              Tab(icon: Icon(Icons.bug_report), text: 'Debug'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Stats Cards
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
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Faculty Tab
                  faculty.isEmpty
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No faculty members found',
                          style:
                          TextStyle(fontSize: 16, color: Colors.grey),
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
                        Icon(Icons.school,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No students found',
                          style:
                          TextStyle(fontSize: 16, color: Colors.grey),
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
                        Icon(Icons.assignment,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No approval requests found',
                          style:
                          TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: approvalRequests.length,
                    itemBuilder: (context, index) {
                      return _buildApprovalCard(
                          approvalRequests[index]);
                    },
                  ),
                  // Debug Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🐛 Debug Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            diagnosticMessage.isEmpty
                                ? 'No diagnostic information available.'
                                : diagnosticMessage,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
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
      ),
    );
  }
}

// ==============================
// SIGN OUT HANDLER
// ==============================

Future<void> _handleSignOut(BuildContext context) async {
  try {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
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
//still working!!!