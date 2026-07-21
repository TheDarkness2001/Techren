import 'package:equatable/equatable.dart';
import 'branch.dart';
import 'person.dart';

class DashboardData extends Equatable {
  const DashboardData({
    required this.role,
    this.stats = const {},
    this.branch,
    this.recentBranches = const [],
    this.recentStudents = const [],
    this.profile,
    this.greeting,
  });

  final String role;
  final Map<String, dynamic> stats;
  final Branch? branch;
  final List<Branch> recentBranches;
  final List<Person> recentStudents;
  final Person? profile;
  final String? greeting;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final statsRaw = json['stats'];
    final stats = statsRaw is Map<String, dynamic>
        ? Map<String, dynamic>.from(statsRaw)
        : <String, dynamic>{};

    return DashboardData(
      role: json['role'] as String? ?? '',
      stats: stats,
      branch: json['branch'] != null ? Branch.fromJson(json['branch'] as Map<String, dynamic>) : null,
      recentBranches: (json['recentBranches'] as List<dynamic>? ?? [])
          .map((e) => Branch.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentStudents: (json['recentStudents'] as List<dynamic>? ?? [])
          .map((e) => Person.fromJson({...e as Map<String, dynamic>, 'userType': 'student'}))
          .toList(),
      profile: json['profile'] != null
          ? Person.fromJson({...json['profile'] as Map<String, dynamic>, 'userType': 'student'})
          : null,
      greeting: json['greeting'] as String?,
    );
  }

  int stat(String key) => (stats[key] as num?)?.toInt() ?? 0;

  @override
  List<Object?> get props => [role, stats, branch?.id];
}
