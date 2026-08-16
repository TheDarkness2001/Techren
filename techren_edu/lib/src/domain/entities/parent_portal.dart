import '../../core/utils/academy_time.dart';

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
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      studentCode: json['studentId']?.toString(),
      email: json['email'] as String?,
      status: json['status'] as String?,
      examEligibility: json['examEligibility'] as bool?,
      profileImage: json['profileImage'] as String?,
    );
  }
}

class ParentAlert {
  const ParentAlert({
    required this.type,
    required this.severity,
    required this.title,
    required this.body,
    this.createdAt,
    this.refId,
  });

  final String type;
  final String severity;
  final String title;
  final String body;
  final String? createdAt;
  final String? refId;

  factory ParentAlert.fromJson(Map<String, dynamic> json) {
    return ParentAlert(
      type: json['type'] as String? ?? '',
      severity: json['severity'] as String? ?? 'low',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: json['createdAt']?.toString(),
      refId: json['refId']?.toString(),
    );
  }
}

class ParentPaymentSummary {
  const ParentPaymentSummary({
    required this.overallStatus,
    required this.amountRemaining,
    required this.amountPaid,
    required this.isPaid,
  });

  final String overallStatus;
  final double amountRemaining;
  final double amountPaid;
  final bool isPaid;

  factory ParentPaymentSummary.fromJson(Map<String, dynamic> json) {
    return ParentPaymentSummary(
      overallStatus: json['overallStatus'] as String? ?? 'paid',
      amountRemaining: (json['amountRemaining'] as num?)?.toDouble() ?? 0,
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0,
      isPaid: json['isPaid'] as bool? ?? true,
    );
  }
}

class ParentChildOverview {
  const ParentChildOverview({
    required this.child,
    required this.summary,
    this.alerts = const [],
  });

  final ParentChild child;
  final ParentChildSummary summary;
  final List<ParentAlert> alerts;

