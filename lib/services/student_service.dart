// lib/services/student_service.dart

import 'dart:io';
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
      if (user == null) {
        print('❌ No authenticated user');
        return null;
      }

      print('🔍 Fetching student profile for user: ${user.id}');

      final response = await _supabase
          .from('students')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        print('❌ No student profile found');
        return null;
      }

      print('✅ Student profile loaded: ${response['first_name']} ${response['last_name']}');
      return StudentProfile.fromJson(response);
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
      // Fetch attendance data
      final attendanceData = await _supabase
          .from('attendance')
          .select('status')
          .eq('student_id', studentId);

      int present = 0, total = 0;
      for (var record in attendanceData) {
        total++;
        if (record['status'] == 'present') present++;
      }
      final attendancePercentage = total > 0 ? (present / total) * 100 : 0.0;

      // Fetch course enrollments for credits
      final enrollments = await _supabase
          .from('course_enrollments')
          .select('course_id, status')
          .eq('student_id', studentId);

      final courseIds = enrollments
          .where((e) => e['status'] == 'completed')
          .map((e) => e['course_id'])
          .toList();

      int creditsCompleted = 0;
      if (courseIds.isNotEmpty) {
        final courses = await _supabase
            .from('courses')
            .select('credits')
            .filter('id', 'in', courseIds);

        creditsCompleted = courses.fold<int>(
          0,
              (sum, course) => sum + (int.tryParse(course['credits']?.toString() ?? '0') ?? 0),
        );
      }

      // Fetch pending leaves
      final leaves = await _supabase
          .from('leave_applications')
          .select('id')
          .eq('student_id', studentId)
          .eq('status', 'pending');

      // Fetch approved documents
      final documents = await _supabase
          .from('student_documents')
          .select('id')
          .eq('student_id', studentId)
          .eq('status', 'approved');

      // Get student CGPA
      final student = await _supabase
          .from('students')
          .select('cgpa')
          .eq('id', studentId)
          .single();

      return DashboardStats(
        cgpa: student['cgpa'] != null ? (student['cgpa'] as num).toDouble() : null,
        attendancePercentage: attendancePercentage,
        creditsCompleted: creditsCompleted,
        totalCredits: 180, // Default total credits (adjust as needed)
        activeClubs: 3, // TODO: Link to clubs table when available
        pendingLeaves: leaves.length,
        approvedDocuments: documents.length,
      );
    } catch (e) {
      print('❌ Error fetching dashboard stats: $e');
      return DashboardStats(
        attendancePercentage: 0,
        creditsCompleted: 0,
        totalCredits: 180,
        activeClubs: 0,
        pendingLeaves: 0,
        approvedDocuments: 0,
      );
    }
  }

  // ================================
  // LEAVE APPLICATIONS
  // ================================

  static Future<List<LeaveApplication>> getLeaveApplications(String studentId) async {
    try {
      final response = await _supabase
          .from('leave_applications')
          .select()
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => LeaveApplication.fromJson(data))
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
    File? document,
  }) async {
    try {
      String? documentUrl;

      // Upload document if provided
      if (document != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${document.path.split('/').last}';
        final filePath = 'leaves/$studentId/$fileName';

        await _supabase.storage
            .from('documents')
            .upload(filePath, document);

        documentUrl = _supabase.storage
            .from('documents')
            .getPublicUrl(filePath);
      }

      // Insert leave application
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
          .map((data) => StudentDocument.fromJson(data))
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
    required File document,
  }) async {
    try {
      // Upload document
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${document.path.split('/').last}';
      final filePath = 'student_documents/$studentId/$fileName';

      await _supabase.storage
          .from('documents')
          .upload(filePath, document);

      final documentUrl = _supabase.storage
          .from('documents')
          .getPublicUrl(filePath);

      // Insert document record
      await _supabase.from('student_documents').insert({
        'student_id': studentId,
        'document_type': documentType,
        'title': title,
        'description': description,
        'document_url': documentUrl,
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

  // ================================
  // STORAGE BUCKET CREATION (Run once)
  // ================================

  static Future<void> ensureStorageBuckets() async {
    try {
      // Check if 'documents' bucket exists, create if not
      final buckets = await _supabase.storage.listBuckets();
      final hasDocumentsBucket = buckets.any((b) => b.name == 'documents');

      if (!hasDocumentsBucket) {
        await _supabase.storage.createBucket(
          'documents',
          const BucketOptions(public: true),
        );
        print('✅ Created documents storage bucket');
      }
    } catch (e) {
      print('⚠️ Storage bucket check: $e');
    }
  }
}