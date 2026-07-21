import 'package:equatable/equatable.dart';

class Person extends Equatable {
  const Person({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.status = 'active',
    this.role,
    this.displayId,
    this.branchId,
    this.parentName,
    this.parentPhone,
    this.examEligibility,
    this.userType = 'student',
    this.profileImage,
    this.subjects = const [],
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String status;
  final String? role;
  final String? displayId;
  final String? branchId;
  final String? parentName;
  final String? parentPhone;
  final bool? examEligibility;
  final String userType;
  final String? profileImage;
  final List<String> subjects;

  bool get isActive => status == 'active';
  bool get isStudent => userType == 'student';
  bool get isTeacher => userType == 'teacher';

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        status: json['status'] as String? ?? 'active',
        role: json['role'] as String?,
        displayId: (json['studentId'] ?? json['teacherId'])?.toString(),
        branchId: json['branchId']?.toString(),
        parentName: json['parentName'] as String?,
        parentPhone: json['parentPhone'] as String?,
        examEligibility: json['examEligibility'] as bool?,
        userType: json['userType'] as String? ?? 'student',
        profileImage: json['profileImage'] as String?,
        subjects: (json['subject'] as List<dynamic>? ?? json['subjects'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  Person copyWith({String? profileImage, String? status}) => Person(
        id: id,
        name: name,
        email: email,
        phone: phone,
        status: status ?? this.status,
        role: role,
        displayId: displayId,
        branchId: branchId,
        parentName: parentName,
        parentPhone: parentPhone,
        examEligibility: examEligibility,
        userType: userType,
        profileImage: profileImage ?? this.profileImage,
      );

  @override
  List<Object?> get props => [id, name, email, status, profileImage];
}
