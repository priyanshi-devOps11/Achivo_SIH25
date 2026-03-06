// lib/models/student_models.dart

import 'package:intl/intl.dart';

// ─────────────────────────────────────────────
// ATTENDANCE RECORD (one class session)
// ─────────────────────────────────────────────

class AttendanceRecord {
  final int id;
  final String studentId;
  final int? courseId;
  final String courseName;    // joined from courses table
  final String? facultyName;  // joined from faculty table
  final DateTime date;
  final String status;        // present | absent | leave | late

  AttendanceRecord({
    required this.id,
    required this.studentId,
    this.courseId,
    required this.courseName,
    this.facultyName,
    required this.date,
    required this.status,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    // courses is a joined object: { course_name: "...", faculty: { first_name, last_name } }
    final courseRaw = map['courses'];
    String cName = 'Unknown Subject';
    String? fName;
    if (courseRaw is Map) {
      cName = courseRaw['course_name']?.toString() ?? 'Unknown Subject';
      final facRaw = courseRaw['faculty'];
      if (facRaw is Map) {
        final fn = facRaw['first_name'] ?? '';
        final ln = facRaw['last_name'] ?? '';
        fName = '$fn $ln'.trim();
        if (fName.isEmpty) fName = null;
      }
    }
    return AttendanceRecord(
      id: map['id'] as int,
      studentId: map['student_id']?.toString() ?? '',
      courseId: map['course_id'] as int?,
      courseName: cName,
      facultyName: fName,
      date: DateTime.parse(map['date']),
      status: map['status'] ?? 'absent',
    );
  }

  bool get isPresent => status == 'present';
  bool get isAbsent  => status == 'absent';
  bool get isLeave   => status == 'leave';
  bool get isLate    => status == 'late';
}

// ─────────────────────────────────────────────
// SUBJECT ATTENDANCE SUMMARY
// Aggregates all records for one subject
// ─────────────────────────────────────────────

class SubjectAttendance {
  final int courseId;
  final String courseName;
  final String? facultyName;
  final int total;
  final int present;
  final int absent;
  final int leave;
  final int late;

  SubjectAttendance({
    required this.courseId,
    required this.courseName,
    this.facultyName,
    required this.total,
    required this.present,
    required this.absent,
    required this.leave,
    required this.late,
  });

  double get percentage =>
      total == 0 ? 0.0 : ((present + late) / total) * 100;

  bool get isLow => percentage < 75;
}

// ─────────────────────────────────────────────
// SUBJECT MARKS
// One row per subject (from course_enrollments)
// ─────────────────────────────────────────────

class SubjectMarks {
  final int enrollmentId;
  final int courseId;
  final String courseName;
  final String? facultyName;
  final double? internalMarks;   // out of 30 or 40 (faculty-defined)
  final double? externalMarks;   // out of 70 or 60
  final double? totalMarks;      // internal + external
  final String? grade;
  final String status;           // enrolled | completed | failed | dropped

  SubjectMarks({
    required this.enrollmentId,
    required this.courseId,
    required this.courseName,
    this.facultyName,
    this.internalMarks,
    this.externalMarks,
    this.totalMarks,
    this.grade,
    required this.status,
  });

  /// Combined marks for display (internal + external if both present)
  double? get combinedTotal {
    if (internalMarks != null && externalMarks != null) {
      return internalMarks! + externalMarks!;
    }
    if (totalMarks != null) return totalMarks;
    return internalMarks ?? externalMarks;
  }

  factory SubjectMarks.fromMap(Map<String, dynamic> map) {
    final courseRaw = map['courses'];
    String cName = 'Unknown Subject';
    String? fName;
    if (courseRaw is Map) {
      cName = courseRaw['course_name']?.toString() ?? 'Unknown Subject';
      final facRaw = courseRaw['faculty'];
      if (facRaw is Map) {
        final fn = facRaw['first_name'] ?? '';
        final ln = facRaw['last_name'] ?? '';
        fName = '$fn $ln'.trim();
        if (fName.isEmpty) fName = null;
      }
    }

    double? parse(dynamic v) =>
        v == null ? null : (v as num).toDouble();

    return SubjectMarks(
      enrollmentId: map['id'] as int,
      courseId: map['course_id'] as int,
      courseName: cName,
      facultyName: fName,
      internalMarks: parse(map['internal_marks']),
      externalMarks: parse(map['external_marks']),
      totalMarks: parse(map['marks']),
      grade: map['grade'] as String?,
      status: map['status'] ?? 'enrolled',
    );
  }
}

// ─────────────────────────────────────────────
// STUDENT PROFILE
// ─────────────────────────────────────────────

class StudentProfile {
  final String id;       // students.id (UUID)
  final String userId;   // profiles.id / auth.users.id
  final String firstName;
  final String lastName;
  final String email;
  final String rollNumber;
  final String? studentIdCode;
  final String? phone;
  final String? gender;
  final String? fatherName;
  final String year;
  final int? departmentId;
  final String? departmentName;
  final double? cgpa;
  final bool isActive;

