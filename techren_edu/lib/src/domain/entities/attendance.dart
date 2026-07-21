import 'package:equatable/equatable.dart';

class TodayClassSession extends Equatable {
  const TodayClassSession({
    required this.schedule,
    required this.isWithinWindow,
    required this.students,
  });

  final ClassScheduleSummary schedule;
  final bool isWithinWindow;
  final List<StudentAttendanceRow> students;

  factory TodayClassSession.fromJson(Map<String, dynamic> json) => TodayClassSession(
        schedule: ClassScheduleSummary.fromJson(json['schedule'] as Map<String, dynamic>),
        isWithinWindow: json['isWithinWindow'] as bool? ?? false,
        students: (json['students'] as List<dynamic>? ?? [])
            .map((e) => StudentAttendanceRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [schedule.id];
}

class ClassScheduleSummary extends Equatable {
  const ClassScheduleSummary({
    required this.id,
    required this.className,
    required this.startTime,
    required this.endTime,
    this.scheduledDays = const [],
    this.studentCount = 0,
    this.teacherName,
    this.teacherId,
    this.subjectName,
    this.room,
  });

  final String id;
  final String className;
  final String startTime;
  final String endTime;
  final List<String> scheduledDays;
  final int studentCount;
  final String? teacherName;
  final String? teacherId;
  final String? subjectName;
  final String? room;

  factory ClassScheduleSummary.fromJson(Map<String, dynamic> json) => ClassScheduleSummary(
        id: json['id']?.toString() ?? '',
        className: json['className'] as String? ?? '',
        startTime: json['startTime'] as String? ?? '',
        endTime: json['endTime'] as String? ?? '',
        scheduledDays: (json['scheduledDays'] as List<dynamic>? ?? []).cast<String>(),
        studentCount: json['studentCount'] as int? ?? 0,
        teacherName: json['teacherName'] as String?,
        teacherId: json['teacherId']?.toString(),
        subjectName: json['subjectName'] as String?,
        room: json['room'] as String?,
      );

  @override
  List<Object?> get props => [id];
}

class StudentAttendanceRow extends Equatable {
  const StudentAttendanceRow({
    required this.id,
    required this.name,
    this.studentId,
    this.status = 'active',
    this.attendanceStatus,
    this.profileImage,
    this.hasFeedback = false,
  });

  final String id;
  final String name;
  final String? studentId;
  final String status;
  final String? attendanceStatus;
  final String? profileImage;
  final bool hasFeedback;

  factory StudentAttendanceRow.fromJson(Map<String, dynamic> json) {
    final attendance = json['attendance'] as Map<String, dynamic>?;
    return StudentAttendanceRow(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      studentId: json['studentId'] as String?,
      status: json['status'] as String? ?? 'active',
      attendanceStatus: attendance?['status'] as String?,
      profileImage: json['profileImage'] as String?,
      hasFeedback: json['hasFeedback'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, attendanceStatus];
}

class TeacherCheckInStatus extends Equatable {
  const TeacherCheckInStatus({
    this.checkInAt,
    this.checkOutAt,
    this.status,
  });

  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final String? status;

  bool get isCheckedIn => checkInAt != null;
  bool get isCheckedOut => checkOutAt != null;

  factory TeacherCheckInStatus.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TeacherCheckInStatus();
    return TeacherCheckInStatus(
      checkInAt: json['checkInAt'] != null ? DateTime.tryParse(json['checkInAt'].toString()) : null,
      checkOutAt: json['checkOutAt'] != null ? DateTime.tryParse(json['checkOutAt'].toString()) : null,
      status: json['status'] as String?,
    );
  }

  @override
  List<Object?> get props => [checkInAt, checkOutAt];
}

class TeacherRosterRow extends Equatable {
  const TeacherRosterRow({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.role,
    this.teacherId,
    this.profileImage,
    this.subjects = const [],
    this.dailyStatus,
    this.notes,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? role;
  final String? teacherId;
  final String? profileImage;
  final List<String> subjects;
  final String? dailyStatus;
  final String? notes;

  factory TeacherRosterRow.fromJson(Map<String, dynamic> json) {
    final teacher = json['teacher'] as Map<String, dynamic>? ?? json;
    final attendance = json['attendance'] as Map<String, dynamic>?;
    return TeacherRosterRow(
      id: teacher['id']?.toString() ?? '',
      name: teacher['name'] as String? ?? '',
      email: teacher['email'] as String?,
      phone: teacher['phone'] as String?,
      role: teacher['role'] as String?,
      teacherId: teacher['teacherId']?.toString(),
      profileImage: teacher['profileImage'] as String?,
      subjects: (teacher['subjects'] as List<dynamic>? ?? teacher['subject'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      dailyStatus: attendance?['dailyStatus'] as String?,
      notes: attendance?['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, dailyStatus, notes];
}

class FeedbackEntry extends Equatable {
  const FeedbackEntry({
    required this.id,
    required this.studentName,
    required this.className,
    required this.date,
    this.homework = 0,
    this.behavior = 0,
    this.participation = 0,
    this.isExamDay = false,
    this.examPercentage,
    this.parentComments,
  });

  final String id;
  final String studentName;
  final String className;
  final String date;
  final int homework;
  final int behavior;
  final int participation;
  final bool isExamDay;
  final int? examPercentage;
  final String? parentComments;

  factory FeedbackEntry.fromJson(Map<String, dynamic> json) => FeedbackEntry(
        id: json['id']?.toString() ?? '',
        studentName: json['studentName'] as String? ?? '',
        className: json['className'] as String? ?? '',
        date: json['date'] as String? ?? '',
        homework: json['homework'] as int? ?? 0,
        behavior: json['behavior'] as int? ?? 0,
        participation: json['participation'] as int? ?? 0,
        isExamDay: json['isExamDay'] as bool? ?? false,
        examPercentage: json['examPercentage'] as int?,
        parentComments: json['parentComments'] as String?,
      );

  @override
  List<Object?> get props => [id];
}
