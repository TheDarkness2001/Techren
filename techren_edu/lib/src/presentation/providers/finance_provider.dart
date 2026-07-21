import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/finance_api.dart';

import '../../domain/entities/finance.dart';

import '../../domain/entities/paginated_result.dart';

import 'auth_provider.dart';



final financeApiProvider = Provider<FinanceApi>((ref) {

  return FinanceApi(ref.watch(dioClientProvider));

});



typedef ExamsQuery = ({int page, String search, bool archived});

typedef PaymentsQuery = ({int page, String search});

typedef PaymentRosterQuery = ({int month, int year, String search});

final examsProvider = FutureProvider.autoDispose.family<PaginatedResult<ExamEntry>, ExamsQuery>((ref, query) async {
  return ref.watch(financeApiProvider).getExams(
        page: query.page,
        search: query.search,
        archived: query.archived,
      );
});

final paymentsProvider = FutureProvider.autoDispose.family<PaginatedResult<PaymentEntry>, PaymentsQuery>((ref, query) async {
  return ref.watch(financeApiProvider).getPayments(page: query.page, search: query.search);
});

final paymentRosterProvider =
    FutureProvider.autoDispose.family<PaymentRosterResult, PaymentRosterQuery>((ref, query) async {
  return ref.watch(financeApiProvider).getPaymentRoster(
        month: query.month,
        year: query.year,
        search: query.search,
      );
});



final revenueSummaryProvider = FutureProvider.autoDispose<RevenueSummary>((ref) async {

  return ref.watch(financeApiProvider).getRevenueSummary();

});



final revenueDateRangeProvider = StateProvider<RevenueDateRange>((ref) => RevenueDateRange.allTime());



final filteredRevenueSummaryProvider = FutureProvider.autoDispose<RevenueSummary>((ref) async {

  final range = ref.watch(revenueDateRangeProvider);

  return ref.watch(financeApiProvider).getRevenueSummary(

        startDate: range.startDateParam,

        endDate: range.endDateParam,

      );

});



final filteredRevenueChartProvider = FutureProvider.autoDispose<RevenueChartData>((ref) async {

  final range = ref.watch(revenueDateRangeProvider);

  return ref.watch(financeApiProvider).getRevenueChart(

        startDate: range.startDateParam,

        endDate: range.endDateParam,

      );

});



final filteredRevenueExportProvider = FutureProvider.autoDispose<RevenueExportData>((ref) async {

  final range = ref.watch(revenueDateRangeProvider);

  return ref.watch(financeApiProvider).getRevenueExport(

        startDate: range.startDateParam,

        endDate: range.endDateParam,

      );

});



final pendingPaymentsProvider = FutureProvider.autoDispose<PendingPaymentsSummary>((ref) async {

  return ref.watch(financeApiProvider).getPendingPayments();

});



final revenueChartProvider = FutureProvider.autoDispose<RevenueChartData>((ref) async {

  return ref.watch(financeApiProvider).getRevenueChart();

});



final revenueExportProvider = FutureProvider.autoDispose<RevenueExportData>((ref) async {

  return ref.watch(financeApiProvider).getRevenueExport();

});



final studentExamsProvider = FutureProvider.autoDispose<List<ExamEntry>>((ref) async {

  final result = await ref.watch(financeApiProvider).getExams();

  return result.items;

});



final studentPaymentsProvider = FutureProvider.autoDispose<List<PaymentEntry>>((ref) async {

  final result = await ref.watch(financeApiProvider).getPayments();

  return result.items;

});


