// lib/screens/admin_fee_management.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/fee_models.dart';
import '../services/fee_service.dart';

// Institute ID is resolved dynamically from the DB — no hardcoding needed.
// FeeService.createFeeStructure and getFeeStructures handle null instituteId.

class AdminFeeManagementPage extends StatefulWidget {
  const AdminFeeManagementPage({super.key});

  @override
  State<AdminFeeManagementPage> createState() => _AdminFeeManagementPageState();
}

class _AdminFeeManagementPageState extends State<AdminFeeManagementPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  AdminFeeStats? _stats;
  List<FeeStructure> _structures = [];
  List<Map<String, dynamic>> _pendingPayments = [];

  // Institute ID resolved once from DB — avoids hardcoding
  int? _resolvedInstituteId;

  String _filterYear = DateTime.now().year.toString();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  String get _academicYear {
    final y = int.tryParse(_filterYear) ?? DateTime.now().year;
    final next = (y + 1).toString().substring(2);
    return '$y-$next';
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // Resolve institute ID once (fetches from DB — no hardcoding)
    _resolvedInstituteId ??= await FeeService.resolveInstituteId();

    final results = await Future.wait([
      FeeService.getAdminFeeStats(
          instituteId: _resolvedInstituteId, academicYear: _academicYear),
      FeeService.getFeeStructures(
          instituteId: _resolvedInstituteId, academicYear: _academicYear),
      FeeService.getPendingPayments(),
    ]);
    if (!mounted) return;
    setState(() {
      _stats           = results[0] as AdminFeeStats?;
      _structures      = results[1] as List<FeeStructure>;
      _pendingPayments = results[2] as List<Map<String, dynamic>>;
      _loading         = false;
    });
  }

  // ════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Fee Management'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: _exportCSV,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            const Tab(icon: Icon(Icons.bar_chart), text: 'Overview'),
            const Tab(icon: Icon(Icons.list_alt),  text: 'Structures'),
            Tab(
              icon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.verified_user),
                if (_pendingPayments.isNotEmpty)
                  Positioned(
                    right: -6, top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: Text('${_pendingPayments.length}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ]),
              text: 'Verify',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateStructureDialog,
        backgroundColor: Colors.teal.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Fee', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tab,
        children: [
          _buildOverviewTab(),
          _buildStructuresTab(),
          _buildVerifyTab(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // TAB 1 — OVERVIEW
  // ─────────────────────────────────────────

  Widget _buildOverviewTab() {
    final s = _stats;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Collection rate card
          if (s != null) ...[
            _collectionRateCard(s),
            const SizedBox(height: 16),

            // Mini stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _miniStat('Paid', s.paidCount, Colors.green, Icons.check_circle),
                _miniStat('Partial', s.partialCount, Colors.orange, Icons.timelapse),
                _miniStat('Unpaid', s.unpaidCount, Colors.red, Icons.cancel),
                _miniStat('Overdue', s.overdueCount, Colors.deepOrange, Icons.warning),
              ],
            ),

            // Pending verifications alert
            if (s.pendingVerifications > 0) ...[
              const SizedBox(height: 16),
              _pendingAlert(s.pendingVerifications),
            ],
          ],
        ],
      ),
    );
  }

  Widget _collectionRateCard(AdminFeeStats s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.teal.shade700, Colors.teal.shade400]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Fee Collection Status',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.formattedCollected,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 26,
                      fontWeight: FontWeight.bold)),
              Text('of ${s.formattedTotal}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
            Text('${(s.collectionRate * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                    color: Colors.white, fontSize: 36,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: s.collectionRate,
            minHeight: 8,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pending: ${s.formattedPending}  •  ${s.totalStudents} students',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ]),
    );
  }

  Widget _miniStat(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 6)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text('$count',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _pendingAlert(int count) {
    return InkWell(
      onTap: () => _tab.animateTo(2),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(children: [
          const Icon(Icons.pending_actions, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count payment${count > 1 ? 's' : ''} awaiting verification',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.orange),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────
  // TAB 2 — FEE STRUCTURES
  // ─────────────────────────────────────────

  Widget _buildStructuresTab() {
    if (_structures.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.list_alt, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No fee structures for $_academicYear.',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _showCreateStructureDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create First Structure'),
          ),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _structures.length,
      itemBuilder: (_, i) => _structureCard(_structures[i]),
    );
  }

  Widget _structureCard(FeeStructure fs) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(fs.feeName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: fs.isActive ? Colors.green.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: fs.isActive ? Colors.green : Colors.grey)),
              child: Text(
                fs.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                    color: fs.isActive ? Colors.green : Colors.grey,
                    fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: [
            _chip('Year ${fs.studentYear}', Colors.blue),
            _chip(fs.academicYear, Colors.teal),
            _chip('${fs.installmentCount} installment${fs.installmentCount > 1 ? 's' : ''}', Colors.purple),
            _chip(fs.formattedAmount, Colors.green),
          ]),
          if (fs.installments.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Installments',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            ...fs.installments.map((inst) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Icon(Icons.circle, size: 6, color: Colors.teal.shade400),
                const SizedBox(width: 8),
                Expanded(child: Text(inst.label, style: const TextStyle(fontSize: 13))),
                Text(inst.formattedAmount,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(width: 8),
                Text('Due: ${inst.formattedDueDate}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ]),
            )),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _assignFees(fs),
              icon: const Icon(Icons.group_add, size: 18),
              label: const Text('Assign to Matching Students'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _assignFees(FeeStructure fs) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Assign Fee to Students'),
        content: Text(
            'Assign "${fs.feeName}" to all matching students?\n\n'
                'Year: ${fs.studentYear}  •  Dept: ${fs.departmentId == null ? 'All' : '#${fs.departmentId}'}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Assign')),
        ],
      ),
    );
    if (confirmed != true) return;

    final res = await FeeService.assignFeesToStudents(fs.id);
    if (!mounted) return;
    _snack(
      res.success
          ? 'Assigned to ${res.assigned} students (${res.skipped} skipped)'
          : 'Error: ${res.error}',
      res.success ? Colors.green : Colors.red,
    );
    if (res.success) _load();
  }

  // ─────────────────────────────────────────
  // TAB 3 — VERIFY PAYMENTS
  // ─────────────────────────────────────────

  Widget _buildVerifyTab() {
    if (_pendingPayments.isEmpty) {
      return _emptyState(Icons.verified_user_outlined, 'No payments pending verification.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingPayments.length,
      itemBuilder: (_, i) => _verifyCard(_pendingPayments[i]),
    );
  }

  Widget _verifyCard(Map<String, dynamic> p) {
    final student   = p['students'] as Map<String, dynamic>? ?? {};
    final dept      = (student['departments'] as Map?)  ?? {};
    final name      = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim();
    final roll      = student['roll_number'] ?? 'N/A';
    final amount    = (p['amount'] as num? ?? 0).toDouble();
    final method    = p['payment_method'] ?? '';
    final proofUrl  = p['proof_url'] as String?;
    final date      = p['payment_date'] != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(p['payment_date']))
        : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: Colors.teal.shade100,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('$roll  •  ${dept['name'] ?? ''}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ]),
            ),
            Text(
              '₹${NumberFormat('#,##,###').format(amount)}',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: [
            _chip(method.toUpperCase(), Colors.indigo),
            _chip('Date: $date', Colors.grey),
          ]),
          if (proofUrl != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _openProof(proofUrl),
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
              label: const Text('View Proof',
                  style: TextStyle(color: Colors.deepOrange)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.deepOrange),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
            ),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _verify(p['id'] as int, false),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _verify(p['id'] as int, true),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Future<void> _openProof(String storagePath) async {
    final url = await FeeService.getProofSignedUrl(storagePath);
    if (url == null) { _snack('Could not load proof', Colors.red); return; }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _verify(int paymentId, bool approve) async {
    final remarksCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(approve ? 'Approve Payment' : 'Reject Payment'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(approve
              ? 'Approve this payment and generate receipt?'
              : 'Reject this payment?'),
          const SizedBox(height: 12),
          TextField(
            controller: remarksCtrl,
            decoration: const InputDecoration(
                labelText: 'Remarks (optional)', border: OutlineInputBorder()),
            maxLines: 2,
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: approve ? Colors.green : Colors.red,
                foregroundColor: Colors.white),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final res = await FeeService.verifyPayment(
        paymentId: paymentId, approved: approve,
        remarks: remarksCtrl.text.trim().isEmpty ? null : remarksCtrl.text.trim());
    if (!mounted) return;

    _snack(
      res.success
          ? (approve
          ? 'Payment approved! Receipt: ${res.receiptNo}'
          : 'Payment rejected.')
          : 'Error: ${res.error}',
      res.success ? Colors.green : Colors.red,
    );
    if (res.success) _load();
  }

  // ─────────────────────────────────────────
  // CREATE FEE STRUCTURE DIALOG
  // ─────────────────────────────────────────

  void _showCreateStructureDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateFeeStructureDialog(
        instituteId: _resolvedInstituteId,  // null = auto-resolved by FeeService
        onCreated: _load,
      ),
    );
  }

  // ─────────────────────────────────────────
  // EXPORT CSV
  // ─────────────────────────────────────────

  Future<void> _exportCSV() async {
    final data = await FeeService.exportFeeData(academicYear: _academicYear);
    if (data.isEmpty) { _snack('No data to export', Colors.orange); return; }

    // Build CSV string
    final headers = data.first.keys.join(',');
    final rows = data.map((r) => r.values.map((v) => '"$v"').join(',')).join('\n');
    final csv = '$headers\n$rows';

    // On mobile: share via share_plus, on web: trigger download
    // For brevity we just notify — integrate share_plus in production
    _snack('CSV ready: ${data.length} rows (${csv.length ~/ 1024} KB)', Colors.green);
  }

  Widget _emptyState(IconData icon, String msg) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(msg, style: TextStyle(color: Colors.grey.shade600)),
    ]));
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color,
          behavior: SnackBarBehavior.floating),
    );
  }
}

