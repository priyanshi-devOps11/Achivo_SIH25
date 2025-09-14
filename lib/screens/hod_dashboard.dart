import 'package:flutter/material.dart';

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
}

class HODDashboard extends StatefulWidget {
  const HODDashboard({Key? key}) : super(key: key);

  @override
  State<HODDashboard> createState() => _HODDashboardState();
}

class _HODDashboardState extends State<HODDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String searchTerm = '';
  String filterStatus = 'all';
  String filterDesignation = 'all';

  // Mock data
  List<Faculty> faculty = [
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
      subjects: ['Database Systems', 'Web Development', 'Software Engineering'],
      joiningDate: '2016-01-20',
      status: 'Active',
      qualification: 'Ph.D in Information Technology',
    ),
    Faculty(
      id: '3',
      name: 'Dr. Emily Rodriguez',
      email: 'emily.rodriguez@university.edu',
      phone: '+1 (555) 345-6789',
      department: 'Computer Science',
      designation: 'Assistant Professor',
      experience: 5,
      subjects: ['Computer Networks', 'Cybersecurity', 'Operating Systems'],
      joiningDate: '2019-07-10',
      status: 'On Leave',
      qualification: 'Ph.D in Cybersecurity',
    ),
  ];

  List<Student> students = [
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
    Student(
      id: '2',
      name: 'Maria Rodriguez',
      email: 'maria.rodriguez@student.edu',
      phone: '+1 (555) 222-3333',
      rollNumber: 'CS2020015',
      year: '4th Year',
      semester: '8th Semester',
      cgpa: 9.2,
      address: '456 Campus Drive, College Town',
      parentContact: '+1 (555) 222-4444',
      status: 'Active',
      admissionDate: '2020-08-15',
    ),
  ];

  List<ApprovalRequest> approvalRequests = [
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
    ApprovalRequest(
      id: '2',
      studentId: '2',
      studentName: 'Maria Rodriguez',
      type: 'Scholarship',
      title: 'Merit Scholarship Application',
      description:
          'Application for merit-based scholarship based on academic performance.',
      submittedDate: '2024-09-03',
      status: 'Approved',
      urgency: 'Medium',
      documents: ['transcript.pdf', 'recommendation_letter.pdf'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'On Leave':
        return Colors.orange;
      case 'Inactive':
        return Colors.red;
      case 'Suspended':
        return Colors.red;
      case 'Graduated':
        return Colors.blue;
      case 'Dropped':
        return Colors.grey;
      case 'Pending':
        return Colors.orange;
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget buildFilterDropdown(String title, String currentValue,
      List<String> options, Function(String) onChanged) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          icon: const Icon(Icons.filter_list, size: 16),
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

  Widget buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFacultyCard(Faculty member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue,
              child: Text(
                member.name.split(' ').map((n) => n[0]).join(''),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: getStatusColor(member.status)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: getStatusColor(member.status),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          member.status,
                          style: TextStyle(
                            color: getStatusColor(member.status),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    member.designation,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(member.email,
                              style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(member.phone, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.work, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text('${member.experience} years experience',
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subjects: ${member.subjects.join(', ')}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
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

  Widget buildStudentCard(Student student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.green,
              child: Text(
                student.name.split(' ').map((n) => n[0]).join(''),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: getStatusColor(student.status)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: getStatusColor(student.status),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          student.status,
                          style: TextStyle(
                            color: getStatusColor(student.status),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    student.rollNumber,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(student.email,
                              style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(student.phone, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.school, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text('${student.year} - ${student.semester}',
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.grade, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text('CGPA: ${student.cgpa}/10',
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildApprovalCard(ApprovalRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: getStatusColor(request.status)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
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
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: getUrgencyColor(request.urgency)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: getUrgencyColor(request.urgency),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        request.urgency,
                        style: TextStyle(
                          color: getUrgencyColor(request.urgency),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Student: ${request.studentName}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Text(
                  'Type: ${request.type}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(request.description),
            const SizedBox(height: 12),
            if (request.status == 'Pending')
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        request.status = 'Approved';
                      });
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        request.status = 'Rejected';
                      });
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeStudents = students.where((s) => s.status == 'Active').length;
    final pendingRequests =
        approvalRequests.where((r) => r.status == 'Pending').length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.cyan],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HOD Dashboard'),
                Text(
                  'Computer Science Department',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/auth', (route) => false);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: buildStatCard(
                    'Total Faculty',
                    faculty.length.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: buildStatCard(
                    'Active Students',
                    activeStudents.toString(),
                    Icons.school,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: buildStatCard(
                    'Pending Requests',
                    pendingRequests.toString(),
                    Icons.access_time,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: buildStatCard(
                    'Total Students',
                    students.length.toString(),
                    Icons.group,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ),
          // Tab Bar
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(
                  icon: Icon(Icons.people),
                  text: 'Faculty',
                ),
                Tab(
                  icon: Icon(Icons.school),
                  text: 'Students',
                ),
                Tab(
                  icon: Icon(Icons.assignment),
                  text: 'Approval Requests',
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
                      // Search Bar
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            searchTerm = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText:
                              'Search faculty by name, email, or subject...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Filters Row
                      Row(
                        children: [
                          buildFilterDropdown(
                            'All Status',
                            filterStatus,
                            ['all', 'Active', 'On Leave', 'Inactive'],
                            (value) {
                              setState(() {
                                filterStatus = value;
                              });
                            },
                          ),
                          const SizedBox(width: 12),
                          buildFilterDropdown(
                            'All Designations',
                            filterDesignation,
                            [
                              'all',
                              'Professor',
                              'Associate Professor',
                              'Assistant Professor'
                            ],
                            (value) {
                              setState(() {
                                filterDesignation = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: faculty
                              .where((member) {
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
                                    member.status == filterStatus;
                                final matchesDesignation =
                                    filterDesignation == 'all' ||
                                        member.designation == filterDesignation;

                                return matchesSearch &&
                                    matchesStatus &&
                                    matchesDesignation;
                              })
                              .map(buildFacultyCard)
                              .toList(),
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
                      // Search Bar
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            searchTerm = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText:
                              'Search students by name, email, or roll number...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Filters Row
                      Row(
                        children: [
                          buildFilterDropdown(
                            'All Status',
                            filterStatus,
                            [
                              'all',
                              'Active',
                              'Suspended',
                              'Graduated',
                              'Dropped'
                            ],
                            (value) {
                              setState(() {
                                filterStatus = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: students
                              .where((student) {
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
                                    student.status == filterStatus;

                                return matchesSearch && matchesStatus;
                              })
                              .map(buildStudentCard)
                              .toList(),
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
                      // Search Bar
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            searchTerm = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText:
                              'Search requests by student name, title, or type...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Filters Row
                      Row(
                        children: [
                          buildFilterDropdown(
                            'All Status',
                            filterStatus,
                            ['all', 'Pending', 'Approved', 'Rejected'],
                            (value) {
                              setState(() {
                                filterStatus = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: approvalRequests
                              .where((request) {
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
                                    request.status == filterStatus;

                                return matchesSearch && matchesStatus;
                              })
                              .map(buildApprovalCard)
                              .toList(),
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
