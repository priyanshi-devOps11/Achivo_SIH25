// lib/models/fee_models.dart

import 'package:intl/intl.dart';

// ─────────────────────────────────────────────
// FORMAT HELPER
// ─────────────────────────────────────────────

String _fmt(num? v) {
  if (v == null) return '₹0';
  return '₹${NumberFormat('#,##,###.##').format(v)}';
}

// ─────────────────────────────────────────────
// SAFE CAST HELPERS
// ─────────────────────────────────────────────

int _toInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  final parsed = int.tryParse(v.toString());
  return parsed ?? fallback;
}

double _toDouble(dynamic v, {double fallback = 0.0}) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  final parsed = double.tryParse(v.toString());
  return parsed ?? fallback;
}

DateTime _parseDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return DateTime.now();
  }
}

// ─────────────────────────────────────────────
// FEE STRUCTURE
// ─────────────────────────────────────────────

class FeeStructure {
  final int id;
  final int instituteId;
  final int? departmentId;
  final String academicYear;
  final String studentYear;
  final String feeName;
  final double totalAmount;
  final int installmentCount;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final List<FeeInstallment> installments;

  FeeStructure({
    required this.id,
    required this.instituteId,
    this.departmentId,
    required this.academicYear,
    required this.studentYear,
    required this.feeName,
    required this.totalAmount,
    required this.installmentCount,
    required this.isActive,
    this.createdBy,
    required this.createdAt,
    this.installments = const [],
  });

  String get formattedAmount => _fmt(totalAmount);

  factory FeeStructure.fromMap(Map<String, dynamic> map) {
    final instRaw = map['fee_installments'];
    final instList = <FeeInstallment>[];
    if (instRaw is List) {
      for (final i in instRaw) {
        if (i is Map<String, dynamic>) {
          instList.add(FeeInstallment.fromMap(i));
        }
      }
    }
    return FeeStructure(
      id:               _toInt(map['id']),
      instituteId:      _toInt(map['institute_id']),
      departmentId:     map['department_id'] != null
          ? _toInt(map['department_id'])
          : null,
      academicYear:     map['academic_year']?.toString() ?? '',
      studentYear:      map['student_year']?.toString() ?? 'ALL',
      feeName:          map['fee_name']?.toString() ?? '',
      totalAmount:      _toDouble(map['total_amount']),
      installmentCount: _toInt(map['installment_count'], fallback: 1),
      isActive:         map['is_active'] as bool? ?? true,
      createdBy:        map['created_by']?.toString(),
      createdAt:        _parseDate(map['created_at']),
      installments:     instList,
    );
  }
}

// ─────────────────────────────────────────────
// FEE INSTALLMENT
// ─────────────────────────────────────────────

class FeeInstallment {
  final int id;
  final int feeStructureId;
  final int installmentNumber;
  final double amount;
  final DateTime dueDate;
  final String label;

  FeeInstallment({
    required this.id,
    required this.feeStructureId,
    required this.installmentNumber,
    required this.amount,
    required this.dueDate,
    required this.label,
  });

  String get formattedAmount  => _fmt(amount);
  bool   get isOverdue        => dueDate.isBefore(DateTime.now());
  String get formattedDueDate => DateFormat('dd MMM yyyy').format(dueDate);

  factory FeeInstallment.fromMap(Map<String, dynamic> map) {
    return FeeInstallment(
      id:                _toInt(map['id']),
      feeStructureId:    _toInt(map['fee_structure_id']),
      installmentNumber: _toInt(map['installment_number']),
      amount:            _toDouble(map['amount']),
      dueDate:           _parseDate(map['due_date']),
      label:             map['label']?.toString() ??
          'Installment ${_toInt(map['installment_number'])}',
    );
  }
}

// ─────────────────────────────────────────────
// STUDENT FEE  (assigned fee record)
// ─────────────────────────────────────────────

class StudentFee {
  final int id;
  final String studentId;
  final int feeStructureId;
  final String academicYear;
  final double totalAmount;
  final double amountPaid;
  final double amountDue;
  final String paymentStatus;
  final double waiverAmount;
  final String? waiverReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional join
  final FeeStructure? feeStructure;

  StudentFee({
    required this.id,
    required this.studentId,
    required this.feeStructureId,
    required this.academicYear,
    required this.totalAmount,
    required this.amountPaid,
    required this.amountDue,
    required this.paymentStatus,
    this.waiverAmount = 0,
    this.waiverReason,
    required this.createdAt,
    required this.updatedAt,
    this.feeStructure,
  });

  double get percentagePaid =>
      totalAmount == 0 ? 0 : (amountPaid / totalAmount).clamp(0, 1);

  String get formattedTotal  => _fmt(totalAmount);
  String get formattedPaid   => _fmt(amountPaid);
  String get formattedDue    => _fmt(amountDue);
  String get formattedWaiver => _fmt(waiverAmount);

