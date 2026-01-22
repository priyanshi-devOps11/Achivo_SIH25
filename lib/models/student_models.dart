// lib/models/student_models.dart

import 'package:intl/intl.dart';

/// Student profile with academic details
class StudentProfile {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String rollNumber;
  final String? studentId;
  final String? year;
  final String? semester;
  final String? branch;
  final double? cgpa;
  final String? phone;
  final String? gender;
  final String? fatherName;
  final DateTime? dateOfBirth;
  final int? departmentId;
  final bool isActive;

  StudentProfile({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.rollNumber,
    this.studentId,
    this.year,
    this.semester,
    this.branch,
    this.cgpa,
    this.phone,
    this.gender,
    this.fatherName,
    this.dateOfBirth,
    this.departmentId,
    required this.isActive,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      rollNumber: json['roll_number']?.toString() ?? '',
      studentId: json['student_id']?.toString(),
      year: json['year']?.toString(),
      semester: json['semester']?.toString(),
      branch: json['branch']?.toString(),
      cgpa: json['cgpa'] != null ? (json['cgpa'] as num).toDouble() : null,
      phone: json['phone']?.toString(),
      gender: json['gender']?.toString(),
      fatherName: json['father_name']?.toString(),
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'].toString())
          : null,
      departmentId: json['department_id'] != null
          ? int.tryParse(json['department_id'].toString())
          : null,
      isActive: json['is_active'] == true,
    );
  }

  String get fullName => '$firstName $lastName';

  String get displayYear => year ?? 'N/A';
}

/// Leave Application Model
class LeaveApplication {
  final int id;
  final String studentId;
  final String title;
  final String description;
  final DateTime fromDate;
  final DateTime toDate;
  final String? documentUrl;
  final String status;
  final String? hodRemarks;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;

  LeaveApplication({
    required this.id,
    required this.studentId,
    required this.title,
    required this.description,
    required this.fromDate,
    required this.toDate,
    this.documentUrl,
    required this.status,
    this.hodRemarks,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
  });

  factory LeaveApplication.fromJson(Map<String, dynamic> json) {
    return LeaveApplication(
      id: int.parse(json['id'].toString()),
      studentId: json['student_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      fromDate: DateTime.parse(json['from_date'].toString()),
      toDate: DateTime.parse(json['to_date'].toString()),
      documentUrl: json['document_url']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      hodRemarks: json['hod_remarks']?.toString(),
      approvedBy: json['approved_by']?.toString(),
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'].toString())
          : null,
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }

  String get formattedDateRange {
    final formatter = DateFormat('MMM dd, yyyy');
    return '${formatter.format(fromDate)} - ${formatter.format(toDate)}';
  }

  int get durationDays => toDate.difference(fromDate).inDays + 1;
}

/// Student Document Model
class StudentDocument {
  final int id;
  final String studentId;
  final String documentType;
  final String title;
  final String? description;
  final String documentUrl;
  final String status;
  final int pointsAwarded;
  final String? hodRemarks;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;

  StudentDocument({
    required this.id,
    required this.studentId,
    required this.documentType,
    required this.title,
    this.description,
    required this.documentUrl,
    required this.status,
    required this.pointsAwarded,
    this.hodRemarks,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
  });

  factory StudentDocument.fromJson(Map<String, dynamic> json) {
    return StudentDocument(
      id: int.parse(json['id'].toString()),
      studentId: json['student_id']?.toString() ?? '',
      documentType: json['document_type']?.toString() ?? 'other',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      documentUrl: json['document_url']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      pointsAwarded: int.tryParse(json['points_awarded']?.toString() ?? '0') ?? 0,
      hodRemarks: json['hod_remarks']?.toString(),
      approvedBy: json['approved_by']?.toString(),
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'].toString())
          : null,
      createdAt: DateTime.parse(json['created_at'].toString()),
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
}

/// Dashboard Statistics
class DashboardStats {
  final double? cgpa;
  final double attendancePercentage;
  final int creditsCompleted;
  final int totalCredits;
  final int activeClubs;
  final int pendingLeaves;
  final int approvedDocuments;

  DashboardStats({
    this.cgpa,
    required this.attendancePercentage,
    required this.creditsCompleted,
    required this.totalCredits,
    required this.activeClubs,
    required this.pendingLeaves,
    required this.approvedDocuments,
  });
}