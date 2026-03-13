// lib/services/fee_service.dart

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fee_models.dart';

class FeeService {
  static final _db = Supabase.instance.client;

  // ════════════════════════════════════════════
  // ADMIN — FEE STRUCTURES
  // ════════════════════════════════════════════

  /// Create a new fee structure with its installments in one transaction.
  static Future<({bool success, String? error, int? structureId})>
  createFeeStructure({
    required int instituteId,
    int? departmentId,
    required String academicYear,
    required String studentYear,
    required String feeName,
    required double totalAmount,
    required List<({double amount, DateTime dueDate, String label})> installments,
  }) async {
    try {
      final fsRow = await _db.from('fee_structures').insert({
        'institute_id': instituteId,
        'department_id': departmentId,
        'academic_year': academicYear,
        'student_year': studentYear,
        'fee_name': feeName,
        'total_amount': totalAmount,
        'installment_count': installments.length,
        'created_by': _db.auth.currentUser?.id,
      }).select('id').single();

      final fsId = fsRow['id'] as int;

      final instRows = installments.asMap().entries.map((e) => {
        'fee_structure_id': fsId,
        'installment_number': e.key + 1,
        'amount': e.value.amount,
        'due_date': e.value.dueDate.toIso8601String().split('T')[0],
        'label': e.value.label,
      }).toList();

      await _db.from('fee_installments').insert(instRows);
      return (success: true, error: null, structureId: fsId);
    } catch (e) {
      return (success: false, error: e.toString(), structureId: null);
    }
  }

  /// List fee structures, optionally filtered.
  static Future<List<FeeStructure>> getFeeStructures({
    required int instituteId,
    String? academicYear,
    bool activeOnly = true,
  }) async {
    try {
      var q = _db
          .from('fee_structures')
          .select('*, fee_installments(*)')
          .eq('institute_id', instituteId);
      if (academicYear != null) q = q.eq('academic_year', academicYear);
      if (activeOnly) q = q.eq('is_active', true);
      final rows = await q.order('created_at', ascending: false);
      return (rows as List).map((r) => FeeStructure.fromMap(r)).toList();
    } catch (e) {
      print('❌ getFeeStructures: $e');
      return [];
    }
  }

  /// Assign a fee structure to all matching students (calls DB RPC).
  static Future<({bool success, int assigned, int skipped, String? error})>
  assignFeesToStudents(int feeStructureId) async {
    try {
      final res = await _db.rpc(
        'assign_fees_to_students',
        params: {'p_fee_structure_id': feeStructureId},
      );
      final data = res as Map<String, dynamic>;
      if (data['success'] == true) {
        return (
        success: true,
        assigned: (data['assigned'] as num? ?? 0).toInt(),
        skipped: (data['skipped'] as num? ?? 0).toInt(),
        error: null,
        );
      }
      return (success: false, assigned: 0, skipped: 0, error: data['error'] as String?);
    } catch (e) {
      return (success: false, assigned: 0, skipped: 0, error: e.toString());
    }
  }

  // ════════════════════════════════════════════
  // ADMIN — PAYMENT VERIFICATION
  // ════════════════════════════════════════════

  /// List payments pending admin verification.
  static Future<List<Map<String, dynamic>>> getPendingPayments() async {
    try {
      final rows = await _db
          .from('fee_payments')
          .select('''
            id, amount, payment_method, payment_date, proof_url, transaction_id,
            created_at,
            students(first_name, last_name, roll_number,
              departments(name))
          ''')
          .eq('status', 'pending')
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      print('❌ getPendingPayments: $e');
      return [];
    }
  }

  /// Approve or reject a pending payment (calls DB RPC).
  static Future<({bool success, String? receiptNo, String? error})>
  verifyPayment({
    required int paymentId,
    required bool approved,
    String? remarks,
  }) async {
    try {
      final res = await _db.rpc('verify_payment', params: {
        'p_payment_id': paymentId,
        'p_approved': approved,
        'p_remarks': remarks,
      });
      final data = res as Map<String, dynamic>;
      return (
      success: data['success'] == true,
      receiptNo: data['receipt_no'] as String?,
      error: data['error'] as String?,
      );
    } catch (e) {
      return (success: false, receiptNo: null, error: e.toString());
    }
  }

  // ════════════════════════════════════════════
  // ADMIN — STATS & EXPORT
  // ════════════════════════════════════════════