  bool get isPaid    => paymentStatus == 'paid';
  bool get isUnpaid  => paymentStatus == 'unpaid';
  bool get isPartial => paymentStatus == 'partial';
  bool get isOverdue => paymentStatus == 'overdue';

  factory StudentFee.fromMap(Map<String, dynamic> map) {
    final fsRaw = map['fee_structures'];
    FeeStructure? fs;
    if (fsRaw is Map<String, dynamic>) {
      fs = FeeStructure.fromMap(fsRaw);
    }
    return StudentFee(
      id:             _toInt(map['id']),
      studentId:      map['student_id']?.toString() ?? '',
      feeStructureId: _toInt(map['fee_structure_id']),
      academicYear:   map['academic_year']?.toString() ?? '',
      totalAmount:    _toDouble(map['total_amount']),
      amountPaid:     _toDouble(map['amount_paid']),
      amountDue:      _toDouble(map['amount_due']),
      paymentStatus:  map['payment_status']?.toString() ?? 'unpaid',
      waiverAmount:   _toDouble(map['waiver_amount']),
      waiverReason:   map['waiver_reason']?.toString(),
      createdAt:      _parseDate(map['created_at']),
      updatedAt:      _parseDate(map['updated_at']),
      feeStructure:   fs,
    );
  }
}

// ─────────────────────────────────────────────
// FEE PAYMENT
// ─────────────────────────────────────────────

class FeePayment {
  final int id;
  final int studentFeeId;
  final String studentId;
  final int? feeInstallmentId;
  final String paymentMethod;
  final double amount;
  final String? transactionId;
  final String? transactionRef;
  final DateTime paymentDate;
  final String? bankName;
  final String? proofUrl;
  final String status;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final double refundAmount;
  final String? remarks;
  final DateTime createdAt;

  // Optional join
  final String? installmentLabel;

  FeePayment({
    required this.id,
    required this.studentFeeId,
    required this.studentId,
    this.feeInstallmentId,
    required this.paymentMethod,
    required this.amount,
    this.transactionId,
    this.transactionRef,
    required this.paymentDate,
    this.bankName,
    this.proofUrl,
    required this.status,
    this.verifiedBy,
    this.verifiedAt,
    this.refundAmount = 0,
    this.remarks,
    required this.createdAt,
    this.installmentLabel,
  });

  String get formattedAmount => _fmt(amount);
  String get formattedDate   => DateFormat('dd MMM yyyy').format(paymentDate);

  String get displayMethod {
    const methodMap = {
      'online':      'Online Payment',
      'upi':         'UPI',
      'net_banking': 'Net Banking',
      'credit_card': 'Credit Card',
      'debit_card':  'Debit Card',
      'cash':        'Cash',
      'dd':          'Demand Draft',
      'cheque':      'Cheque',
      'neft':        'NEFT',
      'rtgs':        'RTGS',
    };
    return methodMap[paymentMethod] ?? paymentMethod;
  }

  bool get isPending  => status == 'pending';
  bool get isVerified => status == 'verified';
  bool get isFailed   => status == 'failed';

  factory FeePayment.fromMap(Map<String, dynamic> map) {
    final instRaw = map['fee_installments'];
    String? instLabel;
    if (instRaw is Map) instLabel = instRaw['label']?.toString();

    return FeePayment(
      id:               _toInt(map['id']),
      studentFeeId:     _toInt(map['student_fee_id']),
      studentId:        map['student_id']?.toString() ?? '',
      feeInstallmentId: map['fee_installment_id'] != null
          ? _toInt(map['fee_installment_id'])
          : null,
      paymentMethod:    map['payment_method']?.toString() ?? 'cash',
      amount:           _toDouble(map['amount']),
      transactionId:    map['transaction_id']?.toString(),
      transactionRef:   map['transaction_ref']?.toString(),
      paymentDate:      _parseDate(map['payment_date']),
      bankName:         map['bank_name']?.toString(),
      proofUrl:         map['proof_url']?.toString(),
      status:           map['status']?.toString() ?? 'pending',
      verifiedBy:       map['verified_by']?.toString(),
      verifiedAt:       map['verified_at'] != null
          ? _parseDate(map['verified_at'])
          : null,
      refundAmount:     _toDouble(map['refund_amount']),
      remarks:          map['remarks']?.toString(),
      createdAt:        _parseDate(map['created_at']),
      installmentLabel: instLabel,
    );
  }
}

// ─────────────────────────────────────────────
// PAYMENT RECEIPT
// ─────────────────────────────────────────────

class PaymentReceipt {
  final int id;
  final String receiptNumber;
  final int feePaymentId;
  final String studentName;
  final String rollNumber;
  final String departmentName;
  final String academicYear;
  final String feeStructureName;
  final String? installmentLabel;
  final double amountPaid;
  final double totalFee;
  final double amountPaidBefore;
  final double remainingAfter;
  final String paymentMethod;
  final String? transactionId;
  final String? receiptPdfUrl;
  final bool isCancelled;
  final DateTime createdAt;

