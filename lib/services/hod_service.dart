// lib/services/hod_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/hod_models.dart';

class HODService {
  static final _supabase = Supabase.instance.client;

  // Get HOD's department ID
  static Future<BigInt?> getHODDepartmentId() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select('department_id')
          .eq('id', userId)
          .single();

      final deptId = response['department_id'];
      if (deptId == null) return null;

      return deptId is int ? BigInt.from(deptId) : (deptId is BigInt ? deptId : null);
    } catch (e) {
      print('Error getting HOD department: $e');
      return null;
    }
  }

  // Get documents for review (with student details)
  static Future<List<DocumentForReview>> getDocumentsForReview({
    BigInt? departmentId,
    String? status,
    String? documentType,
  }) async {
    try {
      if (departmentId == null) return [];

      final deptIdInt = departmentId.toInt();

      // Build query dynamically
      dynamic query = _supabase
          .from('student_documents')
          .select('''
            *,
            students!inner(
              id,
              first_name,
              last_name,
              roll_number,
              department_id
            )
          ''');

      // Apply department filter
      query = query.eq('students.department_id', deptIdInt);

      // Apply status filter
      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }

      // Apply document type filter
      if (documentType != null && documentType != 'all') {
        query = query.eq('document_type', documentType);
      }

      // Apply ordering
      query = query.order('created_at', ascending: false);

      final response = await query;

      return (response as List).map((doc) {
        final student = doc['students'] as Map<String, dynamic>;
        final studentName = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim();
        final rollNumber = student['roll_number'] ?? 'N/A';

        return DocumentForReview.fromMap(doc, studentName, rollNumber);
      }).toList();
    } catch (e) {
      print('Error loading documents: $e');
      return [];
    }
  }

  // Get leaves for review
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
            students!inner(
              id,
              first_name,
              last_name,
              roll_number,
              department_id
            )
          ''');

      query = query.eq('students.department_id', deptIdInt);

      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }

      query = query.order('created_at', ascending: false);

      final response = await query;

      return (response as List).map((leave) {
        final student = leave['students'] as Map<String, dynamic>;
        final studentName = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim();
        final rollNumber = student['roll_number'] ?? 'N/A';

        return LeaveForReview.fromMap(leave, studentName, rollNumber);
      }).toList();
    } catch (e) {
      print('Error loading leaves: $e');
      return [];
    }
  }

  // Approve/Reject Document
  static Future<bool> reviewDocument({
    required String documentId,
    required String action, // 'approve' or 'reject'
    String? remarks,
    int pointsAwarded = 0,
  }) async {
    try {
      final hodUserId = _supabase.auth.currentUser?.id;
      if (hodUserId == null) return false;

      // Get HOD's ID from hods table
      final hodResponse = await _supabase
          .from('hods')
          .select('id')
          .eq('user_id', hodUserId)
          .maybeSingle();

      if (hodResponse == null) {
        print('HOD record not found for user: $hodUserId');
        return false;
      }

      final hodId = hodResponse['id'];

      await _supabase.from('student_documents').update({
        'status': action == 'approve' ? 'approved' : 'rejected',
        'hod_remarks': remarks,
        'points_awarded': action == 'approve' ? pointsAwarded : 0,
        'reviewed_by': hodId,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', int.parse(documentId));

      return true;
    } catch (e) {
      print('Error reviewing document: $e');
      return false;
    }
  }

  // Approve/Reject Leave
  static Future<bool> reviewLeave({
    required String leaveId,
    required String action,
    String? remarks,
  }) async {
    try {
      final hodUserId = _supabase.auth.currentUser?.id;
      if (hodUserId == null) return false;

      final hodResponse = await _supabase
          .from('hods')
          .select('id')
          .eq('user_id', hodUserId)
          .maybeSingle();

      if (hodResponse == null) {
        print('HOD record not found for user: $hodUserId');
        return false;
      }

      final hodId = hodResponse['id'];

      await _supabase.from('leave_applications').update({
        'status': action == 'approve' ? 'approved' : 'rejected',
        'hod_remarks': remarks,
        'reviewed_by': hodId,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', int.parse(leaveId));

      return true;
    } catch (e) {
      print('Error reviewing leave: $e');
      return false;
    }
  }

  // Get HOD stats
  static Future<HODStats> getHODStats(BigInt departmentId) async {
    try {
      final deptIdInt = departmentId.toInt();
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      // Students count
      final studentsResponse = await _supabase
          .from('students')
          .select('is_active')
          .eq('department_id', deptIdInt);

      final totalStudents = studentsResponse.length;
      final activeStudents = (studentsResponse as List)
          .where((s) => s['is_active'] == true)
          .length;

      // Faculty count
      final facultyResponse = await _supabase
          .from('faculty')
          .select('is_active')
          .eq('department_id', deptIdInt);

      final totalFaculty = facultyResponse.length;
      final activeFaculty = (facultyResponse as List)
          .where((f) => f['is_active'] == true)
          .length;

      // Pending documents
      final pendingDocsResponse = await _supabase
          .from('student_documents')
          .select('id, student_id')
          .eq('status', 'pending');

      // Filter by department (need to check student's department)
      final studentIds = await _supabase
          .from('students')
          .select('id')
          .eq('department_id', deptIdInt);

      final deptStudentIds = (studentIds as List).map((s) => s['id']).toSet();

      final pendingDocuments = (pendingDocsResponse as List)
          .where((doc) => deptStudentIds.contains(doc['student_id']))
          .length;

      // Pending leaves
      final pendingLeavesResponse = await _supabase
          .from('leave_applications')
          .select('id, student_id')
          .eq('status', 'pending');

      final pendingLeaves = (pendingLeavesResponse as List)
          .where((leave) => deptStudentIds.contains(leave['student_id']))
          .length;

      // Pending activities
      final pendingActivitiesResponse = await _supabase
          .from('activities')
          .select('id, student_id')
          .eq('status', 'pending');

      final pendingActivities = (pendingActivitiesResponse as List)
          .where((activity) => deptStudentIds.contains(activity['student_id']))
          .length;

      // Documents reviewed today
      final docsReviewedTodayResponse = await _supabase
          .from('student_documents')
          .select('id, student_id')
          .gte('reviewed_at', todayStart.toIso8601String());

      final documentsReviewedToday = (docsReviewedTodayResponse as List)
          .where((doc) => deptStudentIds.contains(doc['student_id']))
          .length;

      // Leaves reviewed today
      final leavesReviewedTodayResponse = await _supabase
          .from('leave_applications')
          .select('id, student_id')
          .gte('reviewed_at', todayStart.toIso8601String());

      final leavesReviewedToday = (leavesReviewedTodayResponse as List)
          .where((leave) => deptStudentIds.contains(leave['student_id']))
          .length;

      return HODStats(
        totalStudents: totalStudents,
        activeStudents: activeStudents,
        totalFaculty: totalFaculty,
        activeFaculty: activeFaculty,
        pendingDocuments: pendingDocuments,
        pendingLeaves: pendingLeaves,
        pendingActivities: pendingActivities,
        documentsReviewedToday: documentsReviewedToday,
        leavesReviewedToday: leavesReviewedToday,
      );
    } catch (e) {
      print('Error getting HOD stats: $e');
      return HODStats(
        totalStudents: 0,
        activeStudents: 0,
        totalFaculty: 0,
        activeFaculty: 0,
        pendingDocuments: 0,
        pendingLeaves: 0,
        pendingActivities: 0,
        documentsReviewedToday: 0,
        leavesReviewedToday: 0,
      );
    }
  }

  // Get document URL for preview
  static Future<String?> getDocumentDownloadUrl(String documentUrl) async {
    try {
      // If it's already a full URL, return it
      if (documentUrl.startsWith('http')) {
        return documentUrl;
      }

      // If it starts with bucket name, strip it
      String path = documentUrl;
      if (path.startsWith('student-documents/')) {
        path = path.replaceFirst('student-documents/', '');
      }

      final signedUrl = await _supabase.storage
          .from('student-documents')
          .createSignedUrl(path, 3600);

      return signedUrl;
    } catch (e) {
      print('Error getting document URL: $e');
      return null;
    }
  }
}