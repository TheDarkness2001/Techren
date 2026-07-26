import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/progress_api.dart';
import '../../domain/entities/learning_cms.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/entities/student_progress.dart';
import '../../domain/entities/words.dart';
import 'auth_provider.dart';
import 'scheduling_provider.dart';
import 'sentences_provider.dart';
import 'words_provider.dart';

final progressApiProvider = Provider<ProgressApi>((ref) {
  return ProgressApi(ref.watch(dioClientProvider));
});

final studentProgressOverviewProvider = FutureProvider.autoDispose<ProgressOverview>((ref) async {
  return ref.watch(progressApiProvider).getOverview();
});

typedef AdminStudentsProgressQuery = ({String search, int page});

final adminStudentsProgressProvider =
    FutureProvider.autoDispose.family<PaginatedResult<StudentProgressSummary>, AdminStudentsProgressQuery>((ref, query) async {
  return ref.watch(progressApiProvider).listStudents(
        page: query.page,
        search: query.search.isEmpty ? null : query.search,
      );
});

final groupProgressProvider = FutureProvider.autoDispose.family<GroupProgressReport, String>((ref, groupId) async {
  return ref.watch(progressApiProvider).getGroupProgress(groupId);
});

bool _isMissingEndpoint(Object error) {
  if (error is! DioException) return false;
  final status = error.response?.statusCode;
  return status == 404 || status == 405;
}

Future<List<GroupProgressReport>> _loadProgressForGroups(
  ProgressApi progressApi,
  Map<String, ({String? groupName, String? subjectName})> byGroup,
) async {
  if (byGroup.isEmpty) return [];

  final reports = await Future.wait(byGroup.entries.map((entry) async {
    final report = await progressApi.getGroupProgress(entry.key);
    final subjectName = entry.value.subjectName;
    if (subjectName == null || subjectName.isEmpty) return report;
    return GroupProgressReport(
      group: {
        ...report.group,
        'subjectName': report.group['subjectName'] ?? subjectName,
        'groupName': report.group['groupName'] ?? entry.value.groupName,
      },
      aggregate: report.aggregate,
      students: report.students,
    );
  }));
  reports.sort((a, b) {
    final an = (a.group['groupName'] as String? ?? '').toLowerCase();
    final bn = (b.group['groupName'] as String? ?? '').toLowerCase();
    return an.compareTo(bn);
  });
  return reports;
}

/// Teacher's groups with student progress (my-groups → timetable fallback).
final teacherMyGroupsProgressProvider = FutureProvider.autoDispose<List<GroupProgressReport>>((ref) async {
  final progressApi = ref.watch(progressApiProvider);
  final schedulingApi = ref.watch(schedulingApiProvider);

  try {
    return await progressApi.getMyGroupsProgress();
  } catch (error) {
    if (!_isMissingEndpoint(error)) {
      // Permission/branch errors on my-groups: still try timetable path.
      final status = error is DioException ? error.response?.statusCode : null;
      if (status != 403 && status != 401) rethrow;
    }
  }

  // Timetable/teacher does not require canViewScheduler.
  final timetable = await schedulingApi.getTimetable('teacher');
  final byGroup = <String, ({String? groupName, String? subjectName})>{};
  for (final entries in timetable.grid.values) {
    for (final entry in entries) {
      final groupId = entry.groupId;
      if (groupId == null || groupId.isEmpty) continue;
      byGroup.putIfAbsent(
        groupId,
        () => (groupName: entry.groupName ?? entry.className, subjectName: entry.subject),
      );
    }
  }

  if (byGroup.isNotEmpty) {
    return _loadProgressForGroups(progressApi, byGroup);
  }

  // Last resort: own class schedules (may 403 if scheduler permission is off).
  try {
    final auth = ref.watch(authProvider);
    final schedules = await schedulingApi.getSchedules(
      page: 1,
      limit: 100,
      teacherId: auth.user?.id,
    );
    for (final schedule in schedules.items) {
      final groupId = schedule.groupId;
      if (groupId == null || groupId.isEmpty) continue;
      byGroup.putIfAbsent(
        groupId,
        () => (groupName: schedule.groupName ?? schedule.className, subjectName: schedule.subjectName),
      );
    }
  } catch (_) {
    return [];
  }

  return _loadProgressForGroups(progressApi, byGroup);
});

final staffStudentProgressProvider = FutureProvider.autoDispose.family<ProgressOverview, String>((ref, studentId) async {
  return ref.watch(progressApiProvider).getOverview(studentId: studentId);
});

typedef GroupLessonProgressQuery = ({String groupId, String lessonId});

final groupLessonProgressProvider =
    FutureProvider.autoDispose.family<GroupLessonProgressReport, GroupLessonProgressQuery>((ref, query) async {
  return ref.watch(progressApiProvider).getGroupLessonProgress(
        groupId: query.groupId,
        lessonId: query.lessonId,
      );
});

final progressLessonOptionsProvider =
    FutureProvider.autoDispose.family<List<ProgressLessonOption>, String>((ref, subjectName) async {
  final progressApi = ref.watch(progressApiProvider);
  try {
    return await progressApi.getLessonOptions(subject: subjectName);
  } catch (_) {
    // Fallback before Railway deploys /progress/lesson-options: load words + sentences CMS.
    final homework = ref.watch(homeworkApiProvider);
    final sentences = ref.watch(sentencesApiProvider);
    final options = <ProgressLessonOption>[];

    Future<void> addModule({
      required Future<List<LearningLanguage>> Function() languages,
      required Future<List<CmsLevel>> Function(String languageId) levels,
      required Future<List<CmsLesson>> Function(String levelId) lessons,
      required String moduleType,
    }) async {
      final langs = await languages();
      final needle = subjectName.trim().toLowerCase();
      var matched = langs.where((l) => l.name.trim().toLowerCase() == needle).toList();
      if (matched.isEmpty) {
        matched = langs
            .where(
              (l) =>
                  needle.contains(l.name.trim().toLowerCase()) ||
                  l.name.trim().toLowerCase().contains(needle),
            )
            .toList();
      }
      if (matched.isEmpty) matched = langs;

      for (final language in matched) {
        final levelList = await levels(language.id);
        for (final level in levelList) {
          final lessonList = List<CmsLesson>.from(await lessons(level.id))
            ..sort((a, b) => a.order.compareTo(b.order));
          for (final lesson in lessonList) {
            options.add(
              ProgressLessonOption(
                id: lesson.id,
                label: lesson.name,
                name: lesson.name,
                moduleType: moduleType,
                levelName: level.name,
              ),
            );
          }
        }
      }
    }

    await addModule(
      languages: homework.getLanguages,
      levels: homework.getLevels,
      lessons: homework.getLessons,
      moduleType: 'words',
    );
    await addModule(
      languages: sentences.getCmsLanguages,
      levels: sentences.getCmsLevels,
      lessons: sentences.getCmsLessons,
      moduleType: 'sentences',
    );

    final seen = <String>{};
    return [
      for (final option in options)
        if (seen.add(option.id)) option,
    ];
  }
});

final studentVocabLessonsProvider = FutureProvider.autoDispose.family<StudentVocabLessonsReport, String>((ref, studentId) async {
  return ref.watch(progressApiProvider).getStudentVocabLessons(studentId);
});