  // ── Extra fields used by receipt_pdf_service.dart ────────────────
  /// Institute name snapshot. Falls back to empty string if the DB row
  /// doesn't carry this column yet.
  final String instituteName;

  /// The date the payment was actually made (fee_payments.payment_date).
  /// Defaults to createdAt when not available.
  final DateTime paymentDate;

  PaymentReceipt({
    required this.id,
    required this.receiptNumber,
    required this.feePaymentId,
    required this.studentName,
    required this.rollNumber,
    required this.departmentName,
    required this.academicYear,
    required this.feeStructureName,
    this.installmentLabel,
    required this.amountPaid,
    required this.totalFee,
    required this.amountPaidBefore,
    required this.remainingAfter,
    required this.paymentMethod,
    this.transactionId,
    this.receiptPdfUrl,
    this.isCancelled = false,
    required this.createdAt,
    this.instituteName = '',
    DateTime? paymentDate,
  }) : paymentDate = paymentDate ?? createdAt;

  String get formattedAmountPaid  => _fmt(amountPaid);
  String get formattedTotalFee    => _fmt(totalFee);
  String get formattedRemaining   => _fmt(remainingAfter);
  String get formattedDate        => DateFormat('dd MMM yyyy').format(createdAt);
  String get formattedPaymentDate => DateFormat('dd MMM yyyy').format(paymentDate);

  factory PaymentReceipt.fromMap(Map<String, dynamic> map) {
    // payment_date may be a top-level field or nested in fee_payments join
    final rawPaymentDate = map['payment_date'] ??
        (map['fee_payments'] is Map
            ? (map['fee_payments'] as Map)['payment_date']
            : null);

    return PaymentReceipt(
      id:               _toInt(map['id']),
      receiptNumber:    map['receipt_number']?.toString() ?? '',
      feePaymentId:     _toInt(map['fee_payment_id']),
      studentName:      map['student_name']?.toString() ?? '',
      rollNumber:       map['roll_number']?.toString() ?? '',
      departmentName:   map['department_name']?.toString() ?? '',
      academicYear:     map['academic_year']?.toString() ?? '',
      feeStructureName: map['fee_structure_name']?.toString() ?? '',
      installmentLabel: map['installment_label']?.toString(),
      amountPaid:       _toDouble(map['amount_paid']),
      totalFee:         _toDouble(map['total_fee']),
      amountPaidBefore: _toDouble(map['amount_paid_before']),
      remainingAfter:   _toDouble(map['remaining_after']),
      paymentMethod:    map['payment_method']?.toString() ?? '',
      transactionId:    map['transaction_id']?.toString(),
      receiptPdfUrl:    map['receipt_pdf_url']?.toString(),
      isCancelled:      map['is_cancelled'] as bool? ?? false,
      createdAt:        _parseDate(map['created_at']),
      instituteName:    map['institute_name']?.toString() ?? '',
      paymentDate:      rawPaymentDate != null
          ? _parseDate(rawPaymentDate)
          : null,
    );
  }
}


class AdminFeeStats {
  final int totalStudents;
  final int paidCount;
  final int partialCount;
  final int unpaidCount;
  final int overdueCount;
  final double totalCollected;
  final double totalPending;
  final double totalFeeAmount;
  final int pendingVerifications;

  AdminFeeStats({
    required this.totalStudents,
    required this.paidCount,
    required this.partialCount,
    required this.unpaidCount,
    required this.overdueCount,
    required this.totalCollected,
    required this.totalPending,
    required this.totalFeeAmount,
    required this.pendingVerifications,
  });

  double get collectionRate =>
      totalFeeAmount == 0
          ? 0
          : (totalCollected / totalFeeAmount).clamp(0, 1);

  String get formattedCollected => _fmt(totalCollected);
  String get formattedPending   => _fmt(totalPending);
  String get formattedTotal     => _fmt(totalFeeAmount);
}


class HodFeeSummary {
  final int totalStudents;
  final int paidCount;
  final int partialCount;
  final int unpaidCount;
  final double totalCollected;
  final double totalPending;
  final double totalFee;

  HodFeeSummary({
    required this.totalStudents,
    required this.paidCount,
    required this.partialCount,
    required this.unpaidCount,
    required this.totalCollected,
    required this.totalPending,
    required this.totalFee,
  });

  double get collectionRate =>
      totalFee == 0 ? 0 : (totalCollected / totalFee).clamp(0, 1);

  String get formattedCollected => _fmt(totalCollected);
  String get formattedPending   => _fmt(totalPending);
  String get formattedTotal     => _fmt(totalFee);

  factory HodFeeSummary.fromMap(Map<String, dynamic> map) {
    return HodFeeSummary(
      totalStudents:  _toInt(map['total_students']),
      paidCount:      _toInt(map['paid']),
      partialCount:   _toInt(map['partial']),
      unpaidCount:    _toInt(map['unpaid']),
      totalCollected: _toDouble(map['total_collected']),
      totalPending:   _toDouble(map['total_pending']),
      totalFee:       _toDouble(map['total_fee']),
    );
  }
}