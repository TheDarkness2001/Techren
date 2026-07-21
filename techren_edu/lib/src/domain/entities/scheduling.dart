import 'package:equatable/equatable.dart';

class Subject extends Equatable {
  const Subject({
    required this.id,
    required this.name,
    this.code,
    this.pricePerClass = 0,
    this.branchId,
  });

  final String id;
  final String name;
  final String? code;
  final num pricePerClass;
  final String? branchId;

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        code: json['code'] as String?,
        pricePerClass: json['pricePerClass'] as num? ?? 0,
        branchId: json['branchId']?.toString(),
      );

  @override
  List<Object?> get props => [id, name];
}

class ExamGroupMember extends Equatable {
  const ExamGroupMember({
    required this.id,
    required this.name,
    this.studentCode,
    this.profileImage,
  });

  final String id;
  final String name;
  final String? studentCode;
  final String? profileImage;

  factory ExamGroupMember.fromJson(Map<String, dynamic> json) => ExamGroupMember(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        studentCode: json['studentCode'] as String? ?? json['studentId'] as String?,
        profileImage: json['profileImage'] as String?,
      );

  @override
  List<Object?> get props => [id];
}

class ExamGroup extends Equatable {
  const ExamGroup({
    required this.id,
    required this.groupName,
    this.subjectId,
    this.subjectName,
    this.studentCount = 0,
    this.students = const [],
    this.linkedScheduleId,
  });

  final String id;
  final String groupName;
  final String? subjectId;
  final String? subjectName;
  final int studentCount;
  final List<ExamGroupMember> students;
  final String? linkedScheduleId;

  factory ExamGroup.fromJson(Map<String, dynamic> json) {
    final subject = json['subject'];
    final studentsRaw = json['students'] as List<dynamic>? ?? [];
    final students = studentsRaw
        .whereType<Map>()
        .map((e) => ExamGroupMember.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return ExamGroup(
      id: json['id']?.toString() ?? '',
      groupName: json['groupName'] as String? ?? '',
      subjectId: subject is Map ? subject['id']?.toString() ?? subject['_id']?.toString() : subject?.toString(),
      subjectName: subject is Map ? subject['name'] as String? : json['subjectName'] as String?,
      studentCount: (json['studentCount'] as num?)?.toInt() ?? students.length,
      students: students,
      linkedScheduleId: json['linkedScheduleId']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, groupName];
}

class ClassSchedule extends Equatable {
  const ClassSchedule({
    required this.id,
    required this.className,
    this.teacherId,
    this.teacherName,
    this.groupName,
    this.scheduledDays = const [],
    this.startTime = '',
    this.endTime = '',
    this.studentCount = 0,
  });

  final String id;
  final String className;
  final String? teacherId;
  final String? teacherName;
  final String? groupName;
  final List<String> scheduledDays;
  final String startTime;
  final String endTime;
  final int studentCount;

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    final teacher = json['teacher'];
    final group = json['subjectGroup'];
    return ClassSchedule(
      id: json['id']?.toString() ?? '',
      className: json['className'] as String? ?? '',
      teacherId: teacher is Map
          ? teacher['id']?.toString() ?? teacher['_id']?.toString()
          : json['teacherId']?.toString(),
      teacherName: teacher is Map ? teacher['name'] as String? : json['teacherName'] as String?,
      groupName: group is Map ? group['groupName'] as String? : json['groupName'] as String?,
      scheduledDays: (json['scheduledDays'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
    );
  }

  String get daysLabel => scheduledDays.join(', ');

  @override
  List<Object?> get props => [id, className];
}

class UnifiedGroupView extends Equatable {
  const UnifiedGroupView({required this.group, this.schedule});

  final ExamGroup group;
  final ClassSchedule? schedule;

  factory UnifiedGroupView.fromJson(Map<String, dynamic> json) => UnifiedGroupView(
        group: ExamGroup.fromJson(json['group'] as Map<String, dynamic>),
        schedule: json['schedule'] != null
            ? ClassSchedule.fromJson(json['schedule'] as Map<String, dynamic>)
            : null,
      );

  @override
  List<Object?> get props => [group.id, schedule?.id];
}

class TimetableEntry extends Equatable {
  const TimetableEntry({
    required this.id,
    required this.className,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.subject,
    this.teacherName,
    this.teacherId,
    this.groupName,
  });

  final String id;
  final String className;
  final String day;
  final String startTime;
  final String endTime;
  final String? subject;
  final String? teacherName;
  final String? teacherId;
  final String? groupName;

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    final teacher = json['teacher'];
    return TimetableEntry(
      id: json['id']?.toString() ?? '',
      className: json['className'] as String? ?? '',
      day: json['day'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      subject: json['subject'] as String?,
      teacherName: json['teacherName'] as String? ?? (teacher is Map ? teacher['name'] as String? : null),
      teacherId: teacher is Map
          ? teacher['id']?.toString() ?? teacher['_id']?.toString()
          : json['teacherId']?.toString(),
      groupName: json['groupName'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, day, startTime];
}

class TimetableData extends Equatable {
  const TimetableData({required this.role, required this.grid, this.total = 0});

  final String role;
  final Map<String, List<TimetableEntry>> grid;
  final int total;

  factory TimetableData.fromJson(Map<String, dynamic> json) {
    final gridRaw = json['grid'] as Map<String, dynamic>? ?? {};
    final grid = <String, List<TimetableEntry>>{};
    for (final entry in gridRaw.entries) {
      grid[entry.key] = (entry.value as List<dynamic>)
          .map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return TimetableData(
      role: json['role'] as String? ?? '',
      grid: grid,
      total: json['total'] as int? ?? 0,
    );
  }

  static const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  List<Object?> get props => [role, total];
}
