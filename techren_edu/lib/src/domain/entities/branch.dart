import 'package:equatable/equatable.dart';

class Branch extends Equatable {
  const Branch({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? address;
  final String? phone;
  final bool isActive;
  final DateTime? createdAt;

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      );

  String get formattedCreated {
    if (createdAt == null) return '—';
    final d = createdAt!.toLocal();
    return '${d.month}/${d.day}/${d.year}';
  }

  @override
  List<Object?> get props => [id, name, isActive];
}

class BranchStats extends Equatable {
  const BranchStats({
    required this.branchId,
    required this.students,
    required this.teachers,
    required this.activeStudents,
    required this.inactiveStudents,
  });

  final String branchId;
  final int students;
  final int teachers;
  final int activeStudents;
  final int inactiveStudents;

  factory BranchStats.fromJson(Map<String, dynamic> json) => BranchStats(
        branchId: json['branchId']?.toString() ?? '',
        students: json['students'] as int? ?? 0,
        teachers: json['teachers'] as int? ?? 0,
        activeStudents: json['activeStudents'] as int? ?? 0,
        inactiveStudents: json['inactiveStudents'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [branchId, students, teachers];
}
