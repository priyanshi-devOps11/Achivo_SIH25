// lib/screens/student_fee_dashboard.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/fee_models.dart';
import '../services/fee_service.dart';

class StudentFeeDashboard extends StatefulWidget {
  final String studentId;
  const StudentFeeDashboard({super.key, required this.studentId});

  @override
  State<StudentFeeDashboard> createState() => _StudentFeeDashboardState();
}

class _StudentFeeDashboardState extends State<StudentFeeDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  List<StudentFee>    _fees     = [];
  List<FeePayment>    _payments = [];
  List<PaymentReceipt>_receipts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      FeeService.getStudentFees(widget.studentId),
      FeeService.getStudentPaymentHistory(widget.studentId),
      FeeService.getStudentReceipts(widget.studentId),
    ]);
    if (!mounted) return;
    setState(() {
      _fees     = results[0] as List<StudentFee>;
      _payments = results[1] as List<FeePayment>;
      _receipts = results[2] as List<PaymentReceipt>;
      _loading  = false;
    });
  }

  // ── helpers ──────────────────────────────────────────

  Color _statusColor(String s) {
    switch (s) {
      case 'paid':    return Colors.green;
      case 'partial': return Colors.orange;
      case 'overdue': return Colors.red;
      default:        return Colors.grey;
    }
  }

  String _statusLabel(String s) =>
      s[0].toUpperCase() + s.substring(1);

  // ════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Fees'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'My Fees'),
            Tab(icon: Icon(Icons.history),                text: 'History'),
            Tab(icon: Icon(Icons.receipt_long),           text: 'Receipts'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tab,
        children: [
          _buildFeesTab(),
          _buildHistoryTab(),
          _buildReceiptsTab(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // TAB 1 — MY FEES
  // ─────────────────────────────────────────

  Widget _buildFeesTab() {
    if (_fees.isEmpty) {
      return _emptyState(Icons.account_balance_wallet_outlined,
          'No fee records assigned yet.');
    }

    // Summary totals
    double total = 0, paid = 0, due = 0;
    for (final f in _fees) { total += f.totalAmount; paid += f.amountPaid; due += f.amountDue; }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary row
          _summaryRow(total, paid, due),
          const SizedBox(height: 20),
          ..._fees.map((f) => _feeCard(f)),
        ],
      ),
    );
  }

  Widget _summaryRow(double total, double paid, double due) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo.shade700, Colors.indigo.shade400]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryChip('Total', total, Colors.white),
          _summaryChip('Paid', paid, Colors.greenAccent),
          _summaryChip('Balance', due, Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, double amount, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      const SizedBox(height: 4),
      Text(
        '₹${NumberFormat('#,##,###').format(amount)}',
        style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.bold),
      ),
    ]);
  }

  Widget _feeCard(StudentFee fee) {
    final fs = fee.feeStructure;
    final installments = fs?.installments ?? [];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Title + status
          Row(children: [
            Expanded(
              child: Text(
                fs?.feeName ?? 'Fee — ${fee.academicYear}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(fee.paymentStatus).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _statusColor(fee.paymentStatus)),
              ),
              child: Text(
                _statusLabel(fee.paymentStatus),
                style: TextStyle(
                    color: _statusColor(fee.paymentStatus),
                    fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fee.percentagePaid,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                  _statusColor(fee.paymentStatus)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Paid: ${fee.formattedPaid}',
                  style: const TextStyle(fontSize: 12, color: Colors.green)),
              Text('Due: ${fee.formattedDue}',
                  style: TextStyle(
                      fontSize: 12,
                      color: fee.amountDue > 0 ? Colors.red : Colors.grey)),
            ],
          ),

          // Installments
          if (installments.isNotEmpty) ...[
            const Divider(height: 20),
            const Text('Installment Schedule',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            ...installments.map((inst) => _installmentRow(inst)),
          ],

          // Pay Now button
          if (fee.amountDue > 0) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openPaymentSheet(fee),
                icon: const Icon(Icons.payment, size: 18),
                label: const Text('Pay Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _installmentRow(FeeInstallment inst) {
    final overdue = inst.isOverdue;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: overdue ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: overdue ? Colors.red.shade200 : Colors.grey.shade200),
      ),
      child: Row(children: [
        Icon(overdue ? Icons.warning_rounded : Icons.calendar_today,
            size: 16, color: overdue ? Colors.red : Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(inst.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Text(inst.formattedAmount,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: overdue ? Colors.red : Colors.black87)),
        const SizedBox(width: 8),
        Text('Due: ${inst.formattedDueDate}',
            style: TextStyle(
                fontSize: 11,
                color: overdue ? Colors.red : Colors.grey)),
      ]),
    );
  }

  // ─────────────────────────────────────────
  // TAB 2 — HISTORY
  // ─────────────────────────────────────────

  Widget _buildHistoryTab() {
    if (_payments.isEmpty) {
      return _emptyState(Icons.history, 'No payments recorded yet.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      itemBuilder: (_, i) => _paymentHistoryCard(_payments[i]),
    );
  }

  Widget _paymentHistoryCard(FeePayment p) {
    Color statusColor;
    IconData statusIcon;
    switch (p.status) {
      case 'verified': statusColor = Colors.green; statusIcon = Icons.check_circle; break;
      case 'failed':   statusColor = Colors.red;   statusIcon = Icons.cancel;       break;
      default:         statusColor = Colors.orange; statusIcon = Icons.schedule;
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.12),
          child: Icon(statusIcon, color: statusColor, size: 22),
        ),
        title: Text(p.formattedAmount,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(
            '${p.displayMethod} • ${p.formattedDate}'
                '${p.installmentLabel != null ? ' • ${p.installmentLabel}' : ''}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(p.status.toUpperCase(),
                  style: TextStyle(
                      color: statusColor, fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // TAB 3 — RECEIPTS
  // ─────────────────────────────────────────

  Widget _buildReceiptsTab() {
    if (_receipts.isEmpty) {
      return _emptyState(Icons.receipt_long_outlined, 'No receipts yet.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _receipts.length,
      itemBuilder: (_, i) => _receiptCard(_receipts[i]),
    );
  }

  Widget _receiptCard(PaymentReceipt r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.receipt, color: Colors.indigo),
            const SizedBox(width: 8),
            Expanded(
              child: Text(r.receiptNumber,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            Text(r.formattedDate,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ]),
          const Divider(height: 16),
          _receiptRow('Amount Paid', r.formattedAmountPaid),
          _receiptRow('Remaining', r.formattedRemaining),
          _receiptRow('Method', r.paymentMethod.toUpperCase()),
          if (r.transactionId != null)
            _receiptRow('Txn ID', r.transactionId!),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showReceiptDialog(r),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo,
                    side: const BorderSide(color: Colors.indigo)),
              ),
            ),
            if (r.receiptPdfUrl != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _downloadReceipt(r.receiptPdfUrl!),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade700,
                      foregroundColor: Colors.white),
                ),
              ),
            ],
          ]),
        ]),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  void _showReceiptDialog(PaymentReceipt r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          const Icon(Icons.receipt_long, color: Colors.indigo),
          const SizedBox(width: 8),
          Text(r.receiptNumber,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _receiptRow('Student', r.studentName),
            _receiptRow('Roll No', r.rollNumber),
            _receiptRow('Department', r.departmentName),
            _receiptRow('Academic Year', r.academicYear),
            _receiptRow('Fee', r.feeStructureName),
            if (r.installmentLabel != null)
              _receiptRow('Installment', r.installmentLabel!),
            const Divider(),
            _receiptRow('Total Fee', r.formattedTotalFee),
            _receiptRow('Paid Before', '₹${NumberFormat('#,##,###').format(r.amountPaidBefore)}'),
            _receiptRow('This Payment', r.formattedAmountPaid),
            _receiptRow('Remaining', r.formattedRemaining),
            const Divider(),
            _receiptRow('Method', r.paymentMethod.toUpperCase()),
            if (r.transactionId != null) _receiptRow('Txn ID', r.transactionId!),
            _receiptRow('Date', r.formattedDate),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _downloadReceipt(String storagePath) async {
    final url = await FeeService.getReceiptSignedUrl(storagePath);
    if (url == null) {
      _snack('Could not load receipt URL', Colors.red);
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─────────────────────────────────────────
  // PAYMENT BOTTOM SHEET
  // ─────────────────────────────────────────

  void _openPaymentSheet(StudentFee fee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentSheet(
        fee: fee,
        onSuccess: _load,
      ),
    );
  }

  // ─────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────

  Widget _emptyState(IconData icon, String msg) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(msg, style: TextStyle(color: Colors.grey.shade600)),
      ]),
    );
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
// PAYMENT SHEET
// ═════════════════════════════════════════════════

class _PaymentSheet extends StatefulWidget {
  final StudentFee fee;
  final VoidCallback onSuccess;
  const _PaymentSheet({required this.fee, required this.onSuccess});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  FeeInstallment? _selectedInstallment;
  String _method = 'upi';
  final _txnCtrl  = TextEditingController();
  final _bankCtrl = TextEditingController();
  PlatformFile? _proofFile;
  bool _submitting = false;

  static const _methods = [
    ('upi', 'UPI'),
    ('net_banking', 'Net Banking'),
    ('debit_card', 'Debit Card'),
    ('credit_card', 'Credit Card'),
    ('neft', 'NEFT'),
    ('rtgs', 'RTGS'),
    ('cash', 'Cash'),
    ('dd', 'DD'),
    ('cheque', 'Cheque'),
  ];

  List<FeeInstallment> get _pendingInst =>
      (widget.fee.feeStructure?.installments ?? []);

  @override
  void initState() {
    super.initState();
    if (_pendingInst.length == 1) _selectedInstallment = _pendingInst.first;
  }

  @override
  void dispose() {
    _txnCtrl.dispose();
    _bankCtrl.dispose();
    super.dispose();
  }

  double get _payAmount =>
      _selectedInstallment?.amount ?? widget.fee.amountDue;

  Future<void> _pickProof() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _proofFile = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (_proofFile == null || _proofFile!.bytes == null) {
      _snack('Please attach payment proof', Colors.orange);
      return;
    }
    setState(() => _submitting = true);

    final res = await FeeService.submitPaymentWithProof(
      studentFeeId: widget.fee.id,
      installmentId: _selectedInstallment?.id,
      paymentMethod: _method,
      amount: _payAmount,
      transactionRef: _txnCtrl.text.trim().isEmpty ? null : _txnCtrl.text.trim(),
      bankName: _bankCtrl.text.trim().isEmpty ? null : _bankCtrl.text.trim(),
      proofBytes: _proofFile!.bytes!,
      proofFileName: _proofFile!.name,
    );

    setState(() => _submitting = false);
    if (!mounted) return;

    if (res.success) {
      Navigator.pop(context);
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Payment submitted! Awaiting admin verification.'),
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
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Make Payment',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(
              widget.fee.feeStructure?.feeName ?? 'Fee Payment',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Installment picker (if multiple)
            if (_pendingInst.length > 1) ...[
              const Text('Select Installment',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _pendingInst.map((inst) {
                  final sel = _selectedInstallment?.id == inst.id;
                  return ChoiceChip(
                    label: Text('${inst.label}\n${inst.formattedAmount}'),
                    selected: sel,
                    selectedColor: Colors.indigo.shade100,
                    onSelected: (_) => setState(() => _selectedInstallment = inst),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Amount display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Amount to Pay',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '₹${NumberFormat('#,##,###.##').format(_payAmount)}',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment method chips
            const Text('Payment Method',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _methods.map((m) {
                final sel = _method == m.$1;
                return ChoiceChip(
                  label: Text(m.$2),
                  selected: sel,
                  selectedColor: Colors.indigo.shade100,
                  onSelected: (_) => setState(() => _method = m.$1),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Transaction ref
            TextField(
              controller: _txnCtrl,
              decoration: InputDecoration(
                labelText: 'Transaction Reference / Cheque No. (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 12),

            // Bank name
            TextField(
              controller: _bankCtrl,
              decoration: InputDecoration(
                labelText: 'Bank Name (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.account_balance),
              ),
            ),
            const SizedBox(height: 16),

            // Proof upload
            const Text('Payment Proof *',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickProof,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: _proofFile != null
                          ? Colors.green
                          : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                  color: _proofFile != null
                      ? Colors.green.shade50
                      : Colors.grey.shade50,
                ),
                child: Row(children: [
                  Icon(
                    _proofFile != null
                        ? Icons.check_circle
                        : Icons.upload_file,
                    color: _proofFile != null ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _proofFile != null
                          ? _proofFile!.name
                          : 'Tap to upload PDF / image',
                      style: TextStyle(
                          color: _proofFile != null
                              ? Colors.green.shade700
                              : Colors.grey),
                    ),
                  ),
                  if (_proofFile != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _proofFile = null),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
                label: Text(_submitting ? 'Submitting…' : 'Submit Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}