  static Future<AdminFeeStats?> getAdminFeeStats({
    required int instituteId,
    required String academicYear,
    int? departmentId,
  }) async {
    try {
      var q = _db
          .from('student_fees')
          .select('''
            id, payment_status, total_amount, amount_paid,
            students!inner(department_id)
          ''')
          .eq('academic_year', academicYear);

      if (departmentId != null) {
        q = q.eq('students.department_id', departmentId);
      }

      final rows = await q;
      final list = rows as List;

      int total = list.length, paid = 0, partial = 0, unpaid = 0, overdue = 0;
      double collected = 0, pending = 0, totalFee = 0;

      for (final r in list) {
        switch (r['payment_status']) {
          case 'paid':     paid++;    break;
          case 'partial':  partial++; break;
          case 'overdue':  overdue++; break;
          default:         unpaid++;
        }
        collected += (r['amount_paid'] as num? ?? 0).toDouble();
        totalFee  += (r['total_amount'] as num? ?? 0).toDouble();
      }
      pending = totalFee - collected;

      // Pending verifications count
      final pvRes = await _db
          .from('fee_payments')
          .select('id')
          .eq('status', 'pending')
          .count(CountOption.exact);

      return AdminFeeStats(
        totalStudents: total,
        paidCount: paid,
        partialCount: partial,
        unpaidCount: unpaid,
        overdueCount: overdue,
        totalCollected: collected,
        totalPending: pending,
        totalFeeAmount: totalFee,
        pendingVerifications: pvRes.count,
      );
    } catch (e) {
      print('❌ getAdminFeeStats: $e');
      return null;
    }
  }

