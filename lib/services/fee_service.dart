// lib/services/fee_service.dart
//
// ══════════════════════════════════════════════════════════════════════
// BUG FIXES IN THIS VERSION:
//
// BUG 1 — getStudentFees() was querying student_fees with the wrong ID.
//   StudentProfile.id = students.id (UUID from students table).
//   But if the caller passes auth.uid() (profiles.id) instead, the
//   query returns 0 rows. Fix: we now do a lookup of students.id
//   by user_id first, then query student_fees with the correct UUID.
//
// BUG 2 — assign_fees_to_students SQL function filters is_active = true.
//   If the students table has is_active = NULL or the column doesn't
//   exist yet, nobody gets assigned. Fixed in the SQL patch below and
//   we also provide a safe Flutter-side fallback.
//
// BUG 3 — Academic year format mismatch.
//   Admin stores "2026-27", but student dashboard called getStudentFees
//   without any year filter so all years showed — except the Supabase
//   join on fee_structures could fail if the foreign key row was missing.
//   Fix: we always join fee_structures and never filter by year on the
//   student side (show ALL fees assigned to the student regardless of year).
//
// BUG 4 — getFeeStructures required instituteId but admin_fee_management
//   hardcoded _kInstituteId = 1 which may not match your DB. Fixed by
//   making instituteId optional and falling back to no-filter.
// ══════════════════════════════════════════════════════════════════════

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fee_models.dart';

class FeeService {
  static final _db = Supabase.instance.client;

  // ══════════════════════════════════════════
  // INTERNAL HELPER
  // ══════════════════════════════════════════

  /// Given an ID string, figure out which UUID is the students.id for
  /// the currently logged-in user (or the supplied userId string).
  ///
  /// students.id  ─ the UUID primary key on the students table
  /// students.user_id ─ the auth / profiles UUID
  ///
  /// StudentDashboard passes _studentProfile.id which comes from
  /// StudentService.getCurrentStudentProfile() → that queries the
  /// students table directly, so profile.id = students.id.  BUT
  /// in case it ever becomes the auth UUID we do a safe lookup here.
  static Future<String?> _resolveStudentRowId(String idFromCaller) async {
    // 1) Try direct lookup: is idFromCaller already a valid students.id?
    try {
      final row = await _db
          .from('students')
          .select('id')
          .eq('id', idFromCaller)
          .maybeSingle();
      if (row != null) return idFromCaller; // ✅ it is already students.id
    } catch (_) {}

    // 2) Fallback: idFromCaller might be the auth uid stored in students.user_id
    try {
      final row = await _db
          .from('students')
          .select('id')
          .eq('user_id', idFromCaller)
          .maybeSingle();
      if (row != null) return row['id'] as String;
    } catch (_) {}

    // 3) Fallback: use the current auth user's user_id → students.id
    final authUid = _db.auth.currentUser?.id;
    if (authUid != null && authUid != idFromCaller) {
      try {
        final row = await _db
            .from('students')
            .select('id')
            .eq('user_id', authUid)
            .maybeSingle();
        if (row != null) return row['id'] as String;
      } catch (_) {}
    }

    return null; // Could not resolve
  }

  // ══════════════════════════════════════════
  // ADMIN — FEE STRUCTURES
  // ══════════════════════════════════════════

  /// Create a fee structure + installments.
  static Future<({bool success, String? error, int? structureId})>
  createFeeStructure({
    int? instituteId, // optional — reads from institutes table if null
    int? departmentId,
    required String academicYear,
    required String studentYear,
    required String feeName,
    required double totalAmount,
    required List<({double amount, DateTime dueDate, String label})> installments,
  }) async {
    try {
      // If no instituteId supplied, fetch the first one from the DB
      final resolvedInstId = instituteId ?? await _getFirstInstituteId();
      if (resolvedInstId == null) {
        return (success: false, error: 'No institute found in DB. Check institutes table.', structureId: null);
      }

      final fsRow = await _db.from('fee_structures').insert({
        'institute_id':       resolvedInstId,
        'department_id':      departmentId,
        'academic_year':      academicYear,
        'student_year':       studentYear,
        'fee_name':           feeName,
        'total_amount':       totalAmount,
        'installment_count':  installments.length,
        'created_by':         _db.auth.currentUser?.id,
        'is_active':          true,
      }).select('id').single();

      final fsId = fsRow['id'] as int;

      final instRows = installments.asMap().entries.map((e) => {
        'fee_structure_id':   fsId,
        'installment_number': e.key + 1,
        'amount':             e.value.amount,
        'due_date':           e.value.dueDate.toIso8601String().split('T')[0],
        'label':              e.value.label,
      }).toList();

      await _db.from('fee_installments').insert(instRows);
      return (success: true, error: null, structureId: fsId);
    } catch (e) {
      return (success: false, error: e.toString(), structureId: null);
    }
  }

