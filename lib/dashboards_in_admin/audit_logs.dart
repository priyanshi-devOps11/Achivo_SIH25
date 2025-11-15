import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final supabase = Supabase.instance.client;

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  List<Map<String, dynamic>> auditLogs = [];
  bool isLoading = true;
  String filterTable = 'all';
  String filterAction = 'all';
  String searchQuery = '';

  final List<String> tables = [
    'profiles',
    'students',
    'faculty',
    'activities',
    'departments',
    'courses',
    'attendance',
  ];

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => isLoading = true);
    try {
      final List<Map<String, dynamic>> logs = [];

      // Get activity logs with student info
      try {
        final activities = await supabase
            .from('activities')
            .select('*, students!inner(first_name, last_name, email, roll_number)')
            .order('created_at', ascending: false)
            .limit(50);

        for (var activity in activities) {
          final student = activity['students'];
          logs.add({
            'id': activity['id'],
            'action': _getActivityAction(activity['status']),
            'table_name': 'activities',
            'record_id': activity['id'].toString(),
            'user_email': student?['email'] ?? 'Unknown',
            'user_name':
            '${student?['first_name'] ?? ''} ${student?['last_name'] ?? ''}'
                .trim(),
            'description': _getActivityDescription(activity),
            'timestamp': activity['created_at'] ?? DateTime.now().toIso8601String(),
            'details': {
              'title': activity['title'],
              'category': activity['category'],
              'status': activity['status'],
              'points': activity['points'],
            },
          });
        }
      } catch (e) {
        print('Error loading activities: $e');
      }

      // Get recent profile updates
      try {
        final profiles = await supabase
            .from('profiles')
            .select('*')
            .order('updated_at', ascending: false)
            .limit(30);

        for (var profile in profiles) {
          if (profile['updated_at'] != profile['created_at']) {
            logs.add({
              'id': profile['id'],
              'action': 'UPDATE',
              'table_name': 'profiles',
              'record_id': profile['id'].toString(),
              'user_email': profile['email'] ?? 'Unknown',
              'user_name': '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim(),
              'description': 'Profile updated',
              'timestamp': profile['updated_at'] ?? DateTime.now().toIso8601String(),
              'details': {
                'role': profile['role'],
                'is_active': profile['is_active'],
              },
            });
          }
        }
      } catch (e) {
        print('Error loading profiles: $e');
      }

      // Get student enrollment data
      try {
        final students = await supabase
            .from('students')
            .select('*')
            .order('created_at', ascending: false)
            .limit(20);

        for (var student in students) {
          logs.add({
            'id': student['id'],
            'action': 'CREATE',
            'table_name': 'students',
            'record_id': student['id'].toString(),
            'user_email': student['email'] ?? 'Unknown',
            'user_name': '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim(),
            'description': 'Student enrolled',
            'timestamp': student['created_at'] ?? DateTime.now().toIso8601String(),
            'details': {
              'roll_number': student['roll_number'],
              'year': student['year'],
              'branch': student['branch'],
            },
          });
        }
      } catch (e) {
        print('Error loading students: $e');
      }

      // Sort all logs by timestamp
      logs.sort((a, b) => DateTime.parse(b['timestamp'])
          .compareTo(DateTime.parse(a['timestamp'])));

      setState(() {
        auditLogs = logs;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('Error loading audit logs: $e', Colors.red);
    }
  }

  String _getActivityAction(String? status) {
    switch (status) {
      case 'approved':
        return 'APPROVED';
      case 'rejected':
        return 'REJECTED';
      case 'pending':
        return 'SUBMITTED';
      default:
        return 'UPDATE';
    }
  }

  String _getActivityDescription(Map<String, dynamic> activity) {
    final status = activity['status'] ?? 'pending';
    final title = activity['title'] ?? 'Activity';

    switch (status) {
      case 'approved':
        return 'Activity "$title" approved';
      case 'rejected':
        return 'Activity "$title" rejected';
      case 'pending':
        return 'Activity "$title" submitted for approval';
      default:
        return 'Activity "$title" updated';
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

  Color _getActionColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
      case 'SUBMITTED':
        return Colors.green.shade600;
      case 'UPDATE':
        return Colors.blue.shade600;
      case 'DELETE':
        return Colors.red.shade600;
      case 'APPROVED':
        return Colors.teal.shade600;
      case 'REJECTED':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
      case 'SUBMITTED':
        return Icons.add_circle;
      case 'UPDATE':
        return Icons.edit;
      case 'DELETE':
        return Icons.delete;
      case 'APPROVED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = auditLogs.where((log) {
      if (searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        if (!log['user_email'].toString().toLowerCase().contains(searchLower) &&
            !log['description'].toString().toLowerCase().contains(searchLower) &&
            !log['user_name'].toString().toLowerCase().contains(searchLower)) {
          return false;
        }
      }

      if (filterAction != 'all' && log['action'] != filterAction) {
        return false;
      }

      if (filterTable != 'all' && log['table_name'] != filterTable) {
        return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('System Activity Logs'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAuditLogs,
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterDialog(),
            tooltip: 'Advanced Filters',
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
                    hintText: 'Search by user, email, or description...',
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
                      const Text('Action: ',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      _buildFilterChip('all', 'All', isTable: false),
                      _buildFilterChip('CREATE', 'Create', isTable: false),
                      _buildFilterChip('UPDATE', 'Update', isTable: false),
                      _buildFilterChip('APPROVED', 'Approved', isTable: false),
                      _buildFilterChip('REJECTED', 'Rejected', isTable: false),
                      _buildFilterChip('SUBMITTED', 'Submitted', isTable: false),
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
                    'Total Logs',
                    auditLogs.length.toString(),
                    Icons.description,
                    Colors.deepPurple.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Today',
                    auditLogs
                        .where((l) {
                      try {
                        final date = DateTime.parse(l['timestamp']);
                        return date.day == DateTime.now().day &&
                            date.month == DateTime.now().month &&
                            date.year == DateTime.now().year;
                      } catch (e) {
                        return false;
                      }
                    })
                        .length
                        .toString(),
                    Icons.today,
                    Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Activities',
                    auditLogs
                        .where((l) => l['table_name'] == 'activities')
                        .length
                        .toString(),
                    Icons.event,
                    Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredLogs.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No activity logs found',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredLogs.length,
              itemBuilder: (context, index) {
                final log = filteredLogs[index];
                return _buildLogCard(log);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Table:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: [
                _buildDialogFilterChip('all', 'All', isTable: true),
                ...tables.map((t) => _buildDialogFilterChip(t, t, isTable: true)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                filterTable = 'all';
                filterAction = 'all';
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogFilterChip(String value, String label,
      {required bool isTable}) {
    final isSelected = isTable ? filterTable == value : filterAction == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (isTable) {
            filterTable = value;
          } else {
            filterAction = value;
          }
        });
      },
    );
  }

  Widget _buildFilterChip(String value, String label, {required bool isTable}) {
    final isSelected = isTable ? filterTable == value : filterAction == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            if (isTable) {
              filterTable = value;
            } else {
              filterAction = value;
            }
          });
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: Colors.deepPurple.shade100,
        checkmarkColor: Colors.deepPurple.shade700,
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

  Widget _buildLogCard(Map<String, dynamic> log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showLogDetails(log),
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
                      color: _getActionColor(log['action']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getActionIcon(log['action']),
                      color: _getActionColor(log['action']),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getActionColor(log['action']),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                log['action'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                log['table_name'].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          log['description'],
                          style: TextStyle(
                              color: Colors.grey.shade800, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${log['user_name']} (${log['user_email']})',
                      style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimestamp(log['timestamp']),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogDetails(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getActionIcon(log['action']),
                color: _getActionColor(log['action']), size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text(log['action'])),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Description', log['description']),
              _buildDetailRow('Table', log['table_name']),
              _buildDetailRow('Record ID', log['record_id']),
              _buildDetailRow('User', log['user_name']),
              _buildDetailRow('Email', log['user_email']),
              _buildDetailRow(
                  'Timestamp',
                  DateFormat('MMM dd, yyyy hh:mm a')
                      .format(DateTime.parse(log['timestamp']))),
              if (log['details'] != null) ...[
                const Divider(height: 24),
                const Text(
                  'Additional Details:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...log['details']
                    .entries
                    .map((e) => _buildDetailRow(
                  e.key,
                  e.value?.toString() ?? 'N/A',
                ))
                    .toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}