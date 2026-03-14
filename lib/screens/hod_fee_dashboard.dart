// lib/screens/hod_fee_dashboard.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fee_models.dart';
import '../services/fee_service.dart';

class HodFeeDashboard extends StatefulWidget {
  final int departmentId;
  const HodFeeDashboard({super.key, required this.departmentId});

  @override
  State<HodFeeDashboard> createState() => _HodFeeDashboardState();
}

class _HodFeeDashboardState extends State<HodFeeDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  HodFeeSummary? _summary;
  List<StudentFee> _studentFees = [];

  String _academicYear =
      '${DateTime.now().year}-${(DateTime.now().year + 1).toString().substring(2)}';
  String _statusFilter = 'all';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      FeeService.getHodFeeSummary(
          departmentId: widget.departmentId, academicYear: _academicYear),
      FeeService.getDeptStudentFeeList(
          departmentId: widget.departmentId,
          academicYear: _academicYear,
          statusFilter: _statusFilter == 'all' ? null : _statusFilter),
    ]);
    if (!mounted) return;
    setState(() {
      _summary     = results[0] as HodFeeSummary?;
      _studentFees = results[1] as List<StudentFee>;
      _loading     = false;
    });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'paid':    return Colors.green;
      case 'partial': return Colors.orange;
      case 'overdue': return Colors.red;
      default:        return Colors.grey;
    }
  }

  String _fmt(double v) => '₹${NumberFormat('#,##,###').format(v)}';

  // ════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Department Fee Status'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart),  text: 'Summary'),
            Tab(icon: Icon(Icons.people),     text: 'Students'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tab,
        children: [
          _buildSummaryTab(),
          _buildStudentsTab(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // TAB 1 — SUMMARY
  // ─────────────────────────────────────────

  Widget _buildSummaryTab() {
    final s = _summary;
    if (s == null) {
      return _emptyState(Icons.bar_chart, 'No fee data for $_academicYear.');
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Year selector
          _yearSelector(),
          const SizedBox(height: 16),

          // Collection banner
          _collectionBanner(s),
          const SizedBox(height: 16),

          // Status breakdown
          _statusBreakdown(s),
          const SizedBox(height: 20),

          // Pending fee students quick list
          _pendingStudentsSection(),
        ],
      ),
    );
  }

  Widget _yearSelector() {
    return Row(children: [
      const Text('Academic Year:',
          style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(width: 10),
      DropdownButton<String>(
        value: _academicYear,
        underline: const SizedBox(),
        items: _academicYears().map((y) => DropdownMenuItem(
          value: y,
          child: Text(y, style: const TextStyle(fontWeight: FontWeight.w500)),
        )).toList(),
        onChanged: (v) {
          setState(() => _academicYear = v!);
          _load();
        },
      ),
    ]);
  }

  List<String> _academicYears() {
    final now = DateTime.now().year;
    return List.generate(4, (i) {
      final y = now - 1 + i;
      return '$y-${(y + 1).toString().substring(2)}';
    });
  }

  Widget _collectionBanner(HodFeeSummary s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade400]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Collected',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            Text('${s.totalStudents} students',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        Text(s.formattedCollected,
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('of ${s.formattedTotal}',
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: s.collectionRate,
            minHeight: 10,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(s.collectionRate * 100).toStringAsFixed(1)}% collected',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('Pending: ${s.formattedPending}',
                style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
          ],
        ),
      ]),
    );
  }

  Widget _statusBreakdown(HodFeeSummary s) {
    final segments = [
      ('Paid', s.paidCount, Colors.green),
      ('Partial', s.partialCount, Colors.orange),
      ('Unpaid / Overdue', s.unpaidCount, Colors.red),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Status Breakdown',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        ...segments.map((seg) => _statusRow(seg.$1, seg.$2, s.totalStudents, seg.$3)),
      ]),
    );
  }

  Widget _statusRow(String label, int count, int total, Color color) {
    final pct = total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text('$count students',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(width: 8),
          Text('${(pct * 100).toInt()}%',
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ]),
    );
  }

  Widget _pendingStudentsSection() {
    final pending = _studentFees
        .where((f) => f.isUnpaid || f.isPartial || f.isOverdue)
        .take(5)
        .toList();

    if (pending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200)),
        child: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 10),
          Text('All students have paid fees!',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
        ]),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Pending Fee Students',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Spacer(),
        TextButton(
          onPressed: () {
            setState(() => _statusFilter = 'partial');
            _tab.animateTo(1);
            _load();
          },
          child: const Text('View All'),
        ),
      ]),
      const SizedBox(height: 8),
      ...pending.map((f) => _pendingStudentCard(f)),
    ]);
  }

  Widget _pendingStudentCard(StudentFee f) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(f.paymentStatus).withOpacity(0.15),
          child: Icon(Icons.person, color: _statusColor(f.paymentStatus), size: 20),
        ),
        title: Text(f.feeStructure?.feeName ?? 'Fee', overflow: TextOverflow.ellipsis),
        subtitle: Text('Due: ${f.formattedDue}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _statusColor(f.paymentStatus).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _statusColor(f.paymentStatus)),
          ),
          child: Text(
            f.paymentStatus.toUpperCase(),
            style: TextStyle(
                color: _statusColor(f.paymentStatus),
                fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // TAB 2 — STUDENTS LIST
  // ─────────────────────────────────────────

  Widget _buildStudentsTab() {
    return Column(children: [
      // Filter bar
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', 'all'),
                  _filterChip('Paid', 'paid'),
                  _filterChip('Partial', 'partial'),
                  _filterChip('Unpaid', 'unpaid'),
                  _filterChip('Overdue', 'overdue'),
                ],
              ),
            ),
          ),
        ]),
      ),
      // Count
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(children: [
          Text('${_studentFees.length} student${_studentFees.length != 1 ? 's' : ''}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ]),
      ),
      Expanded(
        child: _studentFees.isEmpty
            ? _emptyState(Icons.people_outline, 'No students match this filter.')
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: _studentFees.length,
          itemBuilder: (_, i) => _studentFeeCard(_studentFees[i]),
        ),
      ),
    ]);
  }

  Widget _filterChip(String label, String value) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: Colors.deepPurple.shade100,
        onSelected: (_) {
          setState(() => _statusFilter = value);
          _load();
        },
      ),
    );
  }

  Widget _studentFeeCard(StudentFee f) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  f.feeStructure?.feeName ?? 'Fee',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(f.academicYear,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor(f.paymentStatus).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _statusColor(f.paymentStatus)),
              ),
              child: Text(
                f.paymentStatus.toUpperCase(),
                style: TextStyle(
                    color: _statusColor(f.paymentStatus),
                    fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: f.percentagePaid,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_statusColor(f.paymentStatus)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _feeLabel('Total', f.formattedTotal, Colors.grey),
              _feeLabel('Paid', f.formattedPaid, Colors.green),
              _feeLabel('Due', f.formattedDue,
                  f.amountDue > 0 ? Colors.red : Colors.grey),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _feeLabel(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
    ]);
  }

  Widget _emptyState(IconData icon, String msg) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(msg, style: TextStyle(color: Colors.grey.shade600)),
    ]));
  }
}