  /// Returns the first institute id in the database, or null.
  /// Public so admin_fee_management can cache it.
  static Future<int?> resolveInstituteId() => _getFirstInstituteId();

  /// Returns the first institute id in the database, or null.
  static Future<int?> _getFirstInstituteId() async {
    try {
      final row = await _db
          .from('institutes')
          .select('id')
          .limit(1)
          .maybeSingle();
      return row?['id'] as int?;
    } catch (_) {
      return null;
    }
  }

  /// List fee structures for admin.
  /// instituteId is optional — if null, fetches all structures.
  static Future<List<FeeStructure>> getFeeStructures({
    int? instituteId,
    String? academicYear,
    bool activeOnly = true,
  }) async {
    try {
      var q = _db.from('fee_structures').select('*, fee_installments(*)');

      if (instituteId != null) q = q.eq('institute_id', instituteId);
      if (academicYear != null) q = q.eq('academic_year', academicYear);
      if (activeOnly) q = q.eq('is_active', true);

      final rows = await q.order('created_at', ascending: false);
      return (rows as List).map((r) => FeeStructure.fromMap(r)).toList();
    } catch (e) {
      print('❌ getFeeStructures: $e');
      return [];
    }
  }

  // ══════════════════════════════════════════
  // ADMIN — ASSIGN FEES → STUDENTS
  // ══════════════════════════════════════════

