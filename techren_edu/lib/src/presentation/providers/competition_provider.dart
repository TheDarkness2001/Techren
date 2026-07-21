import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/competition_api.dart';
import '../../domain/entities/competition.dart';
import '../../domain/entities/paginated_result.dart';
import 'auth_provider.dart';

final competitionApiProvider = Provider<CompetitionApi>((ref) => CompetitionApi(ref.watch(dioClientProvider)));

final studentCompetitionPenaltiesProvider = FutureProvider.autoDispose.family<List<PenaltyRecord>, String>((ref, studentId) async {
  final now = DateTime.now();
  return ref.watch(competitionApiProvider).getStudentPenalties(studentId, year: now.year, month: now.month);
});

final studentCompetitionPresentationsProvider = FutureProvider.autoDispose.family<List<PresentationRecord>, String>((ref, studentId) async {
  final now = DateTime.now();
  return ref.watch(competitionApiProvider).getStudentPresentations(studentId, year: now.year, month: now.month);
});

final monthlyPenaltiesProvider = FutureProvider.autoDispose.family<PaginatedResult<PenaltyRecord>, int>((ref, page) async {
  final now = DateTime.now();
  return ref.watch(competitionApiProvider).getMonthlyPenalties(year: now.year, month: now.month, page: page);
});

final topPresentersProvider = FutureProvider.autoDispose<List<TopPresenter>>((ref) async {
  final now = DateTime.now();
  return ref.watch(competitionApiProvider).getTopPresenters(year: now.year, month: now.month);
});

final bonusPreviewProvider = FutureProvider.autoDispose<BonusPreview>((ref) async {
  final now = DateTime.now();
  return ref.watch(competitionApiProvider).calculateBonuses(year: now.year, month: now.month);
});

final bonusHistoryProvider = FutureProvider.autoDispose<List<BonusPeriod>>((ref) async {
  return ref.watch(competitionApiProvider).getBonusHistory();
});
