import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/ielts_provider.dart';

class IeltsHubScreen extends ConsumerWidget {
  const IeltsHubScreen({
    super.key,
    required this.subjectId,
    this.isStudent = true,
    this.routePrefix = '/student',
    this.navItems = const [],
    this.selectedRoute,
  });

  final String subjectId;
  final bool isStudent;
  final String routePrefix;
  final List<NavItem> navItems;
  final String? selectedRoute;

  String get _base => isStudent
      ? '$routePrefix/learn/$subjectId/ielts'
      : '$routePrefix/learning/$subjectId/ielts';

  String get _subjectHome => isStudent
      ? '$routePrefix/learn/$subjectId'
      : '$routePrefix/learning/$subjectId';

  String get _learningSelected => selectedRoute ??
      (isStudent ? '$routePrefix/learn' : '$routePrefix/learning');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final locked = isStudent && user?.ieltsAccess != true;
    final scheme = Theme.of(context).colorScheme;
    final muted = context.semantic.textMuted;

    final body = locked
        ? Center(
            child: Padding(
              padding: AppSpacing.pagePaddingWide,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 56, color: muted),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'IELTS Preparation is locked',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Ask your academy founder to unlock IELTS for your account.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: () => context.go(_subjectHome),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to subject'),
                  ),
                ],
              ),
            ),
          )
        : _HubBody(
            base: _base,
            isStudent: isStudent,
            isFounder: user?.isFounder == true,
            scheme: scheme,
            muted: muted,
          );

    final actions = <Widget>[
      IconButton(
        tooltip: 'Back to subject',
        onPressed: () => context.go(_subjectHome),
        icon: const Icon(Icons.arrow_back),
      ),
    ];

    // Staff Learning uses AdaptiveScaffold so IELTS stays inside the academy shell.
    if (!isStudent && navItems.isNotEmpty) {
      final selectedIndex = navItems.indexWhere((i) => _learningSelected.startsWith(i.route) || i.route.contains('/learning'));
      return AdaptiveScaffold(
        title: 'IELTS Preparation',
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        selectedRoute: _learningSelected,
        items: navItems,
        onDestinationSelected: (i) => context.go(navItems[i].route),
        actions: actions,
        body: body,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('IELTS Preparation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(_subjectHome),
        ),
      ),
      body: body,
    );
  }
}

class _HubBody extends StatelessWidget {
  const _HubBody({
    required this.base,
    required this.isStudent,
    required this.isFounder,
    required this.scheme,
    required this.muted,
  });

  final String base;
  final bool isStudent;
  final bool isFounder;
  final ColorScheme scheme;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final tiles = <_HubTile>[
      _HubTile('Mock Exams', Icons.quiz_outlined, '$base/exams', 'Full & section mocks'),
      _HubTile('Listening', Icons.headphones_outlined, '$base/listening', 'Listening-only tests'),
      _HubTile('Reading', Icons.menu_book_outlined, '$base/reading', 'Reading-only tests'),
      _HubTile('Writing', Icons.edit_note_outlined, '$base/writing', 'Writing tasks'),
      _HubTile('Results & History', Icons.history_edu_outlined, '$base/history', 'Past attempts'),
      if (!isStudent) ...[
        _HubTile('Manage Exams', Icons.settings_outlined, '$base/manage', 'Create & publish'),
        _HubTile('Writing Review', Icons.rate_review_outlined, '$base/writing-review', 'Score submissions'),
        if (isFounder)
          _HubTile('IELTS Access', Icons.lock_open_outlined, '$base/access', 'Founder unlock/lock'),
      ],
    ];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.18),
                scheme.surface,
              ],
            ),
            border: Border.all(color: context.semantic.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Computer IELTS practice',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Timed mocks for Listening, Reading, and Writing. Instant L/R bands; Writing reviewed by teachers.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final t in tiles)
              SizedBox(
                width: 280,
                child: _HubCard(tile: t, onTap: () => context.go(t.route)),
              ),
          ],
        ),
      ],
    );
  }
}

class _HubTile {
  const _HubTile(this.title, this.icon, this.route, this.subtitle);
  final String title;
  final IconData icon;
  final String route;
  final String subtitle;
}

class _HubCard extends StatelessWidget {
  const _HubCard({required this.tile, required this.onTap});
  final _HubTile tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(color: context.semantic.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tile.icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tile.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(tile.subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class IeltsExamListScreen extends ConsumerWidget {
  const IeltsExamListScreen({
    super.key,
    required this.subjectId,
    this.mode,
    this.isStudent = true,
    this.routePrefix = '/student',
    this.navItems = const [],
    this.selectedRoute,
  });

  final String subjectId;
  final String? mode;
  final bool isStudent;
  final String routePrefix;
  final List<NavItem> navItems;
  final String? selectedRoute;

  String get _hub => isStudent
      ? '$routePrefix/learn/$subjectId/ielts'
      : '$routePrefix/learning/$subjectId/ielts';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ieltsExamsProvider((subjectId: subjectId, mode: mode)));
    final title = switch (mode) {
      'listening' => 'Listening mocks',
      'reading' => 'Reading mocks',
      'writing' => 'Writing mocks',
      _ => 'Mock exams',
    };

    final body = async.when(
      loading: () => const LoadingState(message: 'Loading exams...'),
      error: (e, _) => ErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(ieltsExamsProvider((subjectId: subjectId, mode: mode))),
      ),
      data: (exams) {
        final filtered = mode == null ? exams : exams.where((e) => e.mode == mode || e.mode == 'full').toList();
        if (filtered.isEmpty) {
          return EmptyState(
            title: 'No exams yet',
            message: isStudent
                ? 'Published IELTS mocks will appear here.'
                : 'Create and publish an exam under Manage Exams.',
            icon: Icons.quiz_outlined,
            action: isStudent
                ? null
                : FilledButton.icon(
                    onPressed: () => context.go('$_hub/manage'),
                    icon: const Icon(Icons.add),
                    label: const Text('Manage exams'),
                  ),
          );
        }
        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final exam = filtered[i];
            return Card(
              child: ListTile(
                title: Text(exam.title),
                subtitle: Text('${exam.mode} · ${exam.difficulty}${exam.published ? '' : ' · draft'}'),
                trailing: const Icon(Icons.play_arrow),
                onTap: () => context.go('$_hub/play/${exam.id}'),
              ),
            );
          },
        );
      },
    );

    final actions = <Widget>[
      IconButton(
        tooltip: 'Back',
        onPressed: () => context.go(_hub),
        icon: const Icon(Icons.arrow_back),
      ),
    ];

    if (!isStudent && navItems.isNotEmpty) {
      final learningSelected = selectedRoute ?? '$routePrefix/learning';
      final selectedIndex = navItems.indexWhere((i) => learningSelected.startsWith(i.route) || i.route.contains('/learning'));
      return AdaptiveScaffold(
        title: title,
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        selectedRoute: learningSelected,
        items: navItems,
        onDestinationSelected: (i) => context.go(navItems[i].route),
        actions: actions,
        body: body,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go(_hub)),
      ),
      body: Padding(padding: AppSpacing.pagePaddingWide, child: body),
    );
  }
}