// ═════════════════════════════════════════════════
// CREATE FEE STRUCTURE DIALOG
// ═════════════════════════════════════════════════

class _CreateFeeStructureDialog extends StatefulWidget {
  final int? instituteId;       // nullable — FeeService resolves from DB if null
  final VoidCallback onCreated;
  const _CreateFeeStructureDialog({
    required this.instituteId,
    required this.onCreated,
  });

  @override
  State<_CreateFeeStructureDialog> createState() =>
      _CreateFeeStructureDialogState();
}

class _CreateFeeStructureDialogState extends State<_CreateFeeStructureDialog> {
  final _nameCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _year  = 'I';
  String _acYear = '${DateTime.now().year}-${(DateTime.now().year + 1).toString().substring(2)}';
  int    _instCount = 1;
  bool   _saving = false;

  // Dynamically built installment date pickers
  final List<TextEditingController> _labelCtrl = [];
  final List<DateTime?> _dueDates = [];

  @override
  void initState() {
    super.initState();
    _rebuildInstallments(1);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    for (final c in _labelCtrl) c.dispose();
    super.dispose();
  }

  void _rebuildInstallments(int count) {
    _labelCtrl.clear();
    _dueDates.clear();
    for (int i = 0; i < count; i++) {
      _labelCtrl.add(TextEditingController(
          text: count == 1 ? 'Full Payment' : 'Installment ${i + 1}'));
      _dueDates.add(null);
    }
    setState(() => _instCount = count);
  }

