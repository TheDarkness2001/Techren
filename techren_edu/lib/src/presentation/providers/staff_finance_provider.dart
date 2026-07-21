import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/staff_finance_api.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/entities/staff_finance.dart';
import 'auth_provider.dart';

typedef StaffEarningsQuery = ({String? staffId, int page, String search});
typedef StaffPayoutsQuery = ({String? staffId, int page, String search});

final staffFinanceApiProvider = Provider<StaffFinanceApi>((ref) {
  return StaffFinanceApi(ref.watch(dioClientProvider));
});

final staffAccountProvider = FutureProvider.autoDispose.family<StaffAccountSummary, String?>((ref, staffId) async {
  return ref.watch(staffFinanceApiProvider).getAccount(staffId: staffId);
});

final staffEarningsProvider =
    FutureProvider.autoDispose.family<PaginatedResult<StaffEarningEntry>, StaffEarningsQuery>((ref, query) async {
  return ref.watch(staffFinanceApiProvider).getEarnings(
        staffId: query.staffId,
        page: query.page,
        search: query.search.isEmpty ? null : query.search,
      );
});

final staffApprovedEarningsProvider = FutureProvider.autoDispose.family<List<StaffEarningEntry>, String>((ref, staffId) async {
  final result = await ref.watch(staffFinanceApiProvider).getEarnings(staffId: staffId, status: 'approved', limit: 100);
  return result.items;
});

final staffPayoutsProvider =
    FutureProvider.autoDispose.family<PaginatedResult<StaffPayoutEntry>, StaffPayoutsQuery>((ref, query) async {
  return ref.watch(staffFinanceApiProvider).getPayouts(
        staffId: query.staffId,
        page: query.page,
        search: query.search.isEmpty ? null : query.search,
      );
});