  factory ParentChildOverview.fromJson(Map<String, dynamic> json) {
    return ParentChildOverview(
      child: ParentChild.fromJson(json['child'] as Map<String, dynamic>),
      summary: ParentChildSummary.fromJson(json['summary'] as Map<String, dynamic>),
      alerts: (json['alerts'] as List<dynamic>? ?? [])
          .map((e) => ParentAlert.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ParentChildSummary {
  const ParentChildSummary({
    required this.feedbackCount,
    required this.attendance,
    required this.examCount,
    this.payments,
  });

  final int feedbackCount;
  final ParentAttendanceSummary attendance;
  final int examCount;
  final ParentPaymentSummary? payments;

  factory ParentChildSummary.fromJson(Map<String, dynamic> json) {
    return ParentChildSummary(
      feedbackCount: json['feedbackCount'] as int? ?? 0,
      attendance: ParentAttendanceSummary.fromJson(json['attendance'] as Map<String, dynamic>? ?? {}),
      examCount: json['examCount'] as int? ?? 0,
      payments: json['payments'] is Map<String, dynamic>
          ? ParentPaymentSummary.fromJson(json['payments'] as Map<String, dynamic>)
          : null,
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

class ParentHomeworkProgress {
  const ParentHomeworkProgress({
    this.totalAttempts = 0,
    this.correctAnswers = 0,
    this.accuracy = 0,
    this.enToUzAccuracy = 0,
    this.uzToEnAccuracy = 0,
    this.lastUpdated,
  });

  final int totalAttempts;
  final int correctAnswers;
  final int accuracy;
  final int enToUzAccuracy;
  final int uzToEnAccuracy;
  final DateTime? lastUpdated;

  factory ParentHomeworkProgress.fromJson(Map<String, dynamic> json) {
    final nested = json['progress'] is Map<String, dynamic>
        ? json['progress'] as Map<String, dynamic>
        : json;
    return ParentHomeworkProgress(
      totalAttempts: (nested['totalAttempts'] as num?)?.toInt() ?? 0,
      correctAnswers: (nested['correctAnswers'] as num?)?.toInt() ?? 0,
      accuracy: (nested['accuracy'] as num?)?.toInt() ?? 0,
      enToUzAccuracy: (nested['enToUzAccuracy'] as num?)?.toInt() ?? 0,
      uzToEnAccuracy: (nested['uzToEnAccuracy'] as num?)?.toInt() ?? 0,
      lastUpdated: DateTime.tryParse(nested['lastUpdated']?.toString() ?? ''),
    );
  }
}

class ParentFeedbackEntry {
  const ParentFeedbackEntry({
    required this.id,
    this.className,
    this.teacherName,
    required this.date,
    this.homework = 0,
    this.words = 0,
    this.sentence = 0,
    this.metricsMode = 'standard',
    required this.behavior,
    required this.participation,
    this.isExamDay = false,
    this.examPercentage,
    this.parentComments,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String? className;
  final String? teacherName;
  final String date;
  final int homework;
  final int words;
  final int sentence;
  final String metricsMode;
  final int behavior;
  final int participation;
  final bool isExamDay;
  final int? examPercentage;
  final String? parentComments;
  final String? notes;
  final DateTime? createdAt;

  bool get isEnglishMetrics => metricsMode == 'english';

  factory ParentFeedbackEntry.fromJson(Map<String, dynamic> json) {
    return ParentFeedbackEntry(
      id: json['id']?.toString() ?? '',
      className: json['className'] as String?,
      teacherName: json['teacherName'] as String?,
      date: json['date'] as String? ?? '',
      homework: (json['homework'] as num?)?.toInt() ?? 0,
      words: (json['words'] as num?)?.toInt() ?? 0,
      sentence: (json['sentence'] as num?)?.toInt() ?? 0,
      metricsMode: json['metricsMode'] as String? ??
          (((json['words'] as num?)?.toInt() ?? 0) > 0 ||
                  ((json['sentence'] as num?)?.toInt() ?? 0) > 0
              ? 'english'
              : 'standard'),
      behavior: (json['behavior'] as num?)?.toInt() ?? 0,
      participation: (json['participation'] as num?)?.toInt() ?? 0,
      isExamDay: json['isExamDay'] as bool? ?? false,
      examPercentage: (json['examPercentage'] as num?)?.toInt(),
      parentComments: json['parentComments'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}

class ParentAttendanceEntry {
  const ParentAttendanceEntry({
    required this.id,
    this.className,
    this.teacherName,
    required this.date,
    required this.status,
    this.excuseReason = '',
    this.excuseSubmittedAt,
    this.canSubmitExcuse = false,
  });

  final String id;
  final String? className;
  final String? teacherName;
  final String date;
  final String status;
  final String excuseReason;
  final DateTime? excuseSubmittedAt;
  final bool canSubmitExcuse;

  factory ParentAttendanceEntry.fromJson(Map<String, dynamic> json) {
    return ParentAttendanceEntry(
      id: json['id']?.toString() ?? '',
      className: json['className'] as String?,
      teacherName: json['teacherName'] as String?,
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? '',
      excuseReason: json['excuseReason'] as String? ?? '',
      excuseSubmittedAt: json['excuseSubmittedAt'] != null
          ? DateTime.tryParse(json['excuseSubmittedAt'].toString())
          : null,
      canSubmitExcuse: json['canSubmitExcuse'] as bool? ?? false,
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
      id: json['id']?.toString() ?? '',
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

class ParentPaymentsPage {
  const ParentPaymentsPage({
    required this.month,
    required this.year,
    required this.overallStatus,
    required this.amountRemaining,
    required this.amountPaid,
    required this.amountDue,
    required this.isPaid,
    this.courses = const [],
    this.recentPayments = const [],
  });

  final int month;
  final int year;
  final String overallStatus;
  final double amountRemaining;
  final double amountPaid;
  final double amountDue;
  final bool isPaid;
  final List<ParentCourseDue> courses;
  final List<ParentPaymentRow> recentPayments;

  factory ParentPaymentsPage.fromJson(Map<String, dynamic> json) {
    return ParentPaymentsPage(
      month: json['month'] as int? ?? AcademyTime.month,
      year: json['year'] as int? ?? AcademyTime.year,
      overallStatus: json['overallStatus'] as String? ?? 'paid',
      amountRemaining: (json['amountRemaining'] as num?)?.toDouble() ?? 0,
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0,
      amountDue: (json['amountDue'] as num?)?.toDouble() ?? 0,
      isPaid: json['isPaid'] as bool? ?? true,
      courses: (json['courses'] as List<dynamic>? ?? [])
          .map((e) => ParentCourseDue.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentPayments: (json['recentPayments'] as List<dynamic>? ?? [])
          .map((e) => ParentPaymentRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ParentCourseDue {
  const ParentCourseDue({
    required this.subject,
    required this.amountDue,
    required this.amountPaid,
    required this.status,
  });

  final String subject;
  final double amountDue;
  final double amountPaid;
  final String status;

  factory ParentCourseDue.fromJson(Map<String, dynamic> json) {
    return ParentCourseDue(
      subject: json['subject'] as String? ?? json['name'] as String? ?? '',
      amountDue: (json['amountDue'] as num?)?.toDouble() ?? 0,
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
    );
  }
}

class ParentPaymentRow {
  const ParentPaymentRow({
    required this.id,
    required this.amount,
    required this.status,
    this.paymentType,
    this.subject,
    this.paidDate,
  });

  final String id;
  final double amount;
  final String status;
  final String? paymentType;
  final String? subject;
  final DateTime? paidDate;

  factory ParentPaymentRow.fromJson(Map<String, dynamic> json) {
    return ParentPaymentRow(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      paymentType: json['paymentType'] as String?,
      subject: json['subject'] as String?,
      paidDate: json['paidDate'] != null ? DateTime.tryParse(json['paidDate'].toString()) : null,
    );
  }
}