  double get _totalAmount {
    final v = double.tryParse(_amountCtrl.text.trim());
    return v ?? 0;
  }

  double _instAmount(int idx) {
    if (_totalAmount == 0) return 0;
    // Split evenly; last installment absorbs rounding diff
    final base = (_totalAmount / _instCount * 100).round() / 100;
    if (idx == _instCount - 1) {
      return _totalAmount - base * (_instCount - 1);
    }
    return base;
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _amountCtrl.text.trim().isEmpty) {
      _snack('Fill in all fields', Colors.orange);
      return;
    }
    if (_dueDates.any((d) => d == null)) {
      _snack('Set all due dates', Colors.orange);
      return;
    }
    setState(() => _saving = true);

    final installments = List.generate(_instCount, (i) => (
    amount:   _instAmount(i),
    dueDate:  _dueDates[i]!,
    label:    _labelCtrl[i].text.trim().isEmpty
        ? 'Installment ${i + 1}'
        : _labelCtrl[i].text.trim(),
    ));

    final res = await FeeService.createFeeStructure(
      instituteId: widget.instituteId,
      academicYear: _acYear,
      studentYear: _year,
      feeName: _nameCtrl.text.trim(),
      totalAmount: _totalAmount,
      installments: installments,
    );

    setState(() => _saving = false);
    if (!mounted) return;

