import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/attendance_api.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/entities/paginated_result.dart';
import 'auth_provider.dart';

typedef FeedbackQuery = ({String? studentId, int page, String search});

final attendanceApiProvider = Provider<AttendanceApi>((ref) {
  return AttendanceApi(ref.watch(dioClientProvider));
});

final teacherCheckInProvider = FutureProvider.autoDispose<TeacherCheckInStatus>((ref) async {
  return ref.watch(attendanceApiProvider).getTodayCheckInStatus();
});

final todayClassesProvider = FutureProvider.autoDispose<List<TodayClassSession>>((ref) async {
  return ref.watch(attendanceApiProvider).getTodayClasses();
});

typedef AttendanceClassesQuery = ({String scope, String date});

final attendanceClassesProvider =
    FutureProvider.autoDispose.family<List<TodayClassSession>, AttendanceClassesQuery>((ref, query) async {
  return ref.watch(attendanceApiProvider).getFeedbackClasses(
        scope: query.scope,
        teacherId: 'all',
        date: query.date,
      );
});

typedef FeedbackClassesQuery = ({String scope, String teacherId});

final feedbackClassesProvider =
    FutureProvider.autoDispose.family<List<TodayClassSession>, FeedbackClassesQuery>((ref, query) async {
  return ref.watch(attendanceApiProvider).getFeedbackClasses(
        scope: query.scope,
        teacherId: query.teacherId,
      );
});

final feedbackListProvider = FutureProvider.autoDispose.family<PaginatedResult<FeedbackEntry>, FeedbackQuery>((ref, query) async {
  return ref.watch(attendanceApiProvider).getFeedback(
        studentId: query.studentId,
        page: query.page,
        search: query.search.isEmpty ? null : query.search,
      );
});

typedef TeacherRosterQuery = ({String date, String role});

final teacherAttendanceRosterProvider =
    FutureProvider.autoDispose.family<List<TeacherRosterRow>, TeacherRosterQuery>((ref, query) async {
  return ref.watch(attendanceApiProvider).getTeacherRoster(date: query.date, role: query.role);
});
