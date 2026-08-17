import '../../core/utils/academy_time.dart';

class ExamEntry {
  const ExamEntry({
    required this.id,
    required this.examName,
    required this.subject,
    required this.className,
    required this.examDate,
    required this.startTime,
    required this.duration,
    required this.totalMarks,
    required this.passingMarks,
    required this.examType,
    required this.status,
    required this.results,
    this.teacherName,
  });

  final String id;
  final String examName;
  final String subject;
  final String className;
  final DateTime examDate;
  final String startTime;
  final int duration;
  final int totalMarks;
  final int passingMarks;
  final String examType;
  final String status;
  final String? teacherName;
  final List<ExamResult> results;

  factory ExamEntry.fromJson(Map<String, dynamic> json) {
    return ExamEntry(
      id: json['id'] as String,
      examName: json['examName'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      className: json['class'] as String? ?? json['className'] as String? ?? '',
      examDate: DateTime.tryParse(json['examDate']?.toString() ?? '') ?? DateTime.now(),
      startTime: json['startTime'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      totalMarks: json['totalMarks'] as int? ?? 0,
      passingMarks: json['passingMarks'] as int? ?? 0,
      examType: json['examType'] as String? ?? 'mid-term',
      status: json['status'] as String? ?? 'scheduled',
      teacherName: json['teacherName'] as String?,
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => ExamResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExamResult {
  const ExamResult({
    required this.studentId,
    this.studentName,
    this.studentCode,
    required this.marksObtained,
    required this.grade,
    required this.remarks,
    required this.enrollmentStatus,
    required this.passed,
  });

  final String studentId;
  final String? studentName;
  final String? studentCode;
  final int marksObtained;
  final String grade;
  final String remarks;
  final String enrollmentStatus;
  final bool passed;

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      studentId: (json['student'] ?? json['studentId'] ?? '').toString(),
      studentName: json['studentName'] as String?,
      studentCode: json['studentCode'] as String?,
      marksObtained: json['marksObtained'] as int? ?? 0,
      grade: json['grade'] as String? ?? '',
      remarks: json['remarks'] as String? ?? '',
      enrollmentStatus: json['enrollmentStatus'] as String? ?? 'enrolled',
      passed: json['passed'] as bool? ?? false,
    );
  }
}

class PaymentEntry {
  const PaymentEntry({
    required this.id,
    required this.studentId,
    this.studentName,
    required this.amount,
    required this.paymentType,
    required this.paymentMethod,
    required this.status,
    required this.subject,
    required this.dueDate,
    this.paidDate,
    this.receiptNumber,
    required this.academicYear,
    required this.term,
    required this.month,
    required this.year,
    this.notes,
  });

  final String id;
  final String studentId;
  final String? studentName;
  final double amount;
  final String paymentType;
  final String paymentMethod;
  final String status;
  final String subject;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String? receiptNumber;
  final String academicYear;
  final String term;
  final int month;
  final int year;
  final String? notes;

  factory PaymentEntry.fromJson(Map<String, dynamic> json) {
    return PaymentEntry(
      id: json['id']?.toString() ?? '',
      studentId: (json['student'] ?? json['studentId'] ?? '').toString(),
      studentName: json['studentName'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentType: json['paymentType'] as String? ?? 'tuition-fee',
      paymentMethod: json['paymentMethod'] as String? ?? 'cash',
      status: json['status'] as String? ?? 'pending',
      subject: json['subject'] as String? ?? '',
      dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? '') ?? DateTime.now(),
      paidDate: json['paidDate'] != null ? DateTime.tryParse(json['paidDate'].toString()) : null,
      receiptNumber: json['receiptNumber'] as String?,
      academicYear: json['academicYear'] as String? ?? '',
      term: json['term'] as String? ?? '',
      month: json['month'] as int? ?? 1,
      year: json['year'] as int? ?? AcademyTime.year,
      notes: json['notes'] as String?,
    );
  }
}

class PaymentCourseStatus {
  const PaymentCourseStatus({
    this.subjectId,
    required this.subjectName,
    required this.amountDue,
    required this.amountPaid,
    required this.status,
  });

  final String? subjectId;
  final String subjectName;
  final double amountDue;
  final double amountPaid;
  final String status; // paid | unpaid | partial

  bool get isPaid => status == 'paid';
  double get remaining => (amountDue - amountPaid).clamp(0, double.infinity);

  factory PaymentCourseStatus.fromJson(Map<String, dynamic> json) => PaymentCourseStatus(
        subjectId: json['subjectId']?.toString(),
        subjectName: json['subjectName'] as String? ?? '',
        amountDue: (json['amountDue'] as num?)?.toDouble() ?? 0,
        amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'unpaid',
      );
}

/// Current-month dues for the logged-in student (`GET /payments/my-dues`).
class StudentDues {
  const StudentDues({
    required this.month,
    required this.year,
    required this.courses,
    required this.overallStatus,
    required this.amountRemaining,
    required this.isPaid,
  });

  final int month;
  final int year;
  final List<PaymentCourseStatus> courses;
  final String overallStatus;
  final double amountRemaining;
  final bool isPaid;

  factory StudentDues.fromJson(Map<String, dynamic> json) => StudentDues(
        month: (json['month'] as num?)?.toInt() ?? AcademyTime.month,
        year: (json['year'] as num?)?.toInt() ?? AcademyTime.year,
        courses: (json['courses'] as List<dynamic>? ?? [])
            .map((e) => PaymentCourseStatus.fromJson(e as Map<String, dynamic>))
            .toList(),
        overallStatus: json['overallStatus'] as String? ?? 'paid',
        amountRemaining: (json['amountRemaining'] as num?)?.toDouble() ?? 0,
        isPaid: json['isPaid'] == true ||
            json['overallStatus'] == 'paid' ||
            ((json['amountRemaining'] as num?)?.toDouble() ?? 0) <= 0,
      );
}

class PaymentRosterRow {
  const PaymentRosterRow({
    required this.id,
    required this.studentCode,
    required this.name,
    required this.courses,
    required this.overallStatus,
  });

  final String id;
  final String studentCode;
  final String name;
  final List<PaymentCourseStatus> courses;
  final String overallStatus;

  bool get isPaid => overallStatus == 'paid';

  double get totalDue => courses.fold<double>(0, (sum, c) => sum + c.amountDue);

  double get totalPaid => courses.fold<double>(0, (sum, c) => sum + c.amountPaid);

  bool get hasBillableCourses => courses.any((c) => c.amountDue > 0 || c.amountPaid > 0);

  String get summaryStatus {
    if (!hasBillableCourses) return 'unpaid';
    if (courses.every((c) => c.isPaid)) return 'paid';
    if (courses.any((c) => c.amountPaid > 0)) return 'partial';
    return 'unpaid';
  }

  factory PaymentRosterRow.fromJson(Map<String, dynamic> json) => PaymentRosterRow(
        id: json['id']?.toString() ?? '',
        studentCode: json['studentCode'] as String? ?? '',
        name: json['name'] as String? ?? '',
        courses: (json['courses'] as List<dynamic>? ?? [])
            .map((e) => PaymentCourseStatus.fromJson(e as Map<String, dynamic>))
            .toList(),
        overallStatus: json['overallStatus'] as String? ?? 'unpaid',
      );
}

class PaymentRosterResult {
  const PaymentRosterResult({
    required this.items,
    required this.month,
    required this.year,
    required this.term,
    required this.academicYear,
  });

  final List<PaymentRosterRow> items;
  final int month;
  final int year;
  final String term;
  final String academicYear;

  factory PaymentRosterResult.fromResponse(List<dynamic> items, Map<String, dynamic> meta) =>
      PaymentRosterResult(
        items: items.map((e) => PaymentRosterRow.fromJson(e as Map<String, dynamic>)).toList(),
        month: meta['month'] as int? ?? AcademyTime.month,
        year: meta['year'] as int? ?? AcademyTime.year,
        term: meta['term'] as String? ?? '1st-term',
        academicYear: meta['academicYear'] as String? ?? '',
      );
}

class RevenueDateRange {
  const RevenueDateRange({this.startDate, this.endDate, this.label = 'All time'});

  final DateTime? startDate;
  final DateTime? endDate;
  final String label;

  bool get hasFilter => startDate != null && endDate != null;

  String? get startDateParam => startDate != null ? _formatDate(startDate!) : null;
  String? get endDateParam => endDate != null ? _formatDate(endDate!) : null;

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static RevenueDateRange allTime() => const RevenueDateRange();

  static RevenueDateRange thisMonth() {
    final now = AcademyTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return RevenueDateRange(startDate: start, endDate: end, label: 'This month');
  }

  static RevenueDateRange last30Days() {
    final now = AcademyTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return RevenueDateRange(
      startDate: today.subtract(const Duration(days: 29)),
      endDate: today,
      label: 'Last 30 days',
    );
  }

  static RevenueDateRange thisYear() {
    final now = AcademyTime.now();
    return RevenueDateRange(
      startDate: DateTime(now.year, 1, 1),
      endDate: DateTime(now.year, now.month, now.day),
      label: 'This year',
    );
  }

  static RevenueDateRange custom(DateTime start, DateTime end) {
    return RevenueDateRange(
      startDate: DateTime(start.year, start.month, start.day),
      endDate: DateTime(end.year, end.month, end.day),
      label: '${_formatDate(start)} – ${_formatDate(end)}',
    );
  }
}

class RevenueSummary {
  const RevenueSummary({
    required this.totalRevenue,
    required this.totalTransactions,
    required this.totalPending,
    required this.pendingCount,
    required this.revenueByType,
    required this.revenueBySubject,
  });

  final double totalRevenue;
  final int totalTransactions;
  final double totalPending;
  final int pendingCount;
  final Map<String, double> revenueByType;
  final Map<String, double> revenueBySubject;

  factory RevenueSummary.fromJson(Map<String, dynamic> json) {
    Map<String, double> mapValues(Map<String, dynamic>? source) {
      return (source ?? {}).map((k, v) => MapEntry(k, (v as num).toDouble()));
    }

    return RevenueSummary(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      totalTransactions: (json['totalTransactions'] as num?)?.toInt() ?? 0,
      totalPending: (json['totalPending'] as num?)?.toDouble() ?? 0,
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      revenueByType: mapValues(json['revenueByType'] as Map<String, dynamic>?),
      revenueBySubject: mapValues(json['revenueBySubject'] as Map<String, dynamic>?),
    );
  }
}

class RevenueChartPoint {
  const RevenueChartPoint({required this.label, required this.amount});

  final String label;
  final double amount;

  factory RevenueChartPoint.fromJson(Map<String, dynamic> json) => RevenueChartPoint(
        label: json['label'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );
}

class RevenueChartData {
  const RevenueChartData({
    required this.byMonth,
    required this.byDate,
    required this.byType,
  });

  final List<RevenueChartPoint> byMonth;
  final List<RevenueChartPoint> byDate;
  final List<RevenueChartPoint> byType;

  factory RevenueChartData.fromJson(Map<String, dynamic> json) {
    List<RevenueChartPoint> parseList(List<dynamic>? items) {
      return (items ?? [])
          .map((e) => RevenueChartPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return RevenueChartData(
      byMonth: parseList(json['byMonth'] as List<dynamic>?),
      byDate: parseList(json['byDate'] as List<dynamic>?),
      byType: parseList(json['byType'] as List<dynamic>?),
    );
  }
}

class RevenueExportData {
  const RevenueExportData({
    required this.generatedAt,
    required this.totalRevenue,
    required this.totalTransactions,
    required this.totalPending,
    required this.pendingCount,
    required this.revenueByType,
    required this.revenueBySubject,
    required this.payments,
  });

  final DateTime generatedAt;
  final double totalRevenue;
  final int totalTransactions;
  final double totalPending;
  final int pendingCount;
  final Map<String, double> revenueByType;
  final Map<String, double> revenueBySubject;
  final List<Map<String, dynamic>> payments;

  factory RevenueExportData.fromJson(Map<String, dynamic> json) {
    Map<String, double> mapValues(Map<String, dynamic>? source) {
      return (source ?? {}).map((k, v) => MapEntry(k, (v as num).toDouble()));
    }

    return RevenueExportData(
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? '') ?? DateTime.now(),
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      totalTransactions: (json['totalTransactions'] as num?)?.toInt() ?? 0,
      totalPending: (json['totalPending'] as num?)?.toDouble() ?? 0,
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      revenueByType: mapValues(json['revenueByType'] as Map<String, dynamic>?),
      revenueBySubject: mapValues(json['revenueBySubject'] as Map<String, dynamic>?),
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }

  String toReportText() {
    final buffer = StringBuffer()
      ..writeln('TechRen EDU Revenue Report')
      ..writeln('Generated: ${generatedAt.toLocal()}')
      ..writeln('')
      ..writeln('Total revenue: ${totalRevenue.toStringAsFixed(0)} UZS')
      ..writeln('Transactions: $totalTransactions')
      ..writeln('Pending: ${totalPending.toStringAsFixed(0)} UZS ($pendingCount)')
      ..writeln('')
      ..writeln('By type:');
    revenueByType.forEach((k, v) => buffer.writeln('  $k: ${v.toStringAsFixed(0)} UZS'));
    buffer
      ..writeln('')
      ..writeln('By subject:');
    revenueBySubject.forEach((k, v) => buffer.writeln('  $k: ${v.toStringAsFixed(0)} UZS'));
    buffer
      ..writeln('')
      ..writeln('Recent payments: ${payments.length}');
    for (final p in payments.take(20)) {
      buffer.writeln(
        '  ${p['studentName'] ?? '—'} · ${p['amount']} UZS · ${p['subject'] ?? ''} · ${p['paidDate'] ?? ''}',
      );
    }
    return buffer.toString();
  }
}

class PendingPaymentsSummary {
  const PendingPaymentsSummary({
    required this.totalPending,
    required this.count,
    required this.payments,
  });

  final double totalPending;
  final int count;
  final List<PaymentEntry> payments;

  factory PendingPaymentsSummary.fromJson(Map<String, dynamic> json) {
    return PendingPaymentsSummary(
      totalPending: (json['totalPending'] as num?)?.toDouble() ?? 0,
      count: json['count'] as int? ?? 0,
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map((e) => PaymentEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BranchCollectionRow {
  const BranchCollectionRow({
    required this.branchId,
    required this.branchName,
    required this.expected,
    required this.collected,
    required this.remaining,
    required this.studentCount,
    required this.unpaidCount,
    this.expenses = 0,
    this.leftover = 0,
  });

  final String branchId;
  final String branchName;
  final double expected;
  final double collected;
  final double remaining;
  final int studentCount;
  final int unpaidCount;
  final double expenses;
  final double leftover;

  double get progress => expected <= 0 ? 0 : (collected / expected).clamp(0, 1);

  factory BranchCollectionRow.fromJson(Map<String, dynamic> json) => BranchCollectionRow(
        branchId: json['branchId']?.toString() ?? '',
        branchName: json['branchName'] as String? ?? 'Unassigned',
        expected: (json['expected'] as num?)?.toDouble() ?? 0,
        collected: (json['collected'] as num?)?.toDouble() ?? 0,
        remaining: (json['remaining'] as num?)?.toDouble() ?? 0,
        studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
        unpaidCount: (json['unpaidCount'] as num?)?.toInt() ?? 0,
        expenses: (json['expenses'] as num?)?.toDouble() ?? 0,
        leftover: (json['leftover'] as num?)?.toDouble() ??
            ((json['collected'] as num?)?.toDouble() ?? 0) - ((json['expenses'] as num?)?.toDouble() ?? 0),
      );
}

class BranchCollectionsResult {
  const BranchCollectionsResult({
    required this.month,
    required this.year,
    required this.items,
    required this.totals,
  });

  final int month;
  final int year;
  final List<BranchCollectionRow> items;
  final BranchCollectionRow totals;

  factory BranchCollectionsResult.fromJson(Map<String, dynamic> json) {
    final totalsJson = json['totals'] as Map<String, dynamic>? ?? {};
    return BranchCollectionsResult(
      month: (json['month'] as num?)?.toInt() ?? 1,
      year: (json['year'] as num?)?.toInt() ?? AcademyTime.year,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => BranchCollectionRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      totals: BranchCollectionRow.fromJson({
        'branchId': 'totals',
        'branchName': 'All branches',
        ...totalsJson,
      }),
    );
  }
}

class BranchExpense {
  const BranchExpense({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
    this.notes = '',
    this.teacherId,
    this.teacherName = '',
    this.recordedByName = '',
  });

  final String id;
  final String branchId;
  final String branchName;
  final String category;
  final double amount;
  final int month;
  final int year;
  final String notes;
  final String? teacherId;
  final String teacherName;
  final String recordedByName;

  factory BranchExpense.fromJson(Map<String, dynamic> json) => BranchExpense(
        id: json['id']?.toString() ?? '',
        branchId: json['branchId']?.toString() ?? '',
        branchName: json['branchName'] as String? ?? '',
        category: json['category'] as String? ?? 'other',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        month: (json['month'] as num?)?.toInt() ?? 1,
        year: (json['year'] as num?)?.toInt() ?? AcademyTime.year,
        notes: json['notes'] as String? ?? '',
        teacherId: json['teacherId']?.toString(),
        teacherName: json['teacherName'] as String? ?? '',
        recordedByName: json['recordedByName'] as String? ?? '',
      );
}

class BranchExpenseListResult {
  const BranchExpenseListResult({
    required this.items,
    required this.totalAmount,
    this.byCategory = const {},
  });

  final List<BranchExpense> items;
  final double totalAmount;
  final Map<String, double> byCategory;

  factory BranchExpenseListResult.fromResponse(List<dynamic> items, Map<String, dynamic> meta) {
    final byCategoryRaw = meta['byCategory'] as Map<String, dynamic>? ?? {};
    return BranchExpenseListResult(
      items: items.map((e) => BranchExpense.fromJson(e as Map<String, dynamic>)).toList(),
      totalAmount: (meta['totalAmount'] as num?)?.toDouble() ?? 0,
      byCategory: {
        for (final entry in byCategoryRaw.entries) entry.key: (entry.value as num?)?.toDouble() ?? 0,
      },
    );
  }
}
