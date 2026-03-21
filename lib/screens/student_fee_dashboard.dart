// lib/screens/student_fee_dashboard.dart  (PayU version)
// ══════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/fee_models.dart';
import '../services/fee_service.dart';
import '../services/payu_service.dart';

class StudentFeeDashboard extends StatefulWidget {
  final String studentId;
  const StudentFeeDashboard({super.key, required this.studentId});

  @override
  State<StudentFeeDashboard> createState() => _StudentFeeDashboardState();
}

class _StudentFeeDashboardState extends State<StudentFeeDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  List<StudentFee>     _fees     = [];
  List<FeePayment>     _payments = [];
  List<PaymentReceipt> _receipts = [];
  bool _loading = true;

  // Student profile for PayU prefill
  String _studentName  = '';
  String _studentEmail = '';
  String _studentPhone = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
    _loadStudentProfile();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

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

  Future<void> _loadStudentProfile() async {
    try {
      final db     = PayUService.supabaseClient;
      final authUid = db.auth.currentUser?.id;
      if (authUid == null) return;
      final row = await db
          .from('students')
          .select('first_name, last_name, email, phone')
          .eq('user_id', authUid)
          .maybeSingle();
      if (row != null && mounted) {
        setState(() {
          _studentName  =
              '${row['first_name'] ?? ''} ${row['last_name'] ?? ''}'.trim();
          _studentEmail = row['email'] ?? '';
          _studentPhone = row['phone'] ?? '';
        });
      }
    } catch (_) {}
  }

  // ── Helpers ───────────────────────────────────────────────────────

  Color _statusColor(String s) {
    switch (s) {
      case 'paid':    return Colors.green;
      case 'partial': return Colors.orange;
      case 'overdue': return Colors.red;
      default:        return Colors.grey;
    }
  }

  String _statusLabel(String s) => s[0].toUpperCase() + s.substring(1);

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ═════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Fees'),
        backgroundColor: Colors.indigo.shade700,
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
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 60),
            Icon(Icons.account_balance_wallet_outlined,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text('No fees assigned yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 10),
            Text(
              'Your fees will appear here once the admin assigns them.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            Center(
              child: OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ),
          ],
        ),
      );
    }

    double total = 0, paid = 0, due = 0;
    for (final f in _fees) {
      total += f.totalAmount;
      paid  += f.amountPaid;
      due   += f.amountDue;
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryBanner(total, paid, due),
          const SizedBox(height: 20),
          ..._fees.map((f) => _feeCard(f)),
        ],
      ),
    );
  }

  Widget _summaryBanner(double total, double paid, double due) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.indigo.shade800, Colors.indigo.shade500]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _bannerChip('Total',   total, Colors.white),
          Container(width: 1, height: 40, color: Colors.white24),
          _bannerChip('Paid',    paid,  Colors.greenAccent),
          Container(width: 1, height: 40, color: Colors.white24),
          _bannerChip('Balance', due,   Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _bannerChip(String label, double amount, Color color) {
    return Column(children: [
      Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 11)),
      const SizedBox(height: 4),
      Text(
        '₹${NumberFormat('#,##,###').format(amount)}',
        style: TextStyle(
            color: color, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ]);
  }

  Widget _feeCard(StudentFee fee) {
    final fs           = fee.feeStructure;
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
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            _statusBadge(fee.paymentStatus),
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
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Paid: ${fee.formattedPaid}',
                style: const TextStyle(fontSize: 12, color: Colors.green)),
            Text('Due: ${fee.formattedDue}',
                style: TextStyle(
                    fontSize: 12,
                    color: fee.amountDue > 0 ? Colors.red : Colors.grey)),
          ]),

          // Installment schedule
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
                label: const Text('Pay Now via PayU'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],

          // Fully paid banner
          if (fee.amountDue <= 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(children: [
                Icon(Icons.check_circle, color: Colors.green, size: 18),
                SizedBox(width: 8),
                Text('Fully Paid',
                    style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(_statusLabel(status),
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
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
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
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
      itemBuilder: (_, i) => _paymentCard(_payments[i]),
    );
  }

  Widget _paymentCard(FeePayment p) {
    Color statusColor;
    IconData statusIcon;
    switch (p.status) {
      case 'verified':
        statusColor = Colors.green; statusIcon = Icons.check_circle; break;
      case 'failed':
        statusColor = Colors.red;   statusIcon = Icons.cancel;       break;
      default:
        statusColor = Colors.orange; statusIcon = Icons.schedule;
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
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor),
          ),
          child: Text(p.status.toUpperCase(),
              style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
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
          _receiptRow('Remaining',   r.formattedRemaining),
          _receiptRow('Method',      r.paymentMethod.toUpperCase()),
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
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
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
          Expanded(
            child: Text(r.receiptNumber,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ]),
        content: SingleChildScrollView(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _receiptRow('Student',       r.studentName),
                _receiptRow('Roll No',       r.rollNumber),
                _receiptRow('Department',    r.departmentName),
                _receiptRow('Academic Year', r.academicYear),
                _receiptRow('Fee',           r.feeStructureName),
                if (r.installmentLabel != null)
                  _receiptRow('Installment', r.installmentLabel!),
                const Divider(),
                _receiptRow('Total Fee',     r.formattedTotalFee),
                _receiptRow('Paid Before',
                    '₹${NumberFormat('#,##,###').format(r.amountPaidBefore)}'),
                _receiptRow('This Payment',  r.formattedAmountPaid),
                _receiptRow('Remaining',     r.formattedRemaining),
                const Divider(),
                _receiptRow('Method', r.paymentMethod.toUpperCase()),
                if (r.transactionId != null)
                  _receiptRow('Txn ID', r.transactionId!),
                _receiptRow('Date', r.formattedDate),
              ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _downloadReceipt(String storagePath) async {
    final url = await FeeService.getReceiptSignedUrl(storagePath);
    if (url == null) { _snack('Could not load receipt', Colors.red); return; }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Open PayU Payment Sheet ───────────────────────────────────────

  void _openPaymentSheet(StudentFee fee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PayUPaymentSheet(
        fee:          fee,
        studentName:  _studentName,
        studentEmail: _studentEmail,
        studentPhone: _studentPhone,
        onSuccess:    _load,
      ),
    );
  }

  Widget _emptyState(IconData icon, String msg) {
    return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(msg, style: TextStyle(color: Colors.grey.shade600)),
    ]));
  }
}

// ═════════════════════════════════════════════════════════════════════
// PAYU PAYMENT BOTTOM SHEET
// ═════════════════════════════════════════════════════════════════════

class _PayUPaymentSheet extends StatefulWidget {
  final StudentFee   fee;
  final String       studentName;
  final String       studentEmail;
  final String       studentPhone;
  final VoidCallback onSuccess;

  const _PayUPaymentSheet({
    required this.fee,
    required this.studentName,
    required this.studentEmail,
    required this.studentPhone,
    required this.onSuccess,
  });

  @override
  State<_PayUPaymentSheet> createState() => _PayUPaymentSheetState();
}

class _PayUPaymentSheetState extends State<_PayUPaymentSheet> {
  FeeInstallment? _selectedInstallment;
  bool    _processing    = false;
  String? _errorMessage;
  String? _successMessage;

  late final PayUService _payU;

  List<FeeInstallment> get _installments =>
      widget.fee.feeStructure?.installments ?? [];

  @override
  void initState() {
    super.initState();
    _payU = PayUService();
    if (_installments.length == 1) {
      _selectedInstallment = _installments.first;
    }
  }

  double get _payAmount =>
      _selectedInstallment?.amount ?? widget.fee.amountDue;

  Future<void> _startPayment() async {
    if (_processing) return;
    setState(() { _processing = true; _errorMessage = null; });

    await _payU.startPayment(
      context:      context,
      studentFee:   widget.fee,
      amount:       _payAmount,
      installmentId: _selectedInstallment?.id,
      studentName:  widget.studentName.isNotEmpty
          ? widget.studentName : 'Student',
      studentEmail: widget.studentEmail,
      studentPhone: widget.studentPhone,
      onResult: (result) {
        if (!mounted) return;
        setState(() => _processing = false);

        if (result.success) {
          setState(() => _successMessage =
          'Payment Successful!\nReceipt: ${result.receiptNo ?? result.txnId}');
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
            widget.onSuccess();
          });
        } else {
          setState(() => _errorMessage = result.error);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize:     0.92,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Drag handle
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                )),
                const SizedBox(height: 20),

                // Header
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.payment,
                        color: Colors.indigo.shade700, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Secure Payment',
                              style: TextStyle(
                                  fontSize: 19, fontWeight: FontWeight.bold)),
                          Text(
                            widget.fee.feeStructure?.feeName ?? 'Fee Payment',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ]),
                  ),
                ]),
                const SizedBox(height: 22),

                // Installment picker
                if (_installments.length > 1) ...[
                  Text('Choose Installment',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _installments.map((inst) {
                      final sel = _selectedInstallment?.id == inst.id;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedInstallment = inst),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? Colors.indigo.shade700
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel
                                  ? Colors.indigo.shade700
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(inst.label,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: sel
                                            ? Colors.white70
                                            : Colors.grey.shade600)),
                                const SizedBox(height: 2),
                                Text(inst.formattedAmount,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: sel
                                            ? Colors.white
                                            : Colors.indigo.shade700)),
                                Text('Due: ${inst.formattedDueDate}',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: sel
                                            ? Colors.white60
                                            : Colors.grey)),
                              ]),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                ],

                // Amount card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [
                          Colors.indigo.shade800,
                          Colors.indigo.shade500,
                        ]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(children: [
                    const Text('Amount to Pay',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                      '₹${NumberFormat('#,##,###.##').format(_payAmount)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.fee.feeStructure?.academicYear ?? '',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // Payment method chips (info only — PayU shows its own UI)
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _infoChip(Icons.security,        'SSL Secured',   Colors.green),
                  _infoChip(Icons.account_balance, 'Net Banking',   Colors.blue),
                  _infoChip(Icons.phone_android,   'UPI',           Colors.orange),
                  _infoChip(Icons.credit_card,     'Cards',         Colors.purple),
                  _infoChip(Icons.wallet,          'Wallets',       Colors.teal),
                ]),
                const SizedBox(height: 22),

                // Success message
                if (_successMessage != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_successMessage!,
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_errorMessage!,
                                style: const TextStyle(color: Colors.red)),
                          ),
                        ]),
                  ),
                  const SizedBox(height: 12),
                ],

                // Pay button
                if (_successMessage == null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _processing ? null : _startPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _processing
                          ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white)),
                          SizedBox(width: 12),
                          Text('Opening PayU…',
                              style: TextStyle(fontSize: 16)),
                        ],
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Pay ₹${NumberFormat('#,##,###').format(_payAmount)} via PayU',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 12),
                if (_successMessage == null)
                  Center(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline,
                              size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text('Secured by PayU Payments',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12)),
                        ]),
                  ),
              ]),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}