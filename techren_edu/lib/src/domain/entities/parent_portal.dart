class ParentChild {
  const ParentChild({
    required this.id,
    required this.name,
    this.studentCode,
    this.email,
    this.status,
    this.examEligibility,
    this.profileImage,
  });

  final String id;
  final String name;
  final String? studentCode;
  final String? email;
  final String? status;
  final bool? examEligibility;
  final String? profileImage;

  factory ParentChild.fromJson(Map<String, dynamic> json) {
    return ParentChild(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      studentCode: json['studentId'] as String?,
      email: json['email'] as String?,
      status: json['status'] as String?,
      examEligibility: json['examEligibility'] as bool?,
      profileImage: json['profileImage'] as String?,
    );
  }
}

class ParentChildOverview {
  const ParentChildOverview({
    required this.child,
    required this.summary,
  });

  final ParentChild child;
  final ParentChildSummary summary;

  factory ParentChildOverview.fromJson(Map<String, dynamic> json) {
    return ParentChildOverview(
      child: ParentChild.fromJson(json['child'] as Map<String, dynamic>),
      summary: ParentChildSummary.fromJson(json['summary'] as Map<String, dynamic>),
    );
  }
}

class ParentChildSummary {
  const ParentChildSummary({
    required this.feedbackCount,
    required this.attendance,
    required this.examCount,
  });

  final int feedbackCount;
  final ParentAttendanceSummary attendance;
  final int examCount;

  factory ParentChildSummary.fromJson(Map<String, dynamic> json) {
    return ParentChildSummary(
      feedbackCount: json['feedbackCount'] as int? ?? 0,
      attendance: ParentAttendanceSummary.fromJson(json['attendance'] as Map<String, dynamic>? ?? {}),
      examCount: json['examCount'] as int? ?? 0,
    );
  }
}

class ParentAttendanceSummary {
  const ParentAttendanceSummary({
    required this.present,
    required this.absent,
    required this.total,
  });

  final int present;
  final int absent;
  final int total;

  factory ParentAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return ParentAttendanceSummary(
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }
}

class ParentFeedbackEntry {
  const ParentFeedbackEntry({
    required this.id,
    this.className,
    this.teacherName,
    required this.date,
    required this.homework,
    required this.behavior,
    required this.participation,
    this.isExamDay = false,
    this.examPercentage,
    this.parentComments,
    this.notes,
  });

  final String id;
  final String? className;
  final String? teacherName;
  final String date;
  final int homework;
  final int behavior;
  final int participation;
  final bool isExamDay;
  final int? examPercentage;
  final String? parentComments;
  final String? notes;

  factory ParentFeedbackEntry.fromJson(Map<String, dynamic> json) {
    return ParentFeedbackEntry(
      id: json['id'] as String,
      className: json['className'] as String?,
      teacherName: json['teacherName'] as String?,
      date: json['date'] as String? ?? '',
      homework: json['homework'] as int? ?? 0,
      behavior: json['behavior'] as int? ?? 0,
      participation: json['participation'] as int? ?? 0,
      isExamDay: json['isExamDay'] as bool? ?? false,
      examPercentage: json['examPercentage'] as int?,
      parentComments: json['parentComments'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class ParentAttendanceEntry {
  const ParentAttendanceEntry({
    required this.id,
    this.className,
    required this.date,
    required this.status,
  });

  final String id;
  final String? className;
  final String date;
  final String status;

  factory ParentAttendanceEntry.fromJson(Map<String, dynamic> json) {
    return ParentAttendanceEntry(
      id: json['id'] as String,
      className: json['className'] as String?,
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

class ParentExamEntry {
  const ParentExamEntry({
    required this.id,
    required this.examName,
    this.subject,
    this.className,
    this.examDate,
    this.status,
    this.marksObtained,
    this.passed = false,
  });

  final String id;
  final String examName;
  final String? subject;
  final String? className;
  final DateTime? examDate;
  final String? status;
  final int? marksObtained;
  final bool passed;

  factory ParentExamEntry.fromJson(Map<String, dynamic> json) {
    return ParentExamEntry(
      id: json['id'] as String,
      examName: json['examName'] as String? ?? '',
      subject: json['subject'] as String?,
      className: json['className'] as String?,
      examDate: json['examDate'] != null ? DateTime.tryParse(json['examDate'].toString()) : null,
      status: json['status'] as String?,
      marksObtained: json['marksObtained'] as int?,
      passed: json['passed'] as bool? ?? false,
    );
  }
}
