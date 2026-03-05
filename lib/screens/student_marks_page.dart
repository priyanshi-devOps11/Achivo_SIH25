// lib/screens/student_marks_page.dart
// Shows real marks per subject entered by faculty.
// Internal + External marks displayed with grade and percentage.

import 'package:flutter/material.dart';
import '../models/student_models.dart';
import '../services/student_service.dart';

class StudentMarksPage extends StatefulWidget {
  final String studentId;

  const StudentMarksPage({Key? key, required this.studentId})
      : super(key: key);

  @override
  State<StudentMarksPage> createState() => _StudentMarksPageState();
}

class _StudentMarksPageState extends State<StudentMarksPage> {
  List<SubjectMarks> _marks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarks();
  }

  Future<void> _loadMarks() async {
    setState(() => _isLoading = true);
    final marks = await StudentService.getSubjectMarks(widget.studentId);
    if (mounted) {
      setState(() {
        _marks = marks;
        _isLoading = false;
      });
    }
  }

  // Compute overall average from available totals
  double? get _overallAverage {
    final withMarks =
    _marks.where((m) => m.combinedTotal != null).toList();
    if (withMarks.isEmpty) return null;
    final sum = withMarks.fold(0.0, (s, m) => s + m.combinedTotal!);
    return sum / withMarks.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Marks'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMarks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadMarks,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildOverallCard(),
              const SizedBox(height: 16),
              if (_marks.isEmpty)
                _buildEmpty()
              else ...[
                // Column header
                _buildTableHeader(),
                const SizedBox(height: 8),
                ..._marks
                    .map((m) => _buildSubjectCard(m))
                    .toList(),
                const SizedBox(height: 20),
                _buildLegend(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Overall summary card ───────────────────────────────────

  Widget _buildOverallCard() {
    final avg = _overallAverage;
    final subjects = _marks.length;
    final entered =
        _marks.where((m) => m.combinedTotal != null).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall Average',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(
                  avg != null ? '${avg.toStringAsFixed(1)} / 100' : '—',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$subjects subject${subjects != 1 ? 's' : ''} enrolled  •  $entered with marks',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (avg != null)
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _gradeFromMarks(avg),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Table header ───────────────────────────────────────────

  Widget _buildTableHeader() {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Expanded(
              flex: 4,
              child: Text('Subject',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal))),
          SizedBox(
              width: 44,
              child: Text('Int.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal))),
          SizedBox(
              width: 44,
              child: Text('Ext.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal))),
          SizedBox(
              width: 44,
              child: Text('Total',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal))),
          SizedBox(
              width: 32,
              child: Text('Gr.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal))),
        ],
      ),
    );
  }

  // ── Per-subject card ───────────────────────────────────────

  Widget _buildSubjectCard(SubjectMarks m) {
    final total = m.combinedTotal;
    final gradeColor =
    total != null ? _gradeColor(total) : Colors.grey;
    final grade = m.grade ?? (total != null ? _gradeFromMarks(total) : '—');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject name + faculty
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.courseName,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    if (m.facultyName != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person,
                              size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 3),
                          Text(m.facultyName!,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500])),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Internal marks
              SizedBox(
                width: 44,
                child: Center(
                  child: _marksCell(m.internalMarks, Colors.blue),
                ),
              ),

              // External marks
              SizedBox(
                width: 44,
                child: Center(
                  child: _marksCell(m.externalMarks, Colors.purple),
                ),
              ),

              // Total
              SizedBox(
                width: 44,
                child: Center(
                  child: total != null
                      ? Text(
                    total.toStringAsFixed(0),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: gradeColor),
                  )
                      : Text('—',
                      style:
                      TextStyle(color: Colors.grey[400])),
                ),
              ),

              // Grade
              SizedBox(
                width: 32,
                child: Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: gradeColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(grade,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: gradeColor)),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Progress bar (only if total available)
          if (total != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (total / 100).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: Colors.grey[200],
                valueColor:
                AlwaysStoppedAnimation<Color>(gradeColor),
              ),
            ),
          ],

          // Status badge (if not enrolled)
          if (m.status != 'enrolled') ...[
            const SizedBox(height: 8),
            _statusBadge(m.status),
          ],
        ],
      ),
    );
  }

  Widget _marksCell(double? val, Color color) {
    if (val == null) {
      return Text('—',
          style: TextStyle(color: Colors.grey[400], fontSize: 13));
    }
    return Text(
      val.toStringAsFixed(0),
      style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color),
    );
  }

  Widget _statusBadge(String status) {
    Color c;
    switch (status) {
      case 'completed':
        c = Colors.green;
        break;
      case 'failed':
        c = Colors.red;
        break;
      case 'dropped':
        c = Colors.grey;
        break;
      default:
        c = Colors.orange;
    }
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
            fontSize: 11, color: c, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Grade Scale',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _legendItem('A+ ≥ 90', Colors.green.shade700),
              _legendItem('A ≥ 80', Colors.green),
              _legendItem('B+ ≥ 70', Colors.blue),
              _legendItem('B ≥ 60', Colors.blue.shade300),
              _legendItem('C ≥ 50', Colors.orange),
              _legendItem('F < 50', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grade_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'No marks available yet.\nYour faculty will enter them in the portal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ── Grade helpers ──────────────────────────────────────────

  String _gradeFromMarks(double marks) {
    if (marks >= 90) return 'A+';
    if (marks >= 80) return 'A';
    if (marks >= 70) return 'B+';
    if (marks >= 60) return 'B';
    if (marks >= 50) return 'C';
    return 'F';
  }

  Color _gradeColor(double marks) {
    if (marks >= 90) return Colors.green.shade700;
    if (marks >= 80) return Colors.green;
    if (marks >= 70) return Colors.blue;
    if (marks >= 60) return Colors.blue.shade300;
    if (marks >= 50) return Colors.orange;
    return Colors.red;
  }
}