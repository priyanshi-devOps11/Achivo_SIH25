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
        instList.add(FeeInstallment.fromMap(i));
      }
    }
    return FeeStructure(
      id: map['id'] as int,
      instituteId: map['institute_id'] as int,
      departmentId: map['department_id'] as int?,
      academicYear: map['academic_year'] ?? '',
      studentYear: map['student_year'] ?? 'ALL',
      feeName: map['fee_name'] ?? '',
      totalAmount: (map['total_amount'] as num).toDouble(),
      installmentCount: map['installment_count'] ?? 1,
      isActive: map['is_active'] ?? true,
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.parse(map['created_at']),
      installments: instList,
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

  String get formattedAmount => _fmt(amount);
  bool get isOverdue => dueDate.isBefore(DateTime.now());
  String get formattedDueDate => DateFormat('dd MMM yyyy').format(dueDate);

  factory FeeInstallment.fromMap(Map<String, dynamic> map) {
    return FeeInstallment(
      id: map['id'] as int,
      feeStructureId: map['fee_structure_id'] as int,
      installmentNumber: map['installment_number'] as int,
      amount: (map['amount'] as num).toDouble(),
      dueDate: DateTime.parse(map['due_date']),
      label: map['label'] ?? 'Installment ${map['installment_number']}',
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

  // Optional joins
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

  String get formattedTotal   => _fmt(totalAmount);
  String get formattedPaid    => _fmt(amountPaid);
  String get formattedDue     => _fmt(amountDue);
  String get formattedWaiver  => _fmt(waiverAmount);

  bool get isPaid     => paymentStatus == 'paid';
  bool get isUnpaid   => paymentStatus == 'unpaid';
  bool get isPartial  => paymentStatus == 'partial';
  bool get isOverdue  => paymentStatus == 'overdue';

  factory StudentFee.fromMap(Map<String, dynamic> map) {
    final fsRaw = map['fee_structures'];
    FeeStructure? fs;
    if (fsRaw is Map<String, dynamic>) {
      fs = FeeStructure.fromMap(fsRaw);
    }
    return StudentFee(
      id: map['id'] as int,
      studentId: map['student_id'].toString(),
      feeStructureId: map['fee_structure_id'] as int,
      academicYear: map['academic_year'] ?? '',
      totalAmount: (map['total_amount'] as num).toDouble(),
      amountPaid: (map['amount_paid'] as num? ?? 0).toDouble(),
      amountDue: (map['amount_due'] as num? ?? 0).toDouble(),
      paymentStatus: map['payment_status'] ?? 'unpaid',
      waiverAmount: (map['waiver_amount'] as num? ?? 0).toDouble(),
      waiverReason: map['waiver_reason'] as String?,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      feeStructure: fs,
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
    const map = {
      'online': 'Online Payment',
      'upi': 'UPI',
      'net_banking': 'Net Banking',
      'credit_card': 'Credit Card',
      'debit_card': 'Debit Card',
      'cash': 'Cash',
      'dd': 'Demand Draft',
      'cheque': 'Cheque',
      'neft': 'NEFT',
      'rtgs': 'RTGS',
    };
    return map[paymentMethod] ?? paymentMethod;
  }

  bool get isPending  => status == 'pending';
  bool get isVerified => status == 'verified';
  bool get isFailed   => status == 'failed';

  factory FeePayment.fromMap(Map<String, dynamic> map) {
    final instRaw = map['fee_installments'];
    String? instLabel;
    if (instRaw is Map) instLabel = instRaw['label'] as String?;

    return FeePayment(
      id: map['id'] as int,
      studentFeeId: map['student_fee_id'] as int,
      studentId: map['student_id'].toString(),
      feeInstallmentId: map['fee_installment_id'] as int?,
      paymentMethod: map['payment_method'] ?? 'cash',
      amount: (map['amount'] as num).toDouble(),
      transactionId: map['transaction_id'] as String?,
      transactionRef: map['transaction_ref'] as String?,
      paymentDate: DateTime.parse(map['payment_date']),
      bankName: map['bank_name'] as String?,
      proofUrl: map['proof_url'] as String?,
      status: map['status'] ?? 'pending',
      verifiedBy: map['verified_by'] as String?,
      verifiedAt: map['verified_at'] != null
          ? DateTime.parse(map['verified_at'])
          : null,
      refundAmount: (map['refund_amount'] as num? ?? 0).toDouble(),
      remarks: map['remarks'] as String?,
      createdAt: DateTime.parse(map['created_at']),
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
  });

  String get formattedAmountPaid    => _fmt(amountPaid);
  String get formattedTotalFee      => _fmt(totalFee);
  String get formattedRemaining     => _fmt(remainingAfter);
  String get formattedDate          => DateFormat('dd MMM yyyy').format(createdAt);

  factory PaymentReceipt.fromMap(Map<String, dynamic> map) {
    return PaymentReceipt(
      id: map['id'] as int,
      receiptNumber: map['receipt_number'] ?? '',
      feePaymentId: map['fee_payment_id'] as int,
      studentName: map['student_name'] ?? '',
      rollNumber: map['roll_number'] ?? '',
      departmentName: map['department_name'] ?? '',
      academicYear: map['academic_year'] ?? '',
      feeStructureName: map['fee_structure_name'] ?? '',
      installmentLabel: map['installment_label'] as String?,
      amountPaid: (map['amount_paid'] as num).toDouble(),
      totalFee: (map['total_fee'] as num).toDouble(),
      amountPaidBefore: (map['amount_paid_before'] as num? ?? 0).toDouble(),
      remainingAfter: (map['remaining_after'] as num? ?? 0).toDouble(),
      paymentMethod: map['payment_method'] ?? '',
      transactionId: map['transaction_id'] as String?,
      receiptPdfUrl: map['receipt_pdf_url'] as String?,
      isCancelled: map['is_cancelled'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

// ─────────────────────────────────────────────
// ADMIN FEE STATS  (dashboard summary)
// ─────────────────────────────────────────────

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
      totalFeeAmount == 0 ? 0 : (totalCollected / totalFeeAmount).clamp(0, 1);

  String get formattedCollected => _fmt(totalCollected);
  String get formattedPending   => _fmt(totalPending);
  String get formattedTotal     => _fmt(totalFeeAmount);
}

// ─────────────────────────────────────────────
// HOD FEE SUMMARY  (from RPC)
// ─────────────────────────────────────────────

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
      totalStudents: (map['total_students'] as num? ?? 0).toInt(),
      paidCount: (map['paid'] as num? ?? 0).toInt(),
      partialCount: (map['partial'] as num? ?? 0).toInt(),
      unpaidCount: (map['unpaid'] as num? ?? 0).toInt(),
      totalCollected: (map['total_collected'] as num? ?? 0).toDouble(),
      totalPending: (map['total_pending'] as num? ?? 0).toDouble(),
      totalFee: (map['total_fee'] as num? ?? 0).toDouble(),
    );
  }
}