import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/wallet_api.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/entities/wallet.dart';
import 'auth_provider.dart';

typedef WalletTransactionsQuery = ({String? studentId, int page, String search});

final walletApiProvider = Provider<WalletApi>((ref) {
  return WalletApi(ref.watch(dioClientProvider));
});

final walletBalanceProvider = FutureProvider.autoDispose<WalletBalance>((ref) async {
  return ref.watch(walletApiProvider).getBalance();
});

final walletTransactionsProvider =
    FutureProvider.autoDispose.family<PaginatedResult<WalletTransaction>, WalletTransactionsQuery>((ref, query) async {
  return ref.watch(walletApiProvider).getTransactions(
        studentId: query.studentId,
        page: query.page,
        search: query.search.isEmpty ? null : query.search,
      );
});

final adminWalletBalanceProvider = FutureProvider.autoDispose.family<WalletBalance, String>((ref, studentId) async {
  return ref.watch(walletApiProvider).getBalance(studentId: studentId);
});
