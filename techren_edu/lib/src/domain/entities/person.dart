import 'package:equatable/equatable.dart';

class SubjectFee extends Equatable {
  const SubjectFee({required this.subject, this.amount = 0});

  final String subject;
  final double amount;

  Map<String, dynamic> toJson() => {'subject': subject, 'amount': amount};

  factory SubjectFee.fromJson(Map<String, dynamic> json) => SubjectFee(
        subject: json['subject'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [subject, amount];
}

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
    this.coursePrice,
    this.subjectFees = const [],
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.address,
    this.medicalConditions,
    this.department,
    this.examEligibility,
    this.ieltsAccess,
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
  final double? coursePrice;
  final List<SubjectFee> subjectFees;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? address;
  final String? medicalConditions;
  final String? department;
  final bool? examEligibility;
  final bool? ieltsAccess;
  final String userType;
  final String? profileImage;
  final List<String> subjects;

  bool get isActive => status == 'active';
  bool get isGraduated => status == 'graduated';
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
        coursePrice: (json['coursePrice'] as num?)?.toDouble(),
        subjectFees: (json['subjectFees'] as List<dynamic>? ?? [])
            .map((e) => SubjectFee.fromJson(e as Map<String, dynamic>))
            .toList(),
        dateOfBirth: json['dateOfBirth'] != null
            ? DateTime.tryParse(json['dateOfBirth'].toString())
            : null,
        gender: json['gender'] as String?,
        bloodGroup: json['bloodGroup'] as String?,
        address: json['address'] as String?,
        medicalConditions: json['medicalConditions'] as String?,
        department: json['department'] as String?,
        examEligibility: json['examEligibility'] as bool?,
        ieltsAccess: json['ieltsAccess'] as bool?,
        userType: json['userType'] as String? ?? 'student',
        profileImage: json['profileImage'] as String?,
        subjects: (json['subject'] as List<dynamic>? ?? json['subjects'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  Person copyWith({String? profileImage, String? status, bool? ieltsAccess, double? coursePrice}) => Person(
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
        coursePrice: coursePrice ?? this.coursePrice,
        subjectFees: subjectFees,
        dateOfBirth: dateOfBirth,
        gender: gender,
        bloodGroup: bloodGroup,
        address: address,
        medicalConditions: medicalConditions,
        department: department,
        examEligibility: examEligibility,
        ieltsAccess: ieltsAccess ?? this.ieltsAccess,
        userType: userType,
        profileImage: profileImage ?? this.profileImage,
        subjects: subjects,
      );

  @override
  List<Object?> get props => [id, name, email, status, profileImage, coursePrice, subjects];
}
