import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/identity_api.dart';
import '../../domain/entities/branch.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/entities/person.dart';
import 'auth_provider.dart';

final identityApiProvider = Provider<IdentityApi>((ref) {
  return IdentityApi(ref.watch(dioClientProvider));
});

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final api = ref.watch(identityApiProvider);
  final data = await api.getDashboard();

  // Founder production API may omit activeStudents — fill from /students?status=active.
  const staffRoles = {'founder', 'admin', 'manager', 'sales', 'receptionist'};
  if (staffRoles.contains(data.role) && !data.stats.containsKey('activeStudents')) {
    try {
      final active = await api.getStudents(const PageMeta(page: 1, limit: 1, status: 'active'));
      return data.copyWith(
        stats: {
          ...data.stats,
          'activeStudents': active.total,
        },
      );
    } catch (_) {
      return data;
    }
  }

  return data;
});

final branchesProvider = FutureProvider.autoDispose.family<PaginatedResult<Branch>, PageMeta>((ref, meta) async {
  return ref.watch(identityApiProvider).getBranches(meta);
});

final studentsProvider = FutureProvider.autoDispose.family<PaginatedResult<Person>, PageMeta>((ref, meta) async {
  return ref.watch(identityApiProvider).getStudents(meta);
});

final teachersProvider = FutureProvider.autoDispose.family<PaginatedResult<Person>, PageMeta>((ref, meta) async {
  return ref.watch(identityApiProvider).getTeachers(meta);
});

final branchStatsProvider = FutureProvider.autoDispose.family<BranchStats, String>((ref, branchId) async {
  return ref.watch(identityApiProvider).getBranchStats(branchId);
});
