import 'package:equatable/equatable.dart';

enum UserType { teacher, student, parent }

enum StaffRole { founder, admin, manager, teacher, sales, receptionist }

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.role,
    this.branchId,
    this.status,
    this.profileImage,
    this.ieltsAccess,
    this.permissions = const {},
  });

  AppUser copyWith({
    String? name,
    String? email,
    String? status,
    String? profileImage,
    bool? ieltsAccess,
    Map<String, bool>? permissions,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        userType: userType,
        role: role,
        branchId: branchId,
        status: status ?? this.status,
        profileImage: profileImage ?? this.profileImage,
        ieltsAccess: ieltsAccess ?? this.ieltsAccess,
        permissions: permissions ?? this.permissions,
      );

  final String id;
  final String name;
  final String? email;
  final UserType userType;
  final StaffRole? role;
  final String? branchId;
  final String? status;
  final String? profileImage;
  final bool? ieltsAccess;
  final Map<String, bool> permissions;

  bool get isStudent => userType == UserType.student;
  bool get isFounder => role == StaffRole.founder;
  bool get isManager => role == StaffRole.manager;
  bool get isSales => role == StaffRole.sales;
  bool get isReceptionist => role == StaffRole.receptionist;
  bool get isAdmin => role == StaffRole.admin;
  bool get isTeacher => role == StaffRole.teacher;
  bool get isParent => userType == UserType.parent;
  bool get isStaff => userType == UserType.teacher;
  bool get isInactiveStudent => isStudent && status == 'inactive';
  bool get hasFullStaffAccess => isFounder || isAdmin;
  bool get isPrivilegedStaff => isFounder || isAdmin || isManager;
  bool get usesAdminShell =>
      isAdmin || isManager || role == StaffRole.sales || role == StaffRole.receptionist;

  bool hasPermission(String key, Map<String, bool> rolePerms) {
    if (hasFullStaffAccess) return true;
    final direct = permissions[key];
    if (direct == true) return true;
    if (direct == false) return false;
    return rolePerms[key] ?? false;
  }

  bool canManageHomeworkFor(Map<String, bool> rolePerms) =>
      hasPermission('canManageHomework', rolePerms);

  /// Teachers can edit/unlock learning content; only managers keep delete via [canManageHomeworkFor].
  bool canEditHomeworkFor(Map<String, bool> rolePerms) {
    if (canManageHomeworkFor(rolePerms)) return true;
    if (hasPermission('canEditHomework', rolePerms)) return true;
    // Default for teachers before platform settings syncs the new key.
    return role == StaffRole.teacher && !rolePerms.containsKey('canEditHomework');
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final userTypeRaw = json['userType'] as String? ?? 'student';
    final roleRaw = json['role'] as String?;

    return AppUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      userType: UserType.values.firstWhere(
        (e) => e.name == userTypeRaw,
        orElse: () => UserType.student,
      ),
      role: roleRaw != null
          ? StaffRole.values.firstWhere(
              (e) => e.name == roleRaw,
              orElse: () => StaffRole.teacher,
            )
          : null,
      branchId: json['branchId']?.toString(),
      status: json['status'] as String?,
      profileImage: json['profileImage'] as String?,
      ieltsAccess: json['ieltsAccess'] as bool?,
      permissions: (json['permissions'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v == true)),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'userType': userType.name,
        'role': role?.name,
        'branchId': branchId,
        'status': status,
        'profileImage': profileImage,
        'ieltsAccess': ieltsAccess,
        'permissions': permissions,
      };

  @override
  List<Object?> get props => [id, email, userType, role, status];
}