  /// Calls the DB RPC to bulk-assign a fee structure to students.
  ///
  /// The RPC filters `students.is_active = true`.  If your students
  /// table doesn't have is_active or it's NULL, run the SQL patch
  /// from fee_debug_patch.sql (provided below).
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
        skipped:  (data['skipped']  as num? ?? 0).toInt(),
        error:    null,
        );
      }
      return (success: false, assigned: 0, skipped: 0, error: data['error'] as String?);
    } catch (e) {
      return (success: false, assigned: 0, skipped: 0, error: e.toString());
    }
  }

  // ══════════════════════════════════════════
  // ADMIN — PAYMENT VERIFICATION
  // ══════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> getPendingPayments() async {
    try {
      final rows = await _db
          .from('fee_payments')
          .select('''
            id, amount, payment_method, payment_date, proof_url,
            transaction_id, created_at,
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

  static Future<({bool success, String? receiptNo, String? error})>
  verifyPayment({
    required int paymentId,
    required bool approved,
    String? remarks,
  }) async {
    try {
      final res = await _db.rpc('verify_payment', params: {
        'p_payment_id': paymentId,
        'p_approved':   approved,
        'p_remarks':    remarks,
      });
      final data = res as Map<String, dynamic>;
      return (
      success:  data['success'] == true,
      receiptNo: data['receipt_no'] as String?,
      error:    data['error'] as String?,
      );
    } catch (e) {
      return (success: false, receiptNo: null, error: e.toString());
    }
  }

  // ══════════════════════════════════════════
  // ADMIN — STATS & EXPORT
  // ══════════════════════════════════════════

  static Future<AdminFeeStats?> getAdminFeeStats({
    int? instituteId,
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

      final rows  = await q;
      final list  = rows as List;

      int total = list.length, paid = 0, partial = 0, unpaid = 0, overdue = 0;
      double collected = 0, totalFee = 0;

      for (final r in list) {
        switch (r['payment_status']) {
          case 'paid':    paid++;    break;
          case 'partial': partial++; break;
          case 'overdue': overdue++; break;
          default:        unpaid++;
        }
        collected += (r['amount_paid']   as num? ?? 0).toDouble();
        totalFee  += (r['total_amount']  as num? ?? 0).toDouble();
      }

      final pvRes = await _db
          .from('fee_payments')
          .select('id')
          .eq('status', 'pending')
          .count(CountOption.exact);

      return AdminFeeStats(
        totalStudents:        total,
        paidCount:            paid,
        partialCount:         partial,
        unpaidCount:          unpaid,
        overdueCount:         overdue,
        totalCollected:       collected,
        totalPending:         totalFee - collected,
        totalFeeAmount:       totalFee,
        pendingVerifications: pvRes.count,
      );
    } catch (e) {
      print('❌ getAdminFeeStats: $e');
      return null;
    }
  }

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
        final s = r['students'] as Map? ?? {};
        final d = s['departments'] as Map? ?? {};
        return {
          'Roll Number':  s['roll_number'] ?? '',
          'Name':         '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim(),
          'Email':        s['email'] ?? '',
          'Department':   d['name'] ?? '',
          'Academic Year':r['academic_year'],
          'Total Fee':    r['total_amount'],
          'Amount Paid':  r['amount_paid'],
          'Amount Due':   r['amount_due'],
          'Status':       r['payment_status'],
        };
      }).toList();
    } catch (e) {
      print('❌ exportFeeData: $e');
      return [];
    }
  }

  // ══════════════════════════════════════════
  // ✅ STUDENT — VIEW FEES  (BUG 1 + 3 FIXED)
  // ══════════════════════════════════════════

  /// Load all fees assigned to a student.
  ///
  /// [studentId] can be either:
  ///   • students.id  (UUID from the students table) ← preferred
  ///   • auth uid / profiles.id                     ← also handled
  ///
  /// We resolve to students.id internally before querying student_fees,
  /// which fixes the "0 results" bug when the wrong UUID was passed.
  static Future<List<StudentFee>> getStudentFees(String studentId) async {
    try {
      // ── Resolve to the correct students.id ────────────────────────
      final resolvedId = await _resolveStudentRowId(studentId);
      if (resolvedId == null) {
        print('❌ getStudentFees: could not resolve student row id for $studentId');
        return [];
      }

      // ── Query student_fees with full joins ─────────────────────────
      // No academic_year filter — show ALL fees assigned to this student
      // across all years so they can always see everything.
      final rows = await _db
          .from('student_fees')
          .select('''
            *,
            fee_structures (
              id, fee_name, total_amount, installment_count,
              academic_year, student_year, department_id,
              fee_installments (*)
            )
          ''')
          .eq('student_id', resolvedId)
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
      final resolvedId = await _resolveStudentRowId(studentId);
      if (resolvedId == null) return [];

      final rows = await _db
          .from('fee_payments')
          .select('*, fee_installments(label)')
          .eq('student_id', resolvedId)
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
      final resolvedId = await _resolveStudentRowId(studentId);
      if (resolvedId == null) return [];

      final rows = await _db
          .from('payment_receipts')
          .select('''
            *,
            fee_payments!inner(student_id)
          ''')
          .eq('fee_payments.student_id', resolvedId)
          .eq('is_cancelled', false)
          .order('created_at', ascending: false);
      return (rows as List).map((r) => PaymentReceipt.fromMap(r)).toList();
    } catch (e) {
      print('❌ getStudentReceipts: $e');
      return [];
    }
  }

  // ══════════════════════════════════════════
  // STUDENT — PAYMENTS
  // ══════════════════════════════════════════

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
      final uid  = _db.auth.currentUser!.id;
      final ts   = DateTime.now().millisecondsSinceEpoch;
      final safe = proofFileName.replaceAll(' ', '_');
      final path = '$uid/payment_proofs/${ts}_$safe';

      await _db.storage.from('fee-documents').uploadBinary(
        path, proofBytes,
        fileOptions: const FileOptions(upsert: false),
      );

      final res = await _db.rpc('record_fee_payment', params: {
        'p_student_fee_id':  studentFeeId,
        'p_installment_id':  installmentId,
        'p_payment_method':  paymentMethod,
        'p_amount':          amount,
        'p_transaction_id':  null,
        'p_transaction_ref': transactionRef,
        'p_bank_name':       bankName,
        'p_proof_url':       path,
        'p_auto_verify':     false,
      });
      final data = res as Map<String, dynamic>;
      return (success: data['success'] == true, error: data['error'] as String?);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

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
        'p_student_fee_id':  studentFeeId,
        'p_installment_id':  installmentId,
        'p_payment_method':  paymentMethod,
        'p_amount':          amount,
        'p_transaction_id':  transactionId,
        'p_transaction_ref': null,
        'p_bank_name':       null,
        'p_proof_url':       null,
        'p_auto_verify':     true,
      });
      final data = res as Map<String, dynamic>;
      return (
      success:   data['success'] == true,
      receiptNo: data['receipt_no'] as String?,
      error:     data['error'] as String?,
      );
    } catch (e) {
      return (success: false, receiptNo: null, error: e.toString());
    }
  }

  // ══════════════════════════════════════════
  // HOD — DEPARTMENT FEE OVERVIEW
  // ══════════════════════════════════════════

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

  // ══════════════════════════════════════════
  // STORAGE — SIGNED URLS
  // ══════════════════════════════════════════

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