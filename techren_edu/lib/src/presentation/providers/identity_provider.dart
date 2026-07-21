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
  return ref.watch(identityApiProvider).getDashboard();
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
