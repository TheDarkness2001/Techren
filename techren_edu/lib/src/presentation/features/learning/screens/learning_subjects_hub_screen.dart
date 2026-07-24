import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/routing/student_navigation.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/learning_subject.dart';
import '../../../providers/learning_provider.dart';
import '../widgets/learning_subject_editor.dart';
import '../widgets/learning_subject_widgets.dart';

/// Staff / student Learning home — subject cards only (modules live inside each subject).
class LearningSubjectsHubScreen extends ConsumerStatefulWidget {
  const LearningSubjectsHubScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
    this.isStudent = false,
  });

  final List<NavItem> navItems;
  final String selectedRoute;
  final bool isStudent;

  @override
  ConsumerState<LearningSubjectsHubScreen> createState() => _LearningSubjectsHubScreenState();
}

class _LearningSubjectsHubScreenState extends ConsumerState<LearningSubjectsHubScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  LearningSubjectsQuery get _query => (page: 1, search: _search);

  String get _prefix {
    if (widget.isStudent) return '/student';
    if (widget.selectedRoute.startsWith('/founder')) return '/founder';
    if (widget.selectedRoute.startsWith('/teacher')) return '/teacher';
    return '/admin';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openSubject(LearningSubjectCard subject) {
    // Student shell registers `/student/learn/:subjectId` (not `/learning`).
    final path = widget.isStudent
        ? '$_prefix/learn/${subject.id}'
        : '$_prefix/learning/${subject.id}';
    context.go(path);
  }

  Future<void> _addSubject() async {
    final saved = await showLearningSubjectEditor(context: context, ref: ref);
    if (saved == true && mounted) {
      ref.invalidate(learningSubjectsProvider(_query));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject created')));
    }
  }

  Future<void> _editSubject(LearningSubjectCard subject) async {
    final saved = await showLearningSubjectEditor(context: context, ref: ref, existing: subject);
    if (saved == true && mounted) {
      ref.invalidate(learningSubjectsProvider(_query));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject updated')));
    }
  }

  Future<void> _deleteSubject(LearningSubjectCard subject) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: 'Remove ${subject.name}?',
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
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(learningApiProvider).deleteSubject(subject.id);
      ref.invalidate(learningSubjectsProvider(_query));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${subject.name} removed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(learningSubjectsProvider(_query));
    final selectedIndex = widget.navItems.indexWhere((i) => widget.selectedRoute.startsWith(i.route));
    final canManage = !widget.isStudent;

    return AdaptiveScaffold(
      title: 'Learning',
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) {
        if (widget.isStudent) {
          onStudentNavSelected(context, widget.navItems, i);
        } else {
          context.go(widget.navItems[i].route);
        }
      },
      actions: [
        if (canManage)
          FilledButton.icon(
            onPressed: _addSubject,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Subject'),
          ),
      ],
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(learningSubjectsProvider(_query)),
        child: ListView(
          padding: AppSpacing.pagePaddingWide,
          children: [
            Text(
              widget.isStudent ? 'My Subjects' : 'Subjects',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.isStudent
                  ? 'Open a subject classroom to continue learning'
                  : 'Add, edit, or remove subjects. Open a card to manage modules and content.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search subjects',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      ),
              ),
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
            const SizedBox(height: AppSpacing.xl),
            subjectsAsync.when(
              loading: () => const LoadingState(kind: LoadingSkeletonKind.dashboard),
              error: (e, _) => EmptyState(
                title: 'Could not load subjects',
                message: e.toString(),
                icon: Icons.error_outline,
              ),
              data: (result) {
                if (result.items.isEmpty) {
                  return EmptyState(
                    title: 'No subjects yet',
                    message: widget.isStudent
                        ? 'You are not enrolled in any subjects. Ask your school to add you to a group.'
                        : 'Tap Add Subject to create your first learning classroom.',
                    icon: Icons.auto_stories_outlined,
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final columns = width >= 1100 ? 3 : width >= 720 ? 2 : 1;
                    final spacing = AppSpacing.md;
                    final cardWidth = columns == 1
                        ? width
                        : (width - spacing * (columns - 1)) / columns;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final subject in result.items)
                          SizedBox(
                            width: cardWidth,
                            child: LearningSubjectCardWidget(
                              subject: subject,
                              onContinue: () => _openSubject(subject),
                              onEdit: canManage ? () => _editSubject(subject) : null,
                              onDelete: canManage ? () => _deleteSubject(subject) : null,
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
