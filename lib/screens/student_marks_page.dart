// lib/screens/student_marks_page.dart
// Redesigned with AchivoColors, subject cards with internal/external breakdown

import 'package:flutter/material.dart';
import '../models/student_models.dart';
import '../services/student_service.dart';
import 'student_dashboard.dart';

class StudentMarksPage extends StatefulWidget {
  final String studentId;
  const StudentMarksPage({Key? key, required this.studentId}) : super(key: key);

  @override
  State<StudentMarksPage> createState() => _StudentMarksPageState();
}

class _StudentMarksPageState extends State<StudentMarksPage> {
  List<SubjectMarks> _marks = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadMarks(); }

  Future<void> _loadMarks() async {
    setState(() => _isLoading = true);
    final m = await StudentService.getSubjectMarks(widget.studentId);
    if (mounted) setState(() { _marks = m; _isLoading = false; });
  }

  double? get _avg {
    final with_ = _marks.where((m) => m.combinedTotal != null).toList();
    if (with_.isEmpty) return null;
    return with_.fold(0.0, (s, m) => s + m.combinedTotal!) / with_.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AchivoColors.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AchivoColors.purpleDark))
          : RefreshIndicator(
        color: AchivoColors.purpleDark,
        onRefresh: _loadMarks,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_marks.isEmpty)
              _buildEmpty()
            else ...[
              _buildTableHeader(),
              const SizedBox(height: 8),
              ..._marks.map(_buildSubjectCard),
              const SizedBox(height: 20),
              _buildGradeLegend(),
            ],
          ]),
        ),
      ),
    );
  }

  // ── Header banner ─────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final avg = _avg;
    final entered = _marks.where((m) => m.combinedTotal != null).length;
    return AchivoPageBanner(
      title: 'My Marks',
      subtitle: '${_marks.length} subjects · $entered with marks entered',
      gradient: AchivoColors.gradientPurple,
      chips: [
        if (avg != null)
          _GradePill(avg: avg),
      ],
    );
  }

  // ── Column header ─────────────────────────────────────────────────────────

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(color: AchivoColors.purpleLight, borderRadius: BorderRadius.circular(8)),
      child: const Row(children: [
        Expanded(flex: 4, child: Text('Subject', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AchivoColors.purpleDark))),
        SizedBox(width: 46, child: Text('Int.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AchivoColors.purpleDark))),
        SizedBox(width: 46, child: Text('Ext.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AchivoColors.purpleDark))),
        SizedBox(width: 46, child: Text('Total', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AchivoColors.purpleDark))),
        SizedBox(width: 34, child: Text('Grade', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AchivoColors.purpleDark))),
      ]),
    );
  }

  // ── Subject card ──────────────────────────────────────────────────────────

  Widget _buildSubjectCard(SubjectMarks m) {
    final total  = m.combinedTotal;
    final gc     = total != null ? _gradeColor(total) : AchivoColors.textHint;
    final gcBg   = total != null ? _gradeBg(total) : const Color(0xFFF1EFE8);
    final grade  = m.grade ?? (total != null ? _gradeFromMarks(total) : '—');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AchivoColors.cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AchivoColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.courseName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AchivoColors.textPrimary)),
            if (m.facultyName != null) ...[
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.person_rounded, size: 12, color: AchivoColors.textHint),
                const SizedBox(width: 3),
                Text(m.facultyName!, style: const TextStyle(fontSize: 11, color: AchivoColors.textSecond)),
              ]),
            ],
          ])),
          SizedBox(width: 46, child: Center(child: _MarksCell(value: m.internalMarks, color: const Color(0xFF185FA5)))),
          SizedBox(width: 46, child: Center(child: _MarksCell(value: m.externalMarks, color: AchivoColors.purpleDark))),
          SizedBox(width: 46, child: Center(child: total != null
              ? Text(total.toStringAsFixed(0), textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: gc))
              : const Text('—', style: TextStyle(color: AchivoColors.textHint)))),
          SizedBox(width: 34, child: Center(child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: gcBg, shape: BoxShape.circle),
            child: Center(child: Text(grade, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: gc))),
          ))),
        ]),
        if (total != null) ...[
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: (total / 100).clamp(0.0, 1.0), minHeight: 5,
                  backgroundColor: gcBg, valueColor: AlwaysStoppedAnimation<Color>(gc))),
        ],
        if (m.status != 'enrolled') ...[
          const SizedBox(height: 8),
          AchivoStatusBadge(m.status),
        ],
      ]),
    );
  }

  // ── Grade legend ──────────────────────────────────────────────────────────

  Widget _buildGradeLegend() {
    final items = [
      ('A+ ≥ 90', const Color(0xFF3B6D11)),
      ('A  ≥ 80', AchivoColors.tealDark),
      ('B+ ≥ 70', AchivoColors.purpleDark),
      ('B  ≥ 60', const Color(0xFF185FA5)),
      ('C  ≥ 50', AchivoColors.amber),
      ('F  < 50',  AchivoColors.red),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AchivoColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AchivoColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Grade Scale', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AchivoColors.textPrimary)),
        const SizedBox(height: 10),
        Wrap(spacing: 12, runSpacing: 8, children: items.map((e) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: e.$2, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(e.$1, style: const TextStyle(fontSize: 12, color: AchivoColors.textSecond)),
        ])).toList()),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: AchivoColors.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AchivoColors.border)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.workspace_premium_rounded, size: 56, color: AchivoColors.textHint.withOpacity(0.4)),
        const SizedBox(height: 14),
        const Text('No marks available yet.\nYour faculty will enter them in the portal.',
            textAlign: TextAlign.center, style: TextStyle(color: AchivoColors.textSecond, fontSize: 14)),
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _gradeFromMarks(double m) {
    if (m >= 90) return 'A+';
    if (m >= 80) return 'A';
    if (m >= 70) return 'B+';
    if (m >= 60) return 'B';
    if (m >= 50) return 'C';
    return 'F';
  }

  Color _gradeColor(double m) {
    if (m >= 90) return const Color(0xFF3B6D11);
    if (m >= 80) return AchivoColors.tealDark;
    if (m >= 70) return AchivoColors.purpleDark;
    if (m >= 60) return const Color(0xFF185FA5);
    if (m >= 50) return AchivoColors.amber;
    return AchivoColors.red;
  }

  Color _gradeBg(double m) {
    if (m >= 90) return const Color(0xFFEAF3DE);
    if (m >= 80) return AchivoColors.tealLight;
    if (m >= 70) return AchivoColors.purpleLight;
    if (m >= 60) return const Color(0xFFE6F1FB);
    if (m >= 50) return AchivoColors.amberLight;
    return AchivoColors.redLight;
  }
}



class _MarksCell extends StatelessWidget {
  final double? value;
  final Color   color;
  const _MarksCell({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    if (value == null) return const Text('—', style: TextStyle(color: AchivoColors.textHint, fontSize: 13));
    return Text(value!.toStringAsFixed(0), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color));
  }
}

class _GradePill extends StatelessWidget {
  final double avg;
  const _GradePill({required this.avg});

  String get _grade {
    if (avg >= 90) return 'A+';
    if (avg >= 80) return 'A';
    if (avg >= 70) return 'B+';
    if (avg >= 60) return 'B';
    if (avg >= 50) return 'C';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(20)),
      child: Text('Avg: ${avg.toStringAsFixed(1)} · Grade $_grade', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}