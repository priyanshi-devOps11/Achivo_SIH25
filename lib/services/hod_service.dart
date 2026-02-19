// lib/services/hod_service.dart
// PRODUCTION VERSION - Handles missing data gracefully

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hod_models.dart';

class HODService {
  static final _supabase = Supabase.instance.client;

  /// Get HOD's department ID with proper error handling
  static Future<BigInt?> getHODDepartmentId() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('⚠️ No authenticated user');
        return null;
      }

      // First try to get from profiles
      final profileResponse = await _supabase
          .from('profiles')
          .select('department_id')
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse == null) {
        print('⚠️ No profile found for user: $userId');
        return null;
      }

      final deptId = profileResponse['department_id'];
      if (deptId == null) {
        print('⚠️ No department assigned to profile');
        return null;
      }

      return deptId is int ? BigInt.from(deptId) : (deptId is BigInt ? deptId : null);
    } catch (e) {
      print('❌ Error getting HOD department: $e');
      return null;
    }
  }

  /// Verify HOD record exists, create if missing (for existing users)
  static Future<bool> ensureHODRecordExists() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Check if HOD record exists
      final hodRecord = await _supabase
          .from('hods')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (hodRecord != null) {
        print('✅ HOD record exists');
        return true;
      }

      // HOD record missing - check profile
      final profile = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null || profile['role'] != 'hod') {
        print('❌ User is not an HOD or profile missing');
        return false;
      }

      // Create HOD record
      print('⚠️ HOD record missing, creating...');

      // Generate HOD ID
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

  /// Get documents with robust error handling
  static Future<List<DocumentForReview>> getDocumentsForReview({
    BigInt? departmentId,
    String? status,
    String? documentType,
  }) async {
    try {
      if (departmentId == null) {
        print('⚠️ No department ID provided');
        return [];
      }

      final deptIdInt = departmentId.toInt();

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

      query = query.eq('students.department_id', deptIdInt);

      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }

      if (documentType != null && documentType != 'all') {
        query = query.eq('document_type', documentType);
      }

      query = query.order('created_at', ascending: false);

      final response = await query;

      if (response == null || response.isEmpty) {
        print('ℹ️ No documents found for department $deptIdInt');
        return [];
      }

      return (response as List).map((doc) {
        final student = doc['students'] as Map<String, dynamic>;
        final studentName = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim();
        final rollNumber = student['roll_number'] ?? 'N/A';

        return DocumentForReview.fromMap(doc, studentName, rollNumber);
      }).toList();
    } catch (e) {
      print('❌ Error loading documents: $e');
      return [];
    }
  }

  /// Get leaves with robust error handling
  static Future<List<LeaveForReview>> getLeavesForReview({
    BigInt? departmentId,
    String? status,
  }) async {
    try {
      if (departmentId == null) {
        print('⚠️ No department ID provided');
        return [];
      }

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

      if (response == null || response.isEmpty) {
        print('ℹ️ No leave applications found for department $deptIdInt');
        return [];
      }

      return (response as List).map((leave) {
        final student = leave['students'] as Map<String, dynamic>;
        final studentName = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim();
        final rollNumber = student['roll_number'] ?? 'N/A';

        return LeaveForReview.fromMap(leave, studentName, rollNumber);
      }).toList();
    } catch (e) {
      print('❌ Error loading leaves: $e');
      return [];
    }
  }

  /// Review document with validation
  static Future<bool> reviewDocument({
    required String documentId,
    required String action,
    String? remarks,
    int pointsAwarded = 0,
  }) async {
    try {
      final hodUserId = _supabase.auth.currentUser?.id;
      if (hodUserId == null) {
        print('❌ No authenticated user');
        return false;
      }

      // Get HOD's ID from hods table
      final hodResponse = await _supabase
          .from('hods')
          .select('id')
          .eq('user_id', hodUserId)
          .maybeSingle();

      if (hodResponse == null) {
        print('❌ HOD record not found. Creating...');
        await ensureHODRecordExists();

        // Retry after creating
        final retryHodResponse = await _supabase
            .from('hods')
            .select('id')
            .eq('user_id', hodUserId)
            .maybeSingle();

        if (retryHodResponse == null) {
          print('❌ Failed to create HOD record');
          return false;
        }
      }

      final hodId = hodResponse?['id'];

      final updateData = {
        'status': action == 'approve' ? 'approved' : 'rejected',
        'hod_remarks': remarks,
        'points_awarded': action == 'approve' ? pointsAwarded : 0,
        'reviewed_by': hodId,
        'reviewed_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('student_documents')
          .update(updateData)
          .eq('id', int.parse(documentId));

      print('✅ Document $documentId ${action}ed successfully');
      return true;
    } catch (e) {
      print('❌ Error reviewing document: $e');
      return false;
    }
  }

  /// Review leave with validation
  static Future<bool> reviewLeave({
    required String leaveId,
    required String action,
    String? remarks,
  }) async {
    try {
      final hodUserId = _supabase.auth.currentUser?.id;
      if (hodUserId == null) {
        print('❌ No authenticated user');
        return false;
      }

      final hodResponse = await _supabase
          .from('hods')
          .select('id')
          .eq('user_id', hodUserId)
          .maybeSingle();

      if (hodResponse == null) {
        print('❌ HOD record not found');
        await ensureHODRecordExists();
        return false;
      }

      final hodId = hodResponse['id'];

      final updateData = {
        'status': action == 'approve' ? 'approved' : 'rejected',
        'hod_remarks': remarks,
        'reviewed_by': hodId,
        'reviewed_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('leave_applications')
          .update(updateData)
          .eq('id', int.parse(leaveId));

      print('✅ Leave $leaveId ${action}ed successfully');
      return true;
    } catch (e) {
      print('❌ Error reviewing leave: $e');
      return false;
    }
  }

  /// Get HOD stats with fallback values
  static Future<HODStats> getHODStats(BigInt departmentId) async {
    try {
      final deptIdInt = departmentId.toInt();
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      // Students count with error handling
      int totalStudents = 0;
      int activeStudents = 0;

      try {
        final studentsResponse = await _supabase
            .from('students')
            .select('is_active')
            .eq('department_id', deptIdInt);

        totalStudents = studentsResponse.length;
        activeStudents = (studentsResponse as List)
            .where((s) => s['is_active'] == true)
            .length;
      } catch (e) {
        print('⚠️ Error fetching students: $e');
      }

      // Faculty count with error handling
      int totalFaculty = 0;
      int activeFaculty = 0;

      try {
        final facultyResponse = await _supabase
            .from('faculty')
            .select('is_active')
            .eq('department_id', deptIdInt);

        totalFaculty = facultyResponse.length;
        activeFaculty = (facultyResponse as List)
            .where((f) => f['is_active'] == true)
            .length;
      } catch (e) {
        print('⚠️ Error fetching faculty: $e');
      }

      // Get student IDs for department
      Set<dynamic> deptStudentIds = {};
      try {
        final studentIds = await _supabase
            .from('students')
            .select('id')
            .eq('department_id', deptIdInt);
        deptStudentIds = (studentIds as List).map((s) => s['id']).toSet();
      } catch (e) {
        print('⚠️ Error fetching student IDs: $e');
      }

      // Pending counts
      int pendingDocuments = 0;
      int pendingLeaves = 0;
      int pendingActivities = 0;
      int documentsReviewedToday = 0;
      int leavesReviewedToday = 0;

      if (deptStudentIds.isNotEmpty) {
        try {
          final pendingDocsResponse = await _supabase
              .from('student_documents')
              .select('id, student_id')
              .eq('status', 'pending');

          pendingDocuments = (pendingDocsResponse as List)
              .where((doc) => deptStudentIds.contains(doc['student_id']))
              .length;
        } catch (e) {
          print('⚠️ Error fetching pending documents: $e');
        }

        try {
          final pendingLeavesResponse = await _supabase
              .from('leave_applications')
              .select('id, student_id')
              .eq('status', 'pending');

          pendingLeaves = (pendingLeavesResponse as List)
              .where((leave) => deptStudentIds.contains(leave['student_id']))
              .length;
        } catch (e) {
          print('⚠️ Error fetching pending leaves: $e');
        }

        try {
          final pendingActivitiesResponse = await _supabase
              .from('activities')
              .select('id, student_id')
              .eq('status', 'pending');

          pendingActivities = (pendingActivitiesResponse as List)
              .where((activity) => deptStudentIds.contains(activity['student_id']))
              .length;
        } catch (e) {
          print('⚠️ Error fetching pending activities: $e');
        }

        try {
          final docsReviewedTodayResponse = await _supabase
              .from('student_documents')
              .select('id, student_id, reviewed_at')
              .not('reviewed_at', 'is', null)
              .gte('reviewed_at', todayStart.toIso8601String());

          documentsReviewedToday = (docsReviewedTodayResponse as List)
              .where((doc) => deptStudentIds.contains(doc['student_id']))
              .length;
        } catch (e) {
          print('⚠️ Error fetching documents reviewed today: $e');
        }

        try {
          final leavesReviewedTodayResponse = await _supabase
              .from('leave_applications')
              .select('id, student_id, reviewed_at')
              .not('reviewed_at', 'is', null)
              .gte('reviewed_at', todayStart.toIso8601String());

          leavesReviewedToday = (leavesReviewedTodayResponse as List)
              .where((leave) => deptStudentIds.contains(leave['student_id']))
              .length;
        } catch (e) {
          print('⚠️ Error fetching leaves reviewed today: $e');
        }
      }

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
      print('❌ Error getting HOD stats: $e');
      // Return zeros instead of crashing
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

  /// Get document URL for preview
  static Future<String?> getDocumentDownloadUrl(String documentUrl) async {
    try {
      if (documentUrl.startsWith('http')) {
        return documentUrl;
      }

      String path = documentUrl;
      if (path.startsWith('student-documents/')) {
        path = path.replaceFirst('student-documents/', '');
      }

      final signedUrl = await _supabase.storage
          .from('student-documents')
          .createSignedUrl(path, 3600);

      return signedUrl;
    } catch (e) {
      print('❌ Error getting document URL: $e');
      return null;
    }
  }
}