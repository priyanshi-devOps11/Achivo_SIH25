// lib/screens/student_attendance_page.dart
// Shows real attendance per subject, marked by faculty.
// Multiple subjects / multiple faculties are all listed separately.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student_models.dart';
import '../services/student_service.dart';

class StudentAttendancePage extends StatefulWidget {
  final String studentId;

  const StudentAttendancePage({Key? key, required this.studentId})
      : super(key: key);

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<SubjectAttendance> _summaries = [];
  List<AttendanceRecord> _allRecords = [];
  bool _isLoading = true;

  // For "Detailed" tab — filter by subject
  int? _selectedCourseId; // null = all

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final summaries = await StudentService.getSubjectAttendanceSummary(
        widget.studentId);
    final records =
    await StudentService.getAttendanceRecords(widget.studentId);
    if (mounted) {
      setState(() {
        _summaries = summaries;
        _allRecords = records;
        _isLoading = false;
      });
    }
  }

  // Overall attendance across all subjects
  double get _overallPercentage {
    if (_summaries.isEmpty) return 0;
    int total = _summaries.fold(0, (s, e) => s + e.total);
    int present = _summaries.fold(0, (s, e) => s + e.present + e.late);
    return total == 0 ? 0 : (present / total) * 100;
  }

  List<AttendanceRecord> get _filteredRecords {
    if (_selectedCourseId == null) return _allRecords;
    return _allRecords
        .where((r) => r.courseId == _selectedCourseId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Attendance'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'By Subject', icon: Icon(Icons.bar_chart, size: 18)),
            Tab(text: 'Detailed', icon: Icon(Icons.list_alt, size: 18)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildDetailedTab(),
        ],
      ),
    );
  }

  // ── TAB 1: Subject summary ─────────────────────────────────

  Widget _buildSummaryTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildOverallCard(),
            const SizedBox(height: 16),
            if (_summaries.isEmpty)
              _buildEmpty('No attendance records found yet.\nYour faculty hasn\'t marked attendance for you.')
            else
              ..._summaries.map((s) => _buildSubjectCard(s)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallCard() {
    final pct = _overallPercentage;
    final color = _pctColor(pct);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.indigo.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overall Attendance',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pct >= 75
                          ? '✅ Good standing'
                          : pct >= 60
                          ? '⚠️ At risk'
                          : '🚨 Critical',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_summaries.length} subject${_summaries.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                  pct >= 75 ? Colors.greenAccent : Colors.orangeAccent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pct < 75
                ? 'Minimum 75% required. You need to improve!'
                : 'You are meeting the minimum attendance requirement.',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(SubjectAttendance s) {
    final pct = s.percentage;
    final color = _pctColor(pct);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: s.isLow
              ? Colors.red.withOpacity(0.3)
              : Colors.grey.withOpacity(0.15),
          width: s.isLow ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject + faculty
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.courseName,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    if (s.facultyName != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.person, size: 13,
                              color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(s.facultyName!,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Percentage badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color),
                ),
                child: Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 7,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          const SizedBox(height: 10),

          // Stats row
          Row(
            children: [
              _statChip(Icons.check_circle, '${s.present}', Colors.green,
                  'Present'),
              const SizedBox(width: 6),
              _statChip(Icons.cancel, '${s.absent}', Colors.red, 'Absent'),
              const SizedBox(width: 6),
              _statChip(Icons.event_busy, '${s.leave}', Colors.orange,
                  'Leave'),
              const SizedBox(width: 6),
              _statChip(Icons.schedule, '${s.late}', Colors.purple, 'Late'),
              const Spacer(),
              Text('${s.total} total',
                  style:
                  TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),

          if (s.isLow) ...[
            const SizedBox(height: 10),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      size: 14, color: Colors.red),
                  const SizedBox(width: 6),
                  Text(
                    'Below 75% — ${_classesNeeded(s)} more classes needed',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── TAB 2: Day-by-day records ──────────────────────────────

  Widget _buildDetailedTab() {
    final subjectOptions = _summaries;

    return Column(
      children: [
        // Filter bar
        Container(
          color: Colors.white,
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.filter_list,
                  size: 18, color: Colors.indigo),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selectedCourseId,
                    isExpanded: true,
                    hint: const Text('All Subjects'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Subjects'),
                      ),
                      ...subjectOptions.map((s) =>
                          DropdownMenuItem<int?>(
                            value: s.courseId,
                            child: Text(s.courseName,
                                overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedCourseId = v),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Records list
        Expanded(
          child: _filteredRecords.isEmpty
              ? _buildEmpty('No records found for this filter.')
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _filteredRecords.length,
            itemBuilder: (_, i) =>
                _buildRecordTile(_filteredRecords[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordTile(AttendanceRecord r) {
    final statusColor = _statusColor(r.status);
    final statusIcon = _statusIcon(r.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: statusColor.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 12),

          // Subject + faculty
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.courseName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                if (r.facultyName != null)
                  Text('by ${r.facultyName!}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),

          // Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(DateFormat('dd MMM').format(r.date),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              Text(DateFormat('yyyy').format(r.date),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),

          const SizedBox(width: 10),

          // Status badge
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              r.status[0].toUpperCase() + r.status.substring(1),
              style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  Widget _statChip(
      IconData icon, String value, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text('$value $label',
            style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }

  Widget _buildEmpty(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Color _pctColor(double pct) {
    if (pct >= 75) return Colors.green;
    if (pct >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'leave':
        return Colors.orange;
      case 'late':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle_outline;
      case 'absent':
        return Icons.cancel_outlined;
      case 'leave':
        return Icons.event_busy;
      case 'late':
        return Icons.schedule;
      default:
        return Icons.help_outline;
    }
  }

  /// How many consecutive present classes needed to reach 75%
  int _classesNeeded(SubjectAttendance s) {
    if (s.percentage >= 75) return 0;
    // (present + x) / (total + x) >= 0.75
    // present + x >= 0.75 * total + 0.75x
    // 0.25x >= 0.75*total - present
    final need = (0.75 * s.total - (s.present + s.late)) / 0.25;
    return need.ceil().clamp(0, 9999);
  }
}