  /// Returns CSV-ready list of maps for export.
  static Future<List<Map<String, dynamic>>> exportFeeData({
    required String academicYear,
    int? departmentId,
    String? statusFilter,
  }) async {
    try {
      var q = _db
          .from('student_fees')
          .select('''
            academic_year, payment_status, total_amount, amount_paid, amount_due,
            students(first_name, last_name, roll_number, email,
              departments(name))
          ''')
          .eq('academic_year', academicYear);

      if (statusFilter != null && statusFilter != 'all') {
        q = q.eq('payment_status', statusFilter);
      }
      if (departmentId != null) {
        q = q.eq('students.department_id', departmentId);
      }

      final rows = await q.order('students(roll_number)', ascending: true);
      return (rows as List).map((r) {
        final s = r['students'] as Map;
        final d = s['departments'] as Map? ?? {};
        return {
          'Roll Number': s['roll_number'],
          'Name': '${s['first_name']} ${s['last_name']}',
          'Email': s['email'],
          'Department': d['name'] ?? '',
          'Academic Year': r['academic_year'],
          'Total Fee': r['total_amount'],
          'Amount Paid': r['amount_paid'],
          'Amount Due': r['amount_due'],
          'Status': r['payment_status'],
        };
      }).toList();
    } catch (e) {
      print('❌ exportFeeData: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════
  // STUDENT — VIEW FEES
  // ════════════════════════════════════════════

  static Future<List<StudentFee>> getStudentFees(String studentId) async {
    try {
      final rows = await _db
          .from('student_fees')
          .select('''
            *,
            fee_structures(*, fee_installments(*))
          ''')
          .eq('student_id', studentId)
          .order('created_at', ascending: false);
      return (rows as List).map((r) => StudentFee.fromMap(r)).toList();
    } catch (e) {
      print('❌ getStudentFees: $e');
      return [];
    }
  }

  static Future<List<FeePayment>> getStudentPaymentHistory(
      String studentId) async {
    try {
      final rows = await _db
          .from('fee_payments')
          .select('''
            *,
            fee_installments(label)
          ''')
          .eq('student_id', studentId)
          .order('created_at', ascending: false);
      return (rows as List).map((r) => FeePayment.fromMap(r)).toList();
    } catch (e) {
      print('❌ getStudentPaymentHistory: $e');
      return [];
    }
  }

  static Future<List<PaymentReceipt>> getStudentReceipts(
      String studentId) async {
    try {
      final rows = await _db
          .from('payment_receipts')
          .select('''
            *,
            fee_payments!inner(student_id)
          ''')
          .eq('fee_payments.student_id', studentId)
          .eq('is_cancelled', false)
          .order('created_at', ascending: false);
      return (rows as List).map((r) => PaymentReceipt.fromMap(r)).toList();
    } catch (e) {
      print('❌ getStudentReceipts: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════
  // STUDENT — PAYMENTS
  // ════════════════════════════════════════════

  /// Submit a payment with proof file (stored, pending admin verification).
  static Future<({bool success, String? error})> submitPaymentWithProof({
    required int studentFeeId,
    int? installmentId,
    required String paymentMethod,
    required double amount,
    String? transactionRef,
    String? bankName,
    required Uint8List proofBytes,
    required String proofFileName,
  }) async {
    try {
      final uid = _db.auth.currentUser!.id;
      final ts  = DateTime.now().millisecondsSinceEpoch;
      final safe = proofFileName.replaceAll(' ', '_');
      final path = '$uid/payment_proofs/${ts}_$safe';

      await _db.storage.from('fee-documents').uploadBinary(
        path,
        proofBytes,
        fileOptions: const FileOptions(upsert: false),
      );

      final res = await _db.rpc('record_fee_payment', params: {
        'p_student_fee_id':   studentFeeId,
        'p_installment_id':   installmentId,
        'p_payment_method':   paymentMethod,
        'p_amount':           amount,
        'p_transaction_id':   null,
        'p_transaction_ref':  transactionRef,
        'p_bank_name':        bankName,
        'p_proof_url':        path,
        'p_auto_verify':      false,
      });
      final data = res as Map<String, dynamic>;
      return (
      success: data['success'] == true,
      error: data['error'] as String?,
      );
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  /// Record an online/gateway payment (auto-verified, receipt generated immediately).
  static Future<({bool success, String? receiptNo, String? error})>
  recordOnlinePayment({
    required int studentFeeId,
    int? installmentId,
    required String paymentMethod,
    required double amount,
    required String transactionId,
  }) async {
    try {
      final res = await _db.rpc('record_fee_payment', params: {
        'p_student_fee_id':   studentFeeId,
        'p_installment_id':   installmentId,
        'p_payment_method':   paymentMethod,
        'p_amount':           amount,
        'p_transaction_id':   transactionId,
        'p_transaction_ref':  null,
        'p_bank_name':        null,
        'p_proof_url':        null,
        'p_auto_verify':      true,
      });
      final data = res as Map<String, dynamic>;
      return (
      success: data['success'] == true,
      receiptNo: data['receipt_no'] as String?,
      error: data['error'] as String?,
      );
    } catch (e) {
      return (success: false, receiptNo: null, error: e.toString());
    }
  }

  // ════════════════════════════════════════════
  // HOD — DEPARTMENT FEE OVERVIEW
  // ════════════════════════════════════════════

  static Future<HodFeeSummary?> getHodFeeSummary({
    required int departmentId,
    required String academicYear,
  }) async {
    try {
      final res = await _db.rpc('get_fee_summary_for_hod', params: {
        'p_department_id': departmentId,
        'p_academic_year': academicYear,
      });
      return HodFeeSummary.fromMap(res as Map<String, dynamic>);
    } catch (e) {
      print('❌ getHodFeeSummary: $e');
      return null;
    }
  }

  static Future<List<StudentFee>> getDeptStudentFeeList({
    required int departmentId,
    required String academicYear,
    String? statusFilter,
  }) async {
    try {
      var q = _db
          .from('student_fees')
          .select('''
            *,
            fee_structures(fee_name),
            students!inner(first_name, last_name, roll_number, department_id)
          ''')
          .eq('academic_year', academicYear)
          .eq('students.department_id', departmentId);

      if (statusFilter != null && statusFilter != 'all') {
        q = q.eq('payment_status', statusFilter);
      }

      final rows = await q.order('students(roll_number)', ascending: true);
      return (rows as List).map((r) => StudentFee.fromMap(r)).toList();
    } catch (e) {
      print('❌ getDeptStudentFeeList: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════
  // STORAGE — SIGNED URL FOR RECEIPTS / PROOFS
  // ════════════════════════════════════════════

  static Future<String?> getReceiptSignedUrl(String storagePath) async {
    try {
      return await _db.storage
          .from('fee-documents')
          .createSignedUrl(storagePath, 3600);
    } catch (e) {
      print('❌ getReceiptSignedUrl: $e');
      return null;
    }
  }

  static Future<String?> getProofSignedUrl(String storagePath) async {
    try {
      return await _db.storage
          .from('fee-documents')
          .createSignedUrl(storagePath, 3600);
    } catch (e) {
      print('❌ getProofSignedUrl: $e');
      return null;
    }
  }
}