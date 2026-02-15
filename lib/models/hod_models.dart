// lib/models/hod_models.dart

import 'package:intl/intl.dart'; // <-- IMPORTANT: Add this import

class DocumentForReview {
  final String id;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String documentType;
  final String title;
  final String? description;
  final String documentUrl;
  final String status;
  final int pointsAwarded;
  final String? hodRemarks;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? fileName;
  final int? fileSize;
  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentForReview({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.documentType,
    required this.title,
    this.description,
    required this.documentUrl,
    required this.status,
    required this.pointsAwarded,
    this.hodRemarks,
    this.reviewedBy,
    this.reviewedAt,
    this.fileName,
    this.fileSize,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentForReview.fromMap(Map<String, dynamic> map, String studentName, String rollNumber) {
    return DocumentForReview(
      id: map['id'].toString(),
      studentId: map['student_id'].toString(),
      studentName: studentName,
      rollNumber: rollNumber,
      documentType: map['document_type'] ?? 'other',
      title: map['title'] ?? 'Untitled',
      description: map['description'],
      documentUrl: map['document_url'] ?? '',
      status: map['status'] ?? 'pending',
      pointsAwarded: map['points_awarded'] ?? 0,
      hodRemarks: map['hod_remarks'],
      reviewedBy: map['reviewed_by']?.toString(),
      reviewedAt: map['reviewed_at'] != null ? DateTime.parse(map['reviewed_at']) : null,
      fileName: map['file_name'],
      fileSize: map['file_size'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get displayType {
    switch (documentType) {
      case 'technical_skill':
        return 'Technical Skill';
      case 'internship':
        return 'Internship';
      case 'seminar':
        return 'Seminar';
      case 'certification':
        return 'Certification';
      default:
        return 'Other';
    }
  }

  String get formattedFileSize {
    if (fileSize == null) return 'Unknown';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
}

class LeaveForReview {
  final String id;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String title;
  final String description;
  final DateTime fromDate;
  final DateTime toDate;
  final int durationDays;
  final String? documentUrl;
  final String status;
  final String? hodRemarks;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  LeaveForReview({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.title,
    required this.description,
    required this.fromDate,
    required this.toDate,
    required this.durationDays,
    this.documentUrl,
    required this.status,
    this.hodRemarks,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
  });

  factory LeaveForReview.fromMap(Map<String, dynamic> map, String studentName, String rollNumber) {
    return LeaveForReview(
      id: map['id'].toString(),
      studentId: map['student_id'].toString(),
      studentName: studentName,
      rollNumber: rollNumber,
      title: map['title'] ?? 'Untitled',
      description: map['description'] ?? '',
      fromDate: DateTime.parse(map['from_date']),
      toDate: DateTime.parse(map['to_date']),
      durationDays: map['duration_days'] ?? 0,
      documentUrl: map['document_url'],
      status: map['status'] ?? 'pending',
      hodRemarks: map['hod_remarks'],
      reviewedBy: map['reviewed_by']?.toString(),
      reviewedAt: map['reviewed_at'] != null ? DateTime.parse(map['reviewed_at']) : null,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get formattedDateRange {
    final formatter = DateFormat('MMM dd, yyyy');
    return '${formatter.format(fromDate)} - ${formatter.format(toDate)}';
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
}

class HODStats {
  final int totalStudents;
  final int activeStudents;
  final int totalFaculty;
  final int activeFaculty;
  final int pendingDocuments;
  final int pendingLeaves;
  final int pendingActivities;
  final int documentsReviewedToday;
  final int leavesReviewedToday;

  HODStats({
    required this.totalStudents,
    required this.activeStudents,
    required this.totalFaculty,
    required this.activeFaculty,
    required this.pendingDocuments,
    required this.pendingLeaves,
    required this.pendingActivities,
    required this.documentsReviewedToday,
    required this.leavesReviewedToday,
  });

  int get totalPendingItems => pendingDocuments + pendingLeaves + pendingActivities;
  int get totalReviewedToday => documentsReviewedToday + leavesReviewedToday;
}