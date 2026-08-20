import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/routing/student_navigation.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/learning_subject.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/learning_provider.dart';
import '../../../providers/staff_navigation_provider.dart';
import '../widgets/learning_subject_editor.dart';
import '../widgets/learning_subject_widgets.dart';

/// Per-subject classroom dashboard — modules as tiles, existing features stay linked.
class LearningSubjectDashboardScreen extends ConsumerWidget {
  const LearningSubjectDashboardScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
    required this.subjectId,
    this.isStudent = false,
  });

  final List<NavItem> navItems;
  final String selectedRoute;
  final String subjectId;
  final bool isStudent;

  String _prefixOf(BuildContext context) {
    if (isStudent) return '/student';
    final loc = GoRouterState.of(context).uri.path;
    if (loc.startsWith('/founder') || selectedRoute.startsWith('/founder')) return '/founder';
    if (loc.startsWith('/teacher') || selectedRoute.startsWith('/teacher')) return '/teacher';
    return '/admin';
  }

  static const _implementedModuleKeys = {
    'words',
    'sentences',
    'listening',
    'video',
    'ielts',
    'cms',
    'import',
    'progress',
    'exam',
    'quiz',
    'typing',
  };

  List<LearningModuleDef> _visibleModules(List<LearningModuleDef> modules) {
    return [
      for (final module in modules)
        if (_implementedModuleKeys.contains(module.key) &&
            !(isStudent && (module.key == 'cms' || module.key == 'import' || module.key == 'exam')))
          module,
    ];
  }

  void _openModule(BuildContext context, WidgetRef ref, LearningModuleDef module) {
    if (module.key == 'ielts' && isStudent) {
      final access = ref.read(authProvider).user?.ieltsAccess == true;
      if (!access) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('IELTS Preparation is locked. Ask your founder to unlock it.')),
        );
      }
    }
    final prefix = _prefixOf(context);
    final route = switch (module.key) {
      'words' => isStudent ? '/student/words' : '$prefix/words',
      'sentences' => isStudent ? '/student/sentences' : '$prefix/sentences',
      'listening' => isStudent ? '/student/listening' : '$prefix/learning-cms',
      'video' => isStudent
          ? '/student/learn/$subjectId/video'
          : '$prefix/learning/$subjectId/video',
      'ielts' => isStudent ? '/student/learn/$subjectId/ielts' : '$prefix/learning/$subjectId/ielts',
      'cms' => isStudent ? null : '$prefix/learning-cms',
      'import' => isStudent ? null : '$prefix/content-import',
      'progress' => isStudent ? '/student/progress' : '$prefix/progress',
      'exam' => isStudent ? null : '$prefix/exams',
      'quiz' => isStudent
          ? '/student/learn/$subjectId/quiz'
          : '$prefix/learning/$subjectId/quiz',
      'typing' => isStudent
          ? '/student/learn/$subjectId/typing'
          : '$prefix/learning/$subjectId/typing',
      _ => null,
    };
    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${module.label} is coming soon for this subject')),
      );
      return;
    }
    context.go(route);
  }

  Future<void> _editSubject(BuildContext context, WidgetRef ref, LearningSubjectDashboard dash) async {
    final saved = await showLearningSubjectEditor(context: context, ref: ref, existing: dash);
    if (saved == true) {
      ref.invalidate(learningSubjectDashboardProvider(subjectId));
      ref.invalidate(learningSubjectsProvider((page: 1, search: '')));
    }
  }

  Future<void> _editModules(BuildContext context, WidgetRef ref, LearningSubjectDashboard dash) async {
    final saved = await showLearningModulesEditor(context: context, ref: ref, subject: dash);
    if (saved == true) {
      ref.invalidate(learningSubjectDashboardProvider(subjectId));
      ref.invalidate(learningSubjectsProvider((page: 1, search: '')));
    }
  }

  Future<void> _deleteSubject(BuildContext context, WidgetRef ref, LearningSubjectDashboard dash) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: 'Remove ${dash.name}?',
        icon: Icons.delete_outline,
        content: const Text(
          'This removes the subject from Learning. Groups that still use it must be removed or reassigned first.',
        ),
        actions: [
          AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context, false)),
          AppDialogActions.confirm(
            context,
            label: 'Remove',
            destructive: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(learningApiProvider).deleteSubject(dash.id);
      if (context.mounted) {
        context.go(isStudent ? '${_prefixOf(context)}/learn' : '${_prefixOf(context)}/learning');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${dash.name} removed')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(learningSubjectDashboardProvider(subjectId));
    final selectedIndex = navItems.indexWhere((i) => selectedRoute.startsWith(i.route.split('/learning').first) || selectedRoute.contains('/learning'));
    final safeIndex = selectedIndex < 0
        ? navItems.indexWhere((i) => i.route.contains('/learning') || i.route.contains('/learn'))
        : selectedIndex;

    return AdaptiveScaffold(
      title: 'Learning',
      selectedIndex: safeIndex < 0 ? 0 : safeIndex,
      selectedRoute: selectedRoute,
      items: navItems,
      onDestinationSelected: (i) {
        if (isStudent) {
          onStudentNavSelected(context, navItems, i);
        } else {
          context.go(navItems[i].route);
        }
      },
      actions: [
        IconButton(
          tooltip: 'Back to subjects',
          onPressed: () => context.go(isStudent ? '/student/learn' : '${_prefixOf(context)}/learning'),
          icon: const Icon(Icons.grid_view_outlined),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(learningSubjectDashboardProvider(subjectId)),
        child: dashAsync.when(
          loading: () => ListView(children: const [LoadingState(kind: LoadingSkeletonKind.dashboard)]),
          error: (e, _) => ListView(
            children: [
              EmptyState(title: 'Subject unavailable', message: e.toString(), icon: Icons.error_outline),
            ],
          ),
          data: (dash) {
            final accent = parseSubjectColor(dash.color);
            final learning = _visibleModules(
              dash.modulesByCategory['learning'] ??
                  dash.modules.where((m) => m.category == 'learning').toList(),
            );
            final assessment = _visibleModules(
              dash.modulesByCategory['assessment'] ??
                  dash.modules.where((m) => m.category == 'assessment').toList(),
            );
            final management = _visibleModules(
              dash.modulesByCategory['management'] ??
                  dash.modules.where((m) => m.category == 'management').toList(),
            );
            final statistics = _visibleModules(
              dash.modulesByCategory['statistics'] ??
                  dash.modules.where((m) => m.category == 'statistics').toList(),
            );
            final ieltsLocked = isStudent && ref.watch(authProvider).user?.ieltsAccess != true;
            final user = ref.watch(authProvider).user;
            final rolePerms = ref.watch(staffRolePermissionsProvider);
            final canEdit = !isStudent && (user?.canEditHomeworkFor(rolePerms) ?? false);
            final canDelete = !isStudent && (user?.canManageHomeworkFor(rolePerms) ?? false);

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _SubjectHero(dash: dash, accent: accent),
                if (canEdit) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _editSubject(context, ref, dash),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit subject'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _editModules(context, ref, dash),
                        icon: const Icon(Icons.widgets_outlined, size: 18),
                        label: const Text('Edit modules'),
                      ),
                      if (canDelete)
                        OutlinedButton.icon(
                          onPressed: () => _deleteSubject(context, ref, dash),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Remove'),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (learning.isNotEmpty) ...[
                  const _SectionTitle(title: 'Learning'),
                  const SizedBox(height: AppSpacing.sm),
                  _ModuleGrid(
                    modules: learning,
                    accent: accent,
                    ieltsLocked: ieltsLocked,
                    onTap: (m) => _openModule(context, ref, m),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (assessment.isNotEmpty) ...[
                  const _SectionTitle(title: 'Assessment'),
                  const SizedBox(height: AppSpacing.sm),
                  _ModuleGrid(modules: assessment, accent: accent, onTap: (m) => _openModule(context, ref, m)),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (management.isNotEmpty) ...[
                  const _SectionTitle(title: 'Content'),
                  const SizedBox(height: AppSpacing.sm),
                  _ModuleGrid(modules: management, accent: accent, onTap: (m) => _openModule(context, ref, m)),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (statistics.isNotEmpty) ...[
                  const _SectionTitle(title: 'Statistics'),
                  const SizedBox(height: AppSpacing.sm),
                  _ModuleGrid(modules: statistics, accent: accent, onTap: (m) => _openModule(context, ref, m)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SubjectHero extends StatelessWidget {
  const _SubjectHero({required this.dash, required this.accent});

  final LearningSubjectDashboard dash;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.22),
            accent.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(iconForLearningKey(dash.icon), color: accent, size: 32),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dash.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                ),
                if (dash.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    dash.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({
    required this.modules,
    required this.accent,
    required this.onTap,
    this.ieltsLocked = false,
  });

  final List<LearningModuleDef> modules;
  final Color accent;
  final void Function(LearningModuleDef) onTap;
  final bool ieltsLocked;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900 ? 4 : width >= 640 ? 3 : width >= 420 ? 2 : 1;
        final spacing = AppSpacing.sm;
        final tileWidth = columns == 1 ? width : (width - spacing * (columns - 1)) / columns;
        final tileHeight = MediaQuery.sizeOf(context).height < 820 ? 96.0 : 112.0;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final module in modules)
              SizedBox(
                width: tileWidth,
                height: tileHeight,
                child: LearningModuleTile(
                  module: module,
                  accent: accent,
                  locked: module.key == 'ielts' && ieltsLocked,
                  onTap: () => onTap(module),
                ),
              ),
          ],
        );
      },
    );
  }
}
