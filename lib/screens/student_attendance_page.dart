// lib/screens/student_attendance_page.dart
// Redesigned with AchivoColors, banner header, richer subject cards

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student_models.dart';
import '../services/student_service.dart';
import 'student_dashboard.dart';

class StudentAttendancePage extends StatefulWidget {
  final String studentId;
  const StudentAttendancePage({Key? key, required this.studentId}) : super(key: key);

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<SubjectAttendance> _summaries = [];
  List<AttendanceRecord>  _allRecords = [];
  bool    _isLoading = true;
  int?    _selectedCourseId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final s = await StudentService.getSubjectAttendanceSummary(widget.studentId);
    final r = await StudentService.getAttendanceRecords(widget.studentId);
    if (mounted) setState(() { _summaries = s; _allRecords = r; _isLoading = false; });
  }

  double get _overall {
    if (_summaries.isEmpty) return 0;
    final tot  = _summaries.fold(0, (s, e) => s + e.total);
    final pres = _summaries.fold(0, (s, e) => s + e.present + e.late);
    return tot == 0 ? 0 : (pres / tot) * 100;
  }

  List<AttendanceRecord> get _filtered =>
      _selectedCourseId == null ? _allRecords : _allRecords.where((r) => r.courseId == _selectedCourseId).toList();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AchivoColors.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AchivoColors.teal))
          : NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: _buildHeader())),
          SliverPersistentHeader(pinned: true, delegate: _TabDelegate(_tabs)),
        ],
        body: TabBarView(controller: _tabs, children: [
          _buildSummaryTab(),
          _buildDetailedTab(),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    final pct = _overall;
    return AchivoPageBanner(
      title: 'My Attendance',
      subtitle: '${_summaries.length} subjects · ${pct.toStringAsFixed(1)}% overall',
      gradient: AchivoColors.gradientTeal,
      chips: [
        _StatusChip(pct >= 75 ? '✓ Good standing' : pct >= 60 ? '⚠ At risk' : '⚠ Critical',
            pct >= 75 ? AchivoColors.teal : AchivoColors.red),
      ],
    );
  }

  // ── TAB 1: Subject summary ─────────────────────────────────────────────────

  Widget _buildSummaryTab() {
    if (_summaries.isEmpty) return _Empty(icon: Icons.event_note_rounded, message: 'No attendance records yet.\nYour faculty hasn\'t marked attendance.');

    return RefreshIndicator(
      color: AchivoColors.teal,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          _OverallCard(pct: _overall),
          const SizedBox(height: 16),
          ..._summaries.map(_buildSubjectCard),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(SubjectAttendance s) {
    final col = _pctColor(s.percentage);
    final low = s.percentage < 75;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AchivoColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: low ? AchivoColors.red.withOpacity(0.3) : AchivoColors.border, width: low ? 1.5 : 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.courseName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AchivoColors.textPrimary)),
            if (s.facultyName != null) ...[
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.person_rounded, size: 13, color: AchivoColors.textHint),
                const SizedBox(width: 4),
                Text(s.facultyName!, style: const TextStyle(fontSize: 12, color: AchivoColors.textSecond)),
              ]),
            ],
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: col.withOpacity(0.4))),
            child: Text('${s.percentage.toStringAsFixed(1)}%', style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: (s.percentage / 100).clamp(0.0, 1.0), minHeight: 7,
                backgroundColor: col.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(col))),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _AttChip(Icons.check_circle_rounded, '${s.present}', 'Present', const Color(0xFFEAF3DE), const Color(0xFF3B6D11)),
          _AttChip(Icons.cancel_rounded, '${s.absent}', 'Absent', AchivoColors.redLight, AchivoColors.red),
          _AttChip(Icons.event_busy_rounded, '${s.leave}', 'Leave', AchivoColors.amberLight, AchivoColors.amber),
          _AttChip(Icons.schedule_rounded, '${s.late}', 'Late', AchivoColors.purpleLight, AchivoColors.purpleDark),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFF1EFE8), borderRadius: BorderRadius.circular(20)),
            child: Text('${s.total} total', style: const TextStyle(fontSize: 11, color: Color(0xFF5F5E5A))),
          ),
        ]),
        if (low) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: AchivoColors.redLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AchivoColors.red.withOpacity(0.2))),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, size: 14, color: AchivoColors.red),
              const SizedBox(width: 6),
              Text('Below 75% — ${_classesNeeded(s)} more classes to reach threshold',
                  style: const TextStyle(fontSize: 11, color: AchivoColors.red, fontWeight: FontWeight.w500)),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── TAB 2: Detailed records ────────────────────────────────────────────────

  Widget _buildDetailedTab() {
    return Column(children: [
      _FilterBar(
        summaries: _summaries,
        selected: _selectedCourseId,
        onChanged: (v) => setState(() => _selectedCourseId = v),
      ),
      Expanded(child: _filtered.isEmpty
          ? _Empty(icon: Icons.event_note_rounded, message: 'No records for this filter.')
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _RecordTile(_filtered[i]),
      )),
    ]);
  }

  Color _pctColor(double pct) { if (pct >= 75) return AchivoColors.teal; if (pct >= 60) return AchivoColors.amber; return AchivoColors.red; }
  int   _classesNeeded(SubjectAttendance s) => ((0.75 * s.total - (s.present + s.late)) / 0.25).ceil().clamp(0, 9999);
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _OverallCard extends StatelessWidget {
  final double pct;
  const _OverallCard({required this.pct});

  @override
  Widget build(BuildContext context) {
    final ok = pct >= 75;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AchivoColors.cardBg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AchivoColors.border),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Overall Attendance', style: TextStyle(fontSize: 12, color: AchivoColors.textSecond)),
          const SizedBox(height: 4),
          Text('${pct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: ok ? AchivoColors.teal : AchivoColors.red)),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: pct / 100, minHeight: 6,
                  backgroundColor: const Color(0xFFF1EFE8), valueColor: AlwaysStoppedAnimation<Color>(ok ? AchivoColors.teal : AchivoColors.red))),
          const SizedBox(height: 6),
          Text(ok ? 'Meeting the 75% minimum requirement' : 'Below 75% minimum — needs improvement',
              style: TextStyle(fontSize: 11, color: ok ? AchivoColors.tealDark : AchivoColors.red)),
        ])),
      ]),
    );
  }
}