    if (res.success) {
      Navigator.pop(context);
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Fee structure created successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      _snack('Error: ${res.error}', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.add_box, color: Colors.teal),
        SizedBox(width: 8),
        Text('New Fee Structure'),
      ]),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Fee Name *',
                  hintText: 'e.g. Annual Tuition Fee 2024-25',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Total Amount (₹) *',
                  border: OutlineInputBorder(),
                  prefixText: '₹ '),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Academic year + student year row
            Row(children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _acYear = v),
                  decoration: InputDecoration(
                    labelText: 'Academic Year',
                    border: const OutlineInputBorder(),
                    hintText: _acYear,
                  ),
                  controller: TextEditingController(text: _acYear),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _year,
                  decoration: const InputDecoration(
                      labelText: 'Student Year',
                      border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All Years')),
                    DropdownMenuItem(value: 'I',   child: Text('1st Year')),
                    DropdownMenuItem(value: 'II',  child: Text('2nd Year')),
                    DropdownMenuItem(value: 'III', child: Text('3rd Year')),
                    DropdownMenuItem(value: 'IV',  child: Text('4th Year')),
                    DropdownMenuItem(value: 'V',   child: Text('5th Year')),
                  ],
                  onChanged: (v) => setState(() => _year = v!),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // Installment count
            DropdownButtonFormField<int>(
              value: _instCount,
              decoration: const InputDecoration(
                  labelText: 'Installment Count',
                  border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 (Full payment)')),
                DropdownMenuItem(value: 2, child: Text('2 (Half-yearly)')),
                DropdownMenuItem(value: 4, child: Text('4 (Quarterly)')),
              ],
              onChanged: (v) => _rebuildInstallments(v!),
            ),
            const SizedBox(height: 16),

            // Per-installment rows
            ...List.generate(_instCount, (i) => _installmentInput(i)),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white),
          child: _saving
              ? const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
              : const Text('Create'),
        ),
      ],
    );
  }

  Widget _installmentInput(int i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _labelCtrl[i],
              decoration: InputDecoration(
                  labelText: 'Label',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  hintText: 'Installment ${i + 1}'),
            ),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('Amount', style: TextStyle(fontSize: 11, color: Colors.grey)),
            Text(
              '₹${NumberFormat('#,##,###.##').format(_instAmount(i))}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ]),
        ]),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 730)),
            );
            if (picked != null) setState(() => _dueDates[i] = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                  color: _dueDates[i] == null
                      ? Colors.grey.shade300
                      : Colors.teal),
              borderRadius: BorderRadius.circular(8),
              color: _dueDates[i] != null
                  ? Colors.teal.shade50
                  : Colors.white,
            ),
            child: Row(children: [
              Icon(Icons.calendar_today,
                  size: 16,
                  color: _dueDates[i] != null ? Colors.teal : Colors.grey),
              const SizedBox(width: 8),
              Text(
                _dueDates[i] != null
                    ? DateFormat('dd MMM yyyy').format(_dueDates[i]!)
                    : 'Pick due date',
                style: TextStyle(
                    color: _dueDates[i] != null
                        ? Colors.teal.shade700
                        : Colors.grey),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}