  StudentProfile({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.rollNumber,
    this.studentIdCode,
    this.phone,
    this.gender,
    this.fatherName,
    required this.year,
    this.departmentId,
    this.departmentName,
    this.cgpa,
    required this.isActive,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get displayYear => year;

  factory StudentProfile.fromMap(Map<String, dynamic> map) {
    final deptRaw = map['departments'];
    String? deptName;
    if (deptRaw is Map) {
      deptName = deptRaw['name'] as String?;
    }

    return StudentProfile(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      firstName: map['first_name'] ?? 'Student',
      lastName: map['last_name'] ?? '',
      email: map['email'] ?? '',
      rollNumber: map['roll_number'] ?? '',
      studentIdCode: map['student_id'] as String?,
      phone: map['phone'] as String?,
      gender: map['gender'] as String?,
      fatherName: map['father_name'] as String?,
      year: map['year'] ?? 'I',
      departmentId: map['department_id'] as int?,
      departmentName: deptName,
      cgpa: (map['cgpa'] as num?)?.toDouble(),
      isActive: map['is_active'] ?? false,
    );
  }
}

// ─────────────────────────────────────────────
// DASHBOARD STATS
// ─────────────────────────────────────────────

class DashboardStats {
  final double? cgpa;
  final double attendancePercentage;
  final int creditsCompleted;
  final int totalCredits;
  final int pendingLeaves;
  final int approvedLeaves;
  final int pendingDocuments;
  final int approvedDocuments;

  DashboardStats({
    this.cgpa,
    required this.attendancePercentage,
    required this.creditsCompleted,
    required this.totalCredits,
    required this.pendingLeaves,
    required this.approvedLeaves,
    required this.pendingDocuments,
    required this.approvedDocuments,
  });

  factory DashboardStats.empty() => DashboardStats(
    cgpa: null,
    attendancePercentage: 0,
    creditsCompleted: 0,
    totalCredits: 150,
    pendingLeaves: 0,
    approvedLeaves: 0,
    pendingDocuments: 0,
    approvedDocuments: 0,
  );
}

// ─────────────────────────────────────────────
// LEAVE APPLICATION
// ─────────────────────────────────────────────

class LeaveApplication {
  final int id;
  final String studentId;
  final String title;
  final String description;
  final DateTime fromDate;
  final DateTime toDate;
  final String? documentUrl;
  final String status;         // pending | approved | rejected
  final String? hodRemarks;
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
    required this.createdAt,
  });

  int get durationDays => toDate.difference(fromDate).inDays + 1;

  String get formattedDateRange {
    final fmt = DateFormat('MMM dd, yyyy');
    return '${fmt.format(fromDate)} – ${fmt.format(toDate)}';
  }

  factory LeaveApplication.fromMap(Map<String, dynamic> map) {
    return LeaveApplication(
      id: map['id'] as int,
      studentId: map['student_id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      fromDate: DateTime.parse(map['from_date']),
      toDate: DateTime.parse(map['to_date']),
      documentUrl: map['document_url'] as String?,
      status: map['status'] ?? 'pending',
      hodRemarks: map['hod_remarks'] as String?,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

// ─────────────────────────────────────────────
// STUDENT DOCUMENT
// ─────────────────────────────────────────────

class StudentDocument {
  final int id;
  final String studentId;
  final String documentType;
  final String title;
  final String? description;
  final String documentUrl;
  final String status;         // pending | approved | rejected
  final int pointsAwarded;
  final String? hodRemarks;
  final String? fileName;
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
    this.fileName,
    required this.createdAt,
  });

  String get displayType {
    switch (documentType) {
      case 'technical_skill': return 'Technical Skill';
      case 'internship':      return 'Internship';
      case 'seminar':         return 'Seminar';
      case 'certification':   return 'Certification';
      default:                return 'Other';
    }
  }

  factory StudentDocument.fromMap(Map<String, dynamic> map) {
    return StudentDocument(
      id: map['id'] as int,
      studentId: map['student_id']?.toString() ?? '',
      documentType: map['document_type'] ?? 'other',
      title: map['title'] ?? '',
      description: map['description'] as String?,
      documentUrl: map['document_url'] ?? '',
      status: map['status'] ?? 'pending',
      pointsAwarded: map['points_awarded'] ?? 0,
      hodRemarks: map['hod_remarks'] as String?,
      fileName: map['file_name'] as String?,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}