class _AttChip extends StatelessWidget {
  final IconData icon;
  final String   count, label;
  final Color    bg, fg;
  const _AttChip(this.icon, this.count, this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: fg),
        const SizedBox(width: 4),
        Text('$count $label', style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color  color;
  const _StatusChip(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final List<SubjectAttendance> summaries;
  final int?                    selected;
  final ValueChanged<int?>      onChanged;
  const _FilterBar({required this.summaries, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AchivoColors.cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: DropdownButtonFormField<int?>(
        value: selected,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.filter_list_rounded, size: 18, color: AchivoColors.textSecond),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AchivoColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AchivoColors.border)),
        ),
        hint: const Text('All Subjects', style: TextStyle(fontSize: 13)),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('All Subjects', style: TextStyle(fontSize: 13))),
          ...summaries.map((s) => DropdownMenuItem<int?>(value: s.courseId, child: Text(s.courseName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final AttendanceRecord r;
  const _RecordTile(this.r);

  @override
  Widget build(BuildContext context) {
    final (col, icon) = _style(r.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AchivoColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: col.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: col, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.courseName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AchivoColors.textPrimary)),
          if (r.facultyName != null) Text('by ${r.facultyName}', style: const TextStyle(fontSize: 11, color: AchivoColors.textSecond)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(DateFormat('dd MMM').format(r.date), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AchivoColors.textPrimary)),
          Text(DateFormat('yyyy').format(r.date), style: const TextStyle(fontSize: 11, color: AchivoColors.textSecond)),
        ]),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(r.status[0].toUpperCase() + r.status.substring(1), style: TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  (Color, IconData) _style(String s) {
    switch (s) {
      case 'present': return (AchivoColors.teal, Icons.check_circle_outline_rounded);
      case 'absent':  return (AchivoColors.red, Icons.cancel_outlined);
      case 'leave':   return (AchivoColors.amber, Icons.event_busy_rounded);
      case 'late':    return (AchivoColors.purpleDark, Icons.schedule_rounded);
      default:        return (AchivoColors.textHint, Icons.help_outline_rounded);
    }
  }
}

// ── Tab bar delegate ──────────────────────────────────────────────────────────

class _TabDelegate extends SliverPersistentHeaderDelegate {
  final TabController controller;
  const _TabDelegate(this.controller);

  @override
  Widget build(_, __, ___) => Container(
    color: AchivoColors.cardBg,
    child: TabBar(
      controller: controller,
      labelColor: AchivoColors.tealDark,
      unselectedLabelColor: AchivoColors.textSecond,
      indicatorColor: AchivoColors.teal,
      indicatorWeight: 2,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      dividerColor: AchivoColors.border,
      tabs: const [
        Tab(icon: Icon(Icons.bar_chart_rounded, size: 18), text: 'By Subject'),
        Tab(icon: Icon(Icons.list_alt_rounded, size: 18), text: 'Detailed'),
      ],
    ),
  );

  @override double get minExtent => 50;
  @override double get maxExtent => 50;
  @override bool shouldRebuild(_TabDelegate old) => old.controller != controller;
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  final IconData icon;
  final String   message;
  const _Empty({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 56, color: AchivoColors.textHint.withOpacity(0.4)),
        const SizedBox(height: 14),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AchivoColors.textSecond, fontSize: 14)),
      ]),
    ));
  }
}