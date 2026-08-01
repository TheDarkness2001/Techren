import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/learning_quiz.dart';
import '../../../providers/learning_quiz_provider.dart';
import '../../../providers/scheduling_provider.dart';

class QuizHubScreen extends ConsumerWidget {
  const QuizHubScreen({
    super.key,
    required this.subjectId,
    this.isStudent = true,
    this.routePrefix = '/student',
  });

  final String subjectId;
  final bool isStudent;
  final String routePrefix;

  String get _base => isStudent
      ? '$routePrefix/learn/$subjectId/quiz'
      : '$routePrefix/learning/$subjectId/quiz';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(learningQuizzesProvider(subjectId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
        actions: [
          if (!isStudent)
            TextButton.icon(
              onPressed: () => context.go('$_base/manage'),
              icon: const Icon(Icons.edit_note_outlined),
              label: const Text('Manage'),
            ),
          if (isStudent)
            TextButton(
              onPressed: () => context.go('$_base/history'),
              child: const Text('History'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(learningQuizzesProvider(subjectId)),
        child: quizzesAsync.when(
          loading: () => ListView(children: const [LoadingState(kind: LoadingSkeletonKind.list)]),
          error: (e, _) => ListView(
            children: [
              EmptyState(title: 'Could not load quizzes', message: e.toString(), icon: Icons.error_outline),
            ],
          ),
          data: (quizzes) {
            if (quizzes.isEmpty) {
              return ListView(
                padding: AppSpacing.pagePaddingWide,
                children: [
                  EmptyState(
                    title: 'No quizzes yet',
                    message: isStudent
                        ? 'Your teacher has not published quizzes for this subject.'
                        : 'Create a topic/level quiz with ABCD or form-completion questions.',
                    icon: Icons.quiz_outlined,
                    action: isStudent
                        ? null
                        : FilledButton.icon(
                            onPressed: () => context.go('$_base/manage'),
                            icon: const Icon(Icons.add),
                            label: const Text('Create quiz'),
                          ),
                  ),
                ],
              );
            }

            final levels = quizzes.map((q) => q.level).toSet().toList()..sort();
            return ListView(
              padding: AppSpacing.pagePaddingWide,
              children: [
                Text(
                  'Topic quizzes by level',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final level in levels) ...[
                  Text(
                    level,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...quizzes.where((q) => q.level == level).map((quiz) {
                    final locked = isStudent && !quiz.isUnlocked;
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: locked
                              ? scheme.surfaceContainerHighest
                              : scheme.primaryContainer,
                          child: Icon(locked ? Icons.lock_outline : Icons.quiz_outlined),
                        ),
                        title: Text(quiz.title),
                        subtitle: Text(
                          '${quiz.topic} · ${quiz.questionCount} questions'
                          '${quiz.published ? '' : ' · draft'}'
                          '${locked ? ' · locked' : ''}',
                        ),
                        trailing: locked
                            ? null
                            : const Icon(Icons.chevron_right),
                        onTap: locked
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Locked for your group. Ask your teacher to unlock it.'),
                                  ),
                                );
                              }
                            : () {
                                if (isStudent) {
                                  context.go('$_base/play/${quiz.id}');
                                } else {
                                  context.go('$_base/manage/${quiz.id}');
                                }
                              },
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class QuizHistoryScreen extends ConsumerWidget {
  const QuizHistoryScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(learningQuizHistoryProvider(subjectId));
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz history')),
      body: historyAsync.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
        error: (e, _) => EmptyState(title: 'Could not load history', message: e.toString()),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(title: 'No attempts yet', message: 'Complete a quiz to see results here.');
          }
          return ListView.separated(
            padding: AppSpacing.pagePaddingWide,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final a = items[i];
              return Card(
                child: ListTile(
                  title: Text(a.quiz?.title ?? 'Quiz'),
                  subtitle: Text(
                    '${a.quiz?.level ?? ''} · ${a.scorePercent}% · ${a.passed ? 'Passed' : 'Failed'}',
                  ),
                  trailing: Icon(
                    a.passed ? Icons.check_circle : Icons.cancel_outlined,
                    color: a.passed ? Colors.green : Colors.orange,
                  ),
                  onTap: () => context.go(
                    '/student/learn/$subjectId/quiz/results/${a.id}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> showQuizUnlockDialog(BuildContext context, WidgetRef ref, LearningQuiz quiz) async {
  final groups = await ref.read(examGroupsProvider.future);
  if (!context.mounted) return;
  if (groups.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No groups found')));
    return;
  }
  var selected = groups.first;
  final unlock = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Unlock “${quiz.title}”'),
          content: DropdownButtonFormField(
            value: selected.id,
            items: [
              for (final g in groups)
                DropdownMenuItem(value: g.id, child: Text(g.groupName)),
            ],
            onChanged: (id) {
              selected = groups.firstWhere((g) => g.id == id);
              setLocal(() {});
            },
            decoration: const InputDecoration(labelText: 'Group'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Lock')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Unlock')),
          ],
        ),
      );
    },
  );
  if (unlock == null) return;
  await ref.read(learningQuizApiProvider).toggleUnlock(
        quizId: quiz.id,
        groupId: selected.id,
        unlock: unlock,
      );
  ref.invalidate(learningQuizzesProvider(quiz.subjectId));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(unlock ? 'Unlocked for ${selected.groupName}' : 'Locked for ${selected.groupName}')),
    );
  }
}
