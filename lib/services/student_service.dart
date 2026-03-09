// lib/services/student_service.dart
// Web-compatible version - uses Uint8List instead of dart:io File

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_models.dart';

class StudentService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ================================
  // STUDENT PROFILE
  // ================================

  static Future<StudentProfile?> getCurrentStudentProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      print('🔍 Fetching student profile for user: ${user.id}');

      final response = await _supabase
          .from('students')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) return null;

      print('✅ Student profile loaded: ${response['first_name']} ${response['last_name']}');
      return StudentProfile.fromMap(response);
    } catch (e) {
      print('❌ Error fetching student profile: $e');
      return null;
    }
  }

  // ================================
  // DASHBOARD STATISTICS
  // ================================

  static Future<DashboardStats> getDashboardStats(String studentId) async {
    try {
      // --- Leaves ---
      final leaves = await _supabase
          .from('leave_applications')
          .select('id, status')
          .eq('student_id', studentId);

      // --- Documents / credits ---
      final documents = await _supabase
          .from('student_documents')
          .select('id, points_awarded, status')
          .eq('student_id', studentId);

      // --- CGPA from students table ---
      final student = await _supabase
          .from('students')
          .select('cgpa')
          .eq('id', studentId)
          .maybeSingle();

      // --- Real attendance from attendance table ---
      final attendanceRows = await _supabase
          .from('attendance')
          .select('status')
          .eq('student_id', studentId);

      final leaveList = (leaves as List);
      final docList   = (documents as List);
      final attList   = (attendanceRows as List);

      // Attendance percentage (present + late count as attended)
      double attendancePct = 0.0;
      if (attList.isNotEmpty) {
        final attended = attList
            .where((r) => r['status'] == 'present' || r['status'] == 'late')
            .length;
        attendancePct = (attended / attList.length) * 100;
      }

      final pendingLeaves  = leaveList.where((l) => l['status'] == 'pending').length;
      final approvedLeaves = leaveList.where((l) => l['status'] == 'approved').length;
      final pendingDocs    = docList.where((d) => d['status'] == 'pending').length;
      final approvedDocs   = docList.where((d) => d['status'] == 'approved').toList();

      int totalPoints = 0;
      for (var doc in approvedDocs) {
        totalPoints += (doc['points_awarded'] as int? ?? 0);
      }

      return DashboardStats(
        cgpa: student?['cgpa'] != null
            ? (student!['cgpa'] as num).toDouble()
            : null,
        attendancePercentage: attendancePct,
        creditsCompleted: totalPoints,
        totalCredits: 150,
        pendingLeaves:     pendingLeaves,
        approvedLeaves:    approvedLeaves,
        pendingDocuments:  pendingDocs,
        approvedDocuments: approvedDocs.length,
      );
    } catch (e) {
      print('❌ Error fetching dashboard stats: $e');
      return DashboardStats.empty();
    }
  }

  // ================================
  // LEAVE APPLICATIONS
  // ================================

  static Future<List<LeaveApplication>> getLeaveApplications(
      String studentId) async {
    try {
      final response = await _supabase
          .from('leave_applications')
          .select()
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => LeaveApplication.fromMap(data))
          .toList();
    } catch (e) {
      print('❌ Error fetching leave applications: $e');
      return [];
    }
  }

  static Future<bool> submitLeaveApplication({
    required String studentId,
    required String title,
    required String description,
    required DateTime fromDate,
    required DateTime toDate,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    try {
      String? documentUrl;

      if (fileBytes != null && fileName != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final safeName = fileName.replaceAll(' ', '_');
        final storagePath = 'leaves/$studentId/${timestamp}_$safeName';

        await _supabase.storage.from('documents').uploadBinary(
          storagePath,
          fileBytes,
          fileOptions: const FileOptions(
            contentType: 'application/pdf',
            upsert: false,
          ),
        );

        documentUrl = _supabase.storage
            .from('documents')
            .getPublicUrl(storagePath);
      }

      await _supabase.from('leave_applications').insert({
        'student_id': studentId,
        'title': title,
        'description': description,
        'from_date': fromDate.toIso8601String().split('T')[0],
        'to_date': toDate.toIso8601String().split('T')[0],
        'document_url': documentUrl,
        'status': 'pending',
      });

      print('✅ Leave application submitted successfully');
      return true;
    } catch (e) {
      print('❌ Error submitting leave application: $e');
      return false;
    }
  }

  static Future<bool> deleteLeaveApplication({
    required String leaveId,
    required String studentId,
    String? documentUrl,
  }) async {
    try {
      final leave = await _supabase
          .from('leave_applications')
          .select('status, document_url')
          .eq('id', int.parse(leaveId))
          .eq('student_id', studentId)
          .maybeSingle();

      if (leave == null) {
        print('❌ Leave not found');
        return false;
      }
      if (leave['status'] != 'pending') {
        print('❌ Cannot delete: leave is already ${leave['status']}');
        return false;
      }

      await _supabase
          .from('leave_applications')
          .delete()
          .eq('id', int.parse(leaveId))
          .eq('student_id', studentId)
          .eq('status', 'pending');

      print('✅ Leave $leaveId deleted');
      _deleteStorageFile(documentUrl ?? leave['document_url'] as String?);
      return true;
    } catch (e) {
      print('❌ Error deleting leave: $e');
      return false;
    }
  }

  // ================================
  // STUDENT DOCUMENTS
  // ================================

  static Future<List<StudentDocument>> getStudentDocuments(
      String studentId, {
        String? documentType,
      }) async {
    try {
      var query = _supabase
          .from('student_documents')
          .select()
          .eq('student_id', studentId);

      if (documentType != null) {
        query = query.eq('document_type', documentType);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((data) => StudentDocument.fromMap(data))
          .toList();
    } catch (e) {
      print('❌ Error fetching student documents: $e');
      return [];
    }
  }

  static Future<bool> uploadStudentDocument({
    required String studentId,
    required String documentType,
    required String title,
    String? description,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = fileName.replaceAll(' ', '_');
      final storagePath = 'student_documents/$studentId/${timestamp}_$safeName';

      await _supabase.storage.from('documents').uploadBinary(
        storagePath,
        fileBytes,
        fileOptions: const FileOptions(
          contentType: 'application/pdf',
          upsert: false,
        ),
      );

      final documentUrl = _supabase.storage
          .from('documents')
          .getPublicUrl(storagePath);

      await _supabase.from('student_documents').insert({
        'student_id': studentId,
        'document_type': documentType,
        'title': title,
        'description': description,
        'document_url': documentUrl,
        'file_name': fileName,
        'file_size': fileBytes.length,
        'status': 'pending',
        'points_awarded': 0,
      });

      print('✅ Document uploaded successfully');
      return true;
    } catch (e) {
      print('❌ Error uploading document: $e');
      return false;
    }
  }

  static Future<bool> deleteStudentDocument({
    required String documentId,
    required String studentId,
    String? documentUrl,
  }) async {
    try {
      final doc = await _supabase
          .from('student_documents')
          .select('status, document_url')
          .eq('id', int.parse(documentId))
          .eq('student_id', studentId)
          .maybeSingle();

      if (doc == null) {
        print('❌ Document not found');
        return false;
      }
      if (doc['status'] != 'pending') {
        print('❌ Cannot delete: document is already ${doc['status']}');
        return false;
      }

      await _supabase
          .from('student_documents')
          .delete()
          .eq('id', int.parse(documentId))
          .eq('student_id', studentId)
          .eq('status', 'pending');

      print('✅ Document $documentId deleted');
      _deleteStorageFile(documentUrl ?? doc['document_url'] as String?);
      return true;
    } catch (e) {
      print('❌ Error deleting document: $e');
      return false;
    }
  }

  // ================================
  // ATTENDANCE
  // ================================

  static Future<List<AttendanceRecord>> getAttendanceRecords(
      String studentId) async {
    try {
      final response = await _supabase
          .from('attendance')
          .select(
        'id, student_id, course_id, date, status, '
            'courses(course_name, faculty(first_name, last_name))',
      )
          .eq('student_id', studentId)
          .order('date', ascending: false);

      return (response as List)
          .map((m) => AttendanceRecord.fromMap(m))
          .toList();
    } catch (e) {
      print('❌ Error fetching attendance: $e');
      return [];
    }
  }

  static Future<List<SubjectAttendance>> getSubjectAttendanceSummary(
      String studentId) async {
    final records = await getAttendanceRecords(studentId);

    final Map<int, List<AttendanceRecord>> grouped = {};
    for (final r in records) {
      final key = r.courseId ?? -1;
      grouped.putIfAbsent(key, () => []).add(r);
    }

    final summaries = <SubjectAttendance>[];
    grouped.forEach((courseId, recs) {
      summaries.add(SubjectAttendance(
        courseId: courseId,
        courseName: recs.first.courseName,
        facultyName: recs.first.facultyName,
        total:   recs.length,
        present: recs.where((r) => r.status == 'present').length,
        absent:  recs.where((r) => r.status == 'absent').length,
        leave:   recs.where((r) => r.status == 'leave').length,
        late:    recs.where((r) => r.status == 'late').length,
      ));
    });

    summaries.sort((a, b) => a.courseName.compareTo(b.courseName));
    return summaries;
  }

  // ================================
  // MARKS
  // ================================

  static Future<List<SubjectMarks>> getSubjectMarks(
      String studentId) async {
    try {
      final response = await _supabase
          .from('course_enrollments')
          .select(
        'id, course_id, internal_marks, external_marks, marks, grade, status, '
            'courses(course_name, faculty(first_name, last_name))',
      )
          .eq('student_id', studentId)
          .order('course_id', ascending: true);

      return (response as List)
          .map((m) => SubjectMarks.fromMap(m))
          .toList();
    } catch (e) {
      print('❌ Error fetching marks: $e');
      return [];
    }
  }

  // ================================
  // STORAGE HELPERS
  // ================================

  static Future<void> ensureStorageBuckets() async {
    try {
      await _supabase.storage.getBucket('documents');
      print('✅ Storage bucket "documents" is ready');
    } catch (e) {
      print('⚠️ Storage bucket check: $e');
    }
  }

  static void _deleteStorageFile(String? url) {
    if (url == null || url.isEmpty) return;
    Future(() async {
      try {
        final uri = Uri.parse(url);
        final segments = uri.pathSegments;
        final bucketIndex = segments.indexOf('documents');
        if (bucketIndex != -1 && bucketIndex + 1 < segments.length) {
          final storagePath = segments.sublist(bucketIndex + 1).join('/');
          await _supabase.storage.from('documents').remove([storagePath]);
          print('✅ Storage file deleted: $storagePath');
        }
      } catch (e) {
        print('⚠️ Could not delete storage file (non-fatal): $e');
      }
    });
  }
}