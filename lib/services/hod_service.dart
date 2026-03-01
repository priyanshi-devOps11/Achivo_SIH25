

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hod_models.dart';

class HODService {
  static final _supabase = Supabase.instance.client;

  static Future<BigInt?> getHODDepartmentId() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final profileResponse = await _supabase
          .from('profiles')
          .select('department_id')
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse == null) return null;
      final deptId = profileResponse['department_id'];
      if (deptId == null) return null;

      return deptId is int ? BigInt.from(deptId) : (deptId is BigInt ? deptId : null);
    } catch (e) {
      print('❌ Error getting HOD department: $e');
      return null;
    }
  }

  static Future<bool> ensureHODRecordExists() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final hodRecord = await _supabase
          .from('hods')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (hodRecord != null) {
        print('✅ HOD record exists');
        return true;
      }

      final profile = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null || profile['role'] != 'hod') return false;

      final deptCode = await _getDepartmentCode(profile['department_id']);
      final hodId = 'HOD${deptCode}${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      await _supabase.from('hods').insert({
        'user_id': userId,
        'hod_id': hodId,
        'first_name': profile['first_name'] ?? 'HOD',
        'last_name': profile['last_name'] ?? '',
        'email': profile['email'],
        'department_id': profile['department_id'],
        'designation': 'Head of Department',
        'is_active': true,
      });

      print('✅ HOD record created with ID: $hodId');
      return true;
    } catch (e) {
      print('❌ Error ensuring HOD record: $e');
      return false;
    }
  }

  static Future<String> _getDepartmentCode(dynamic deptId) async {
    if (deptId == null) return 'GEN';
    try {
      final dept = await _supabase
          .from('departments')
          .select('code')
          .eq('id', deptId)
          .maybeSingle();
      return dept?['code'] ?? 'GEN';
    } catch (e) {
      return 'GEN';
    }
  }

  static Future<List<DocumentForReview>> getDocumentsForReview({
    BigInt? departmentId,
    String? status,
    String? documentType,
  }) async {
    try {
      if (departmentId == null) return [];
      final deptIdInt = departmentId.toInt();

      dynamic query = _supabase
          .from('student_documents')
          .select('''
            *,
            students!inner(id, first_name, last_name, roll_number, department_id)
          ''');

      query = query.eq('students.department_id', deptIdInt);
      if (status != null && status != 'all') query = query.eq('status', status);
      if (documentType != null && documentType != 'all') query = query.eq('document_type', documentType);

      final response = await query.order('created_at', ascending: false);
      if (response == null || (response as List).isEmpty) return [];

      return response.map<DocumentForReview>((doc) {
        final student = doc['students'] as Map<String, dynamic>;
        final studentName = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim();
        return DocumentForReview.fromMap(doc, studentName, student['roll_number'] ?? 'N/A');
      }).toList();
    } catch (e) {
      print('❌ Error loading documents: $e');
      return [];
    }
  }

  static Future<List<LeaveForReview>> getLeavesForReview({
    BigInt? departmentId,
    String? status,
  }) async {
    try {
      if (departmentId == null) return [];
      final deptIdInt = departmentId.toInt();

      dynamic query = _supabase
          .from('leave_applications')
          .select('''
            *,
            students!inner(id, first_name, last_name, roll_number, department_id)
          ''');

      query = query.eq('students.department_id', deptIdInt);
      if (status != null && status != 'all') query = query.eq('status', status);

      final response = await query.order('created_at', ascending: false);
      if (response == null || (response as List).isEmpty) return [];

      return response.map<LeaveForReview>((leave) {
        final student = leave['students'] as Map<String, dynamic>;
        final studentName = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim();
        return LeaveForReview.fromMap(leave, studentName, student['roll_number'] ?? 'N/A');
      }).toList();
    } catch (e) {
      print('❌ Error loading leaves: $e');
      return [];
    }
  }

  static Future<bool> reviewDocument({
    required String documentId,
    required String action,
    String? remarks,
    int pointsAwarded = 0,
  }) async {
    try {
      final hodUserId = _supabase.auth.currentUser?.id;
      if (hodUserId == null) return false;

      await _supabase.from('student_documents').update({
        'status': action == 'approve' ? 'approved' : 'rejected',
        'hod_remarks': remarks,
        'points_awarded': action == 'approve' ? pointsAwarded : 0,
        'reviewed_by': hodUserId,   // ← auth.uid(), always in profiles
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', int.parse(documentId));

      print('✅ Document $documentId ${action}d');
      return true;
    } catch (e) {
      print('❌ Error reviewing document: $e');
      return false;
    }
  }


  static Future<bool> reviewLeave({
    required String leaveId,
    required String action,
    String? remarks,
  }) async {
    try {
      final hodUserId = _supabase.auth.currentUser?.id;
      if (hodUserId == null) return false;

      await _supabase.from('leave_applications').update({
        'status': action == 'approve' ? 'approved' : 'rejected',
        'hod_remarks': remarks,
        'reviewed_by': hodUserId,   // ← auth.uid(), always in profiles
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', int.parse(leaveId));

      print('✅ Leave $leaveId ${action}d');
      return true;
    } catch (e) {
      print('❌ Error reviewing leave: $e');
      return false;
    }
  }

  static Future<HODStats> getHODStats(BigInt departmentId) async {
    try {
      final deptIdInt = departmentId.toInt();
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      int totalStudents = 0, activeStudents = 0;
      int totalFaculty = 0, activeFaculty = 0;

      try {
        final r = await _supabase.from('students').select('is_active').eq('department_id', deptIdInt);
        totalStudents = (r as List).length;
        activeStudents = r.where((s) => s['is_active'] == true).length;
      } catch (_) {}

      try {
        final r = await _supabase.from('faculty').select('is_active').eq('department_id', deptIdInt);
        totalFaculty = (r as List).length;
        activeFaculty = r.where((f) => f['is_active'] == true).length;
      } catch (_) {}

      Set<dynamic> deptStudentIds = {};
      try {
        final r = await _supabase.from('students').select('id').eq('department_id', deptIdInt);
        deptStudentIds = (r as List).map((s) => s['id']).toSet();
      } catch (_) {}

      int pendingDocuments = 0, pendingLeaves = 0;
      int documentsReviewedToday = 0, leavesReviewedToday = 0;

      if (deptStudentIds.isNotEmpty) {
        try {
          final r = await _supabase.from('student_documents').select('id, student_id').eq('status', 'pending');
          pendingDocuments = (r as List).where((d) => deptStudentIds.contains(d['student_id'])).length;
        } catch (_) {}

        try {
          final r = await _supabase.from('leave_applications').select('id, student_id').eq('status', 'pending');
          pendingLeaves = (r as List).where((l) => deptStudentIds.contains(l['student_id'])).length;
        } catch (_) {}

        try {
          final r = await _supabase.from('student_documents').select('id, student_id, reviewed_at')
              .not('reviewed_at', 'is', null).gte('reviewed_at', todayStart.toIso8601String());
          documentsReviewedToday = (r as List).where((d) => deptStudentIds.contains(d['student_id'])).length;
        } catch (_) {}

        try {
          final r = await _supabase.from('leave_applications').select('id, student_id, reviewed_at')
              .not('reviewed_at', 'is', null).gte('reviewed_at', todayStart.toIso8601String());
          leavesReviewedToday = (r as List).where((l) => deptStudentIds.contains(l['student_id'])).length;
        } catch (_) {}
      }

      return HODStats(
        totalStudents: totalStudents,
        activeStudents: activeStudents,
        totalFaculty: totalFaculty,
        activeFaculty: activeFaculty,
        pendingDocuments: pendingDocuments,
        pendingLeaves: pendingLeaves,
        pendingActivities: 0,
        documentsReviewedToday: documentsReviewedToday,
        leavesReviewedToday: leavesReviewedToday,
      );
    } catch (e) {
      print('❌ Error getting HOD stats: $e');
      return HODStats(
        totalStudents: 0, activeStudents: 0, totalFaculty: 0, activeFaculty: 0,
        pendingDocuments: 0, pendingLeaves: 0, pendingActivities: 0,
        documentsReviewedToday: 0, leavesReviewedToday: 0,
      );
    }
  }

  static Future<String?> getDocumentDownloadUrl(String documentUrl) async {
    try {
      if (documentUrl.startsWith('http')) return documentUrl;
      String path = documentUrl.replaceFirst('documents/', '');
      return await _supabase.storage.from('documents').createSignedUrl(path, 3600);
    } catch (e) {
      print('❌ Error getting document URL: $e');
      return null;
    }
  }
}