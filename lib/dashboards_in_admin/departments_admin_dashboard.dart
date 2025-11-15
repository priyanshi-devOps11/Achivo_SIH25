import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class DepartmentsAdminDashboardPage extends StatefulWidget {
  const DepartmentsAdminDashboardPage({super.key});

  @override
  State<DepartmentsAdminDashboardPage> createState() =>
      _DepartmentsAdminDashboardPageState();
}

class _DepartmentsAdminDashboardPageState
    extends State<DepartmentsAdminDashboardPage> {
  List<Map<String, dynamic>> departments = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('departments')
          .select('*, institutes(name)')
          .order('name', ascending: true);

      // Fetch counts for each department
      final List<Map<String, dynamic>> enrichedDepts = [];

      for (var dept in response) {
        final deptId = dept['id'];

        // Count faculty in this department
        final facultyResponse = await supabase
            .from('faculty')
            .select('*')
            .eq('department_id', deptId);
        final facultyCount = (facultyResponse as List).length;

        // Count students in this department
        final studentResponse = await supabase
            .from('students')
            .select('*')
            .eq('department_id', deptId);
        final studentCount = (studentResponse as List).length;

        enrichedDepts.add({
          ...dept,
          'faculty_count': facultyCount,
          'student_count': studentCount,
        });
      }

      setState(() {
        departments = enrichedDepts;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('Error loading departments: $e', Colors.red);
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

  Future<void> _showAddDepartmentDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final hodController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Department'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Department Name *',
                    hintText: 'e.g., Computer Science & Engineering',
                  ),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Department Code *',
                    hintText: 'e.g., CSE',
                  ),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'dept@institute.ac.in',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    hintText: '+91 1234567890',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: hodController,
                  decoration: const InputDecoration(
                    labelText: 'Head of Department',
                    hintText: 'Dr. Name',
                  ),
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
                  // Get the institute ID for SCRIET
                  final institutes = await supabase
                      .from('institutes')
                      .select('id')
                      .eq('institute_code', 'SCRIET_UP_001')
                      .single();

                  await supabase.from('departments').insert({
                    'name': nameController.text,
                    'code': codeController.text,
                    'email': emailController.text.isEmpty
                        ? null
                        : emailController.text,
                    'phone': phoneController.text.isEmpty
                        ? null
                        : phoneController.text,
                    'head_of_department': hodController.text.isEmpty
                        ? null
                        : hodController.text,
                    'institute_id': institutes['id'],
                  });

                  Navigator.pop(context);
                  _showSnackBar(
                      'Department added successfully', Colors.green);
                  _loadDepartments();
                } catch (e) {
                  _showSnackBar('Error adding department: $e', Colors.red);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDepartmentDialog(Map<String, dynamic> dept) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: dept['name']);
    final codeController = TextEditingController(text: dept['code']);
    final emailController = TextEditingController(text: dept['email'] ?? '');
    final phoneController = TextEditingController(text: dept['phone'] ?? '');
    final hodController =
    TextEditingController(text: dept['head_of_department'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Department'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Department Name *'),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Department Code *'),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
                  enabled: false,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: hodController,
                  decoration: const InputDecoration(labelText: 'Head of Department'),
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
                  await supabase.from('departments').update({
                    'name': nameController.text,
                    'email': emailController.text.isEmpty
                        ? null
                        : emailController.text,
                    'phone': phoneController.text.isEmpty
                        ? null
                        : phoneController.text,
                    'head_of_department': hodController.text.isEmpty
                        ? null
                        : hodController.text,
                  }).eq('id', dept['id']);

                  Navigator.pop(context);
                  _showSnackBar(
                      'Department updated successfully', Colors.green);
                  _loadDepartments();
                } catch (e) {
                  _showSnackBar('Error updating department: $e', Colors.red);
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDepartment(Map<String, dynamic> dept) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Department'),
        content: Text(
            'Are you sure you want to delete ${dept['name']}? This action cannot be undone.'),
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
        await supabase.from('departments').delete().eq('id', dept['id']);
        _showSnackBar('Department deleted successfully', Colors.green);
        _loadDepartments();
      } catch (e) {
        _showSnackBar('Error deleting department: $e', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredDepartments = departments.where((dept) {
      if (searchQuery.isEmpty) return true;
      final searchLower = searchQuery.toLowerCase();
      return dept['name'].toString().toLowerCase().contains(searchLower) ||
          dept['code'].toString().toLowerCase().contains(searchLower);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Departments Management'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDepartments,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDepartmentDialog,
            tooltip: 'Add Department',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search departments...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Departments',
                    departments.length.toString(),
                    Icons.business,
                    Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Faculty',
                    departments
                        .fold<int>(
                        0, (sum, d) => sum + (d['faculty_count'] as int? ?? 0))
                        .toString(),
                    Icons.people,
                    Colors.green.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Students',
                    departments
                        .fold<int>(0,
                            (sum, d) => sum + (d['student_count'] as int? ?? 0))
                        .toString(),
                    Icons.school,
                    Colors.purple.shade600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDepartments.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No departments found',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredDepartments.length,
              itemBuilder: (context, index) {
                final dept = filteredDepartments[index];
                return _buildDepartmentCard(dept);
              },
            ),
          ),
        ],
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

  Widget _buildDepartmentCard(Map<String, dynamic> dept) {
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.business,
                      color: Colors.blue.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dept['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          dept['code'],
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
                      _showEditDepartmentDialog(dept);
                    } else if (value == 'delete') {
                      _deleteDepartment(dept);
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
            if (dept['head_of_department'] != null) ...[
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'HOD: ${dept['head_of_department']}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    Icons.people,
                    'Faculty',
                    dept['faculty_count']?.toString() ?? '0',
                    Colors.green.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    Icons.school,
                    'Students',
                    dept['student_count']?.toString() ?? '0',
                    Colors.purple.shade600,
                  ),
                ),
              ],
            ),
            if (dept['email'] != null || dept['phone'] != null) ...[
              const SizedBox(height: 12),
              if (dept['email'] != null)
                Row(
                  children: [
                    Icon(Icons.email, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      dept['email'],
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              if (dept['phone'] != null)
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      dept['phone'],
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Color.fromRGBO(
          color.red,
          color.green,
          color.blue,
          0.1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}