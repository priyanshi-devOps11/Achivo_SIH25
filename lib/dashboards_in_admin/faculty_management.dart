import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class FacultyManagementPage extends StatefulWidget {
  const FacultyManagementPage({super.key});

  @override
  State<FacultyManagementPage> createState() => _FacultyManagementPageState();
}

class _FacultyManagementPageState extends State<FacultyManagementPage> {
  List<Map<String, dynamic>> faculty = [];
  List<Map<String, dynamic>> departments = [];
  bool isLoading = true;
  String searchQuery = '';
  String filterDepartment = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      await Future.wait([
        _loadFaculty(),
        _loadDepartments(),
      ]);
    } catch (e) {
      _showSnackBar('Error loading data: $e', Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadFaculty() async {
    try {
      final response = await supabase
          .from('faculty')
          .select('*, departments(name, code)')
          .order('first_name', ascending: true);

      setState(() {
        faculty = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading faculty: $e');
    }
  }

  Future<void> _loadDepartments() async {
    try {
      final response = await supabase
          .from('departments')
          .select('id, name, code')
          .order('name', ascending: true);

      setState(() {
        departments = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading departments: $e');
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showAddFacultyDialog() async {
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final facultyIdController = TextEditingController();
    final designationController = TextEditingController();
    final qualificationController = TextEditingController();
    final specializationController = TextEditingController();
    int? selectedDepartmentId;
    String? selectedGender;
    int experienceYears = 0;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Faculty'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name *'),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name *'),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: facultyIdController,
                  decoration: const InputDecoration(labelText: 'Faculty ID'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: ['Male', 'Female', 'Other'].map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (value) => selectedGender = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedDepartmentId,
                  decoration: const InputDecoration(labelText: 'Department *'),
                  items: departments.map((dept) {
                    return DropdownMenuItem<int>(
                      value: dept['id'],
                      child: Text(dept['name']),
                    );
                  }).toList(),
                  onChanged: (value) => selectedDepartmentId = value,
                  validator: (value) => value == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: designationController,
                  decoration: const InputDecoration(labelText: 'Designation'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: qualificationController,
                  decoration: const InputDecoration(labelText: 'Qualification'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: specializationController,
                  decoration: const InputDecoration(labelText: 'Specialization'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: '0',
                  decoration:
                  const InputDecoration(labelText: 'Experience (years)'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                  experienceYears = int.tryParse(value) ?? 0,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  // First create profile
                  final profileData = {
                    'first_name': firstNameController.text,
                    'last_name': lastNameController.text,
                    'email': emailController.text,
                    'role': 'faculty',
                    'phone': phoneController.text.isEmpty
                        ? null
                        : phoneController.text,
                    'gender': selectedGender,
                    'department_id': selectedDepartmentId,
                    'is_active': true,
                    'email_verified': false,
                  };

                  final profileResponse =
                  await supabase.from('profiles').insert(profileData).select().single();

                  // Then create faculty record
                  await supabase.from('faculty').insert({
                    'user_id': profileResponse['id'],
                    'first_name': firstNameController.text,
                    'last_name': lastNameController.text,
                    'email': emailController.text,
                    'phone': phoneController.text.isEmpty
                        ? null
                        : phoneController.text,
                    'gender': selectedGender,
                    'faculty_id': facultyIdController.text.isEmpty
                        ? null
                        : facultyIdController.text,
                    'department_id': selectedDepartmentId,
                    'designation': designationController.text.isEmpty
                        ? null
                        : designationController.text,
                    'qualification': qualificationController.text.isEmpty
                        ? null
                        : qualificationController.text,
                    'specialization': specializationController.text.isEmpty
                        ? null
                        : specializationController.text,
                    'experience_years': experienceYears,
                  });

                  Navigator.pop(context);
                  _showSnackBar('Faculty added successfully', Colors.green);
                  _loadFaculty();
                } catch (e) {
                  _showSnackBar('Error adding faculty: $e', Colors.red);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditFacultyDialog(Map<String, dynamic> facultyMember) async {
    final formKey = GlobalKey<FormState>();
    final firstNameController =
    TextEditingController(text: facultyMember['first_name']);
    final lastNameController =
    TextEditingController(text: facultyMember['last_name']);
    final phoneController =
    TextEditingController(text: facultyMember['phone'] ?? '');
    final designationController =
    TextEditingController(text: facultyMember['designation'] ?? '');
    final qualificationController =
    TextEditingController(text: facultyMember['qualification'] ?? '');
    final specializationController =
    TextEditingController(text: facultyMember['specialization'] ?? '');
    int? selectedDepartmentId = facultyMember['department_id'];
    String? selectedGender = facultyMember['gender'];
    int experienceYears = facultyMember['experience_years'] ?? 0;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Faculty'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name *'),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name *'),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: ['Male', 'Female', 'Other'].map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (value) => selectedGender = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedDepartmentId,
                  decoration: const InputDecoration(labelText: 'Department *'),
                  items: departments.map((dept) {
                    return DropdownMenuItem<int>(
                      value: dept['id'],
                      child: Text(dept['name']),
                    );
                  }).toList(),
                  onChanged: (value) => selectedDepartmentId = value,
                  validator: (value) => value == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: designationController,
                  decoration: const InputDecoration(labelText: 'Designation'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: qualificationController,
                  decoration: const InputDecoration(labelText: 'Qualification'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: specializationController,
                  decoration: const InputDecoration(labelText: 'Specialization'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: experienceYears.toString(),
                  decoration:
                  const InputDecoration(labelText: 'Experience (years)'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                  experienceYears = int.tryParse(value) ?? 0,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  // Update profile
                  await supabase.from('profiles').update({
                    'first_name': firstNameController.text,
                    'last_name': lastNameController.text,
                    'phone': phoneController.text.isEmpty
                        ? null
                        : phoneController.text,
                    'gender': selectedGender,
                    'department_id': selectedDepartmentId,
                  }).eq('id', facultyMember['user_id']);

                  // Update faculty
                  await supabase.from('faculty').update({
                    'first_name': firstNameController.text,
                    'last_name': lastNameController.text,
                    'phone': phoneController.text.isEmpty
                        ? null
                        : phoneController.text,
                    'gender': selectedGender,
                    'department_id': selectedDepartmentId,
                    'designation': designationController.text.isEmpty
                        ? null
                        : designationController.text,
                    'qualification': qualificationController.text.isEmpty
                        ? null
                        : qualificationController.text,
                    'specialization': specializationController.text.isEmpty
                        ? null
                        : specializationController.text,
                    'experience_years': experienceYears,
                  }).eq('id', facultyMember['id']);

                  Navigator.pop(context);
                  _showSnackBar('Faculty updated successfully', Colors.green);
                  _loadFaculty();
                } catch (e) {
                  _showSnackBar('Error updating faculty: $e', Colors.red);
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFaculty(Map<String, dynamic> facultyMember) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Faculty'),
        content: Text(
            'Are you sure you want to delete ${facultyMember['first_name']} ${facultyMember['last_name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from('faculty').delete().eq('id', facultyMember['id']);
        _showSnackBar('Faculty deleted successfully', Colors.green);
        _loadFaculty();
      } catch (e) {
        _showSnackBar('Error deleting faculty: $e', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaculty = faculty.where((f) {
      if (searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        if (!f['first_name'].toString().toLowerCase().contains(searchLower) &&
            !f['last_name'].toString().toLowerCase().contains(searchLower) &&
            !f['email'].toString().toLowerCase().contains(searchLower)) {
          return false;
        }
      }

      if (filterDepartment != 'all' &&
          f['department_id'].toString() != filterDepartment) {
        return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Faculty Management'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddFacultyDialog,
            tooltip: 'Add Faculty',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search faculty by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Department: ',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      _buildFilterChip('all', 'All'),
                      ...departments.map((dept) =>
                          _buildFilterChip(dept['id'].toString(), dept['code'])),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Faculty',
                    faculty.length.toString(),
                    Icons.people,
                    Colors.green.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Professors',
                    faculty
                        .where((f) =>
                    f['designation']?.toString().contains('Professor') ??
                        false)
                        .length
                        .toString(),
                    Icons.school,
                    Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Departments',
                    departments.length.toString(),
                    Icons.business,
                    Colors.purple.shade600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredFaculty.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No faculty found',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredFaculty.length,
              itemBuilder: (context, index) {
                final f = filteredFaculty[index];
                return _buildFacultyCard(f);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = filterDepartment == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            filterDepartment = value;
          });
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: Colors.green.shade100,
        checkmarkColor: Colors.green.shade700,
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacultyCard(Map<String, dynamic> f) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    '${f['first_name'][0]}${f['last_name'][0]}'.toUpperCase(),
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${f['first_name']} ${f['last_name']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (f['designation'] != null)
                        Text(
                          f['designation'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      if (f['departments'] != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            f['departments']['code'],
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditFacultyDialog(f);
                    } else if (value == 'delete') {
                      _deleteFaculty(f);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.email, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    f['email'],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              ],
            ),
            if (f['phone'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    f['phone'],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
            if (f['specialization'] != null || f['experience_years'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (f['specialization'] != null)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star,
                                size: 14, color: Colors.blue.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                f['specialization'],
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (f['experience_years'] != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.work,
                              size: 14, color: Colors.orange.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${f['experience_years']} yrs',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}