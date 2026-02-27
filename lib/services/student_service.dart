// lib/services/student_service.dart
// Web-compatible version - uses Uint8List instead of dart:io File

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
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
      // Fetch pending leaves
      final leaves = await _supabase
          .from('leave_applications')
          .select('id')
          .eq('student_id', studentId)
          .eq('status', 'pending');

      // Fetch approved documents
      final documents = await _supabase
          .from('student_documents')
          .select('id, points_awarded')
          .eq('student_id', studentId)
          .eq('status', 'approved');

      // Get student CGPA
      final student = await _supabase
          .from('students')
          .select('cgpa')
          .eq('id', studentId)
          .maybeSingle();

      // Calculate total points from approved docs
      int totalPoints = 0;
      for (var doc in (documents as List)) {
        totalPoints += (doc['points_awarded'] as int? ?? 0);
      }

      return DashboardStats(
        cgpa: student?['cgpa'] != null
            ? (student!['cgpa'] as num).toDouble()
            : null,
        attendancePercentage: 0,
        creditsCompleted: totalPoints,
        totalCredits: 150,
        activeClubs: 0,
        pendingLeaves: (leaves as List).length,
        approvedDocuments: (documents as List).length,
      );
    } catch (e) {
      print('❌ Error fetching dashboard stats: $e');
      return DashboardStats(
        attendancePercentage: 0,
        creditsCompleted: 0,
        totalCredits: 150,
        activeClubs: 0,
        pendingLeaves: 0,
        approvedDocuments: 0,
      );
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
          .map((data) => LeaveApplication.fromJson(data))
          .toList();
    } catch (e) {
      print('❌ Error fetching leave applications: $e');
      return [];
    }
  }

  /// Submit leave application.
  /// [fileBytes] and [fileName] come from FilePicker (web-compatible).
  static Future<bool> submitLeaveApplication({
    required String studentId,
    required String title,
    required String description,
    required DateTime fromDate,
    required DateTime toDate,
    Uint8List? fileBytes,   // ← web-safe, replaces File
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

  /// Upload student document.
  /// [fileBytes] and [fileName] come from FilePicker (web-compatible).
  static Future<bool> uploadStudentDocument({
    required String studentId,
    required String documentType,
    required String title,
    String? description,
    required Uint8List fileBytes,  // ← web-safe
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

  // ================================
  // STORAGE BUCKET CHECK
  // ================================

  static Future<void> ensureStorageBuckets() async {
    // Buckets are created via SQL/dashboard.
    // This just silently verifies without crashing on web.
    try {
      await _supabase.storage.getBucket('documents');
      print('✅ Storage bucket "documents" is ready');
    } catch (e) {
      print('⚠️ Storage bucket check: $e');
      // Don't crash — bucket may still work fine
    }
  }
}