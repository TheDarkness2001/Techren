import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/ielts.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/ielts_provider.dart';
import '../../../shells/staff_shell.dart';
import '../ielts_ui.dart';

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
                    context.l10n.ieltsLocked,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.ieltsLockedMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: () => context.go(_subjectHome),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(context.l10n.backToSubject),
                  ),
                ],
              ),
            ),
          )
        : _HubBody(
            base: _base,
            subjectId: subjectId,
            isStudent: isStudent,
            isFounder: user?.isFounder == true,
            scheme: scheme,
            muted: muted,
          );

    final actions = <Widget>[
      IconButton(
        tooltip: context.l10n.backToSubject,
        onPressed: () => context.go(_subjectHome),
        icon: const Icon(Icons.arrow_back),
      ),
    ];

    // Staff Learning uses AdaptiveScaffold so IELTS stays inside the academy shell.
    if (!isStudent) {
      final items = navItems.isNotEmpty
          ? navItems
          : (routePrefix.startsWith('/founder') ? founderNavItems : adminNavItems);
      final selectedIndex = items.indexWhere((i) => _learningSelected.startsWith(i.route) || i.route.contains('/learning'));
      return AdaptiveScaffold(
        title: context.l10n.ieltsPreparation,
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        selectedRoute: _learningSelected,
        items: items,
        onDestinationSelected: (i) => context.go(items[i].route),
        actions: actions,
        body: body,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.ieltsPreparation),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(_subjectHome),
        ),
      ),
      body: Padding(padding: AppSpacing.pagePaddingWide, child: body),
    );
  }
}

class _HubBody extends ConsumerWidget {
  const _HubBody({
    required this.base,
    required this.subjectId,
    required this.isStudent,
    required this.isFounder,
    required this.scheme,
    required this.muted,
  });

  final String base;
  final String subjectId;
  final bool isStudent;
  final bool isFounder;
  final ColorScheme scheme;
  final Color muted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Six primary cards only — keep the hub tidy.
    final l10n = context.l10n;
    final tiles = <_HubTile>[
      _HubTile(l10n.mockExams, Icons.quiz_outlined, '$base/exams', l10n.mockExamsSubtitle),
      _HubTile(l10n.listening, Icons.headphones_outlined, '$base/listening', l10n.listeningExams),
      _HubTile(l10n.reading, Icons.menu_book_outlined, '$base/reading', l10n.readingExams),
      _HubTile(l10n.writing, Icons.edit_note_outlined, '$base/writing', l10n.writingExams),
      _HubTile(l10n.speaking, Icons.record_voice_over_outlined, '$base/speaking', l10n.speakingExams),
      if (isStudent)
        _HubTile(l10n.resultsAndHistory, Icons.history_edu_outlined, '$base/history', l10n.pastAttempts)
      else
        _HubTile(l10n.ieltsAccess, Icons.lock_open_outlined, '$base/access', l10n.unlockLockStudents),
    ];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (isStudent) ...[
          _StudentDashboard(
            base: base,
            subjectId: subjectId,
            scheme: scheme,
            muted: muted,
          ),
          const SizedBox(height: AppSpacing.lg),
        ] else
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
                  context.l10n.ieltsPreparation,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.ieltsStaffIntro,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted, height: 1.4),
                ),
              ],
            ),
          ),
        if (!isStudent) const SizedBox(height: AppSpacing.lg),
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
        if (!isStudent) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(context.l10n.moreTools, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: muted)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => context.go('$base/manage'),
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: Text(context.l10n.allExams),
              ),
              TextButton.icon(
                onPressed: () => context.go('$base/writing-review'),
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: Text(context.l10n.writingReview),
              ),
              TextButton.icon(
                onPressed: () => context.go('$base/speaking-review'),
                icon: const Icon(Icons.mic_outlined, size: 18),
                label: Text(context.l10n.speakingReview),
              ),
              TextButton.icon(
                onPressed: () => context.go('$base/sources'),
                icon: const Icon(Icons.source_outlined, size: 18),
                label: Text(context.l10n.sources),
              ),
              TextButton.icon(
                onPressed: () => context.go('$base/bank'),
                icon: const Icon(Icons.storage_outlined, size: 18),
                label: Text(context.l10n.questionBank),
              ),
              TextButton.icon(
                onPressed: () => context.go('$base/analytics'),
                icon: const Icon(Icons.bar_chart_outlined, size: 18),
                label: Text(context.l10n.analytics),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Student hub dashboard: latest bands, trend, focus areas, recent attempts.
class _StudentDashboard extends ConsumerWidget {
  const _StudentDashboard({
    required this.base,
    required this.subjectId,
    required this.scheme,
    required this.muted,
  });

  final String base;
  final String subjectId;
  final ColorScheme scheme;
  final Color muted;

  String _band(dynamic v) {
    if (v == null) return '—';
    if (v is num) {
      final d = v.toDouble();
      return d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(1);
    }
    return v.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(ieltsStudentAnalyticsProvider);
    final historyAsync = ref.watch(ieltsHistoryProvider(subjectId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
          child: analyticsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your IELTS progress',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text('Could not load analytics. Pull to refresh from My Analytics.', style: TextStyle(color: muted)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(ieltsStudentAnalyticsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
            data: (data) {
              final latest = data.latestBands;
              final hasAttempts = data.attemptsCompleted > 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Your IELTS progress',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('$base/exams'),
                        child: Text(context.l10n.startMock),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasAttempts
                        ? '${data.attemptsCompleted} completed attempt${data.attemptsCompleted == 1 ? '' : 's'} · last ${data.days} days'
                        : 'Complete a mock to see estimated bands and focus areas.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted, height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _DashBandChip(label: context.l10n.overall, value: _band(latest?['overallBand']), emphasize: true),
                      _DashBandChip(label: context.l10n.listening, value: _band(latest?['listeningBand'])),
                      _DashBandChip(label: context.l10n.reading, value: _band(latest?['readingBand'])),
                      _DashBandChip(label: context.l10n.writing, value: _band(latest?['writingBand'])),
                      _DashBandChip(label: context.l10n.speaking, value: _band(latest?['speakingBand'])),
                    ],
                  ),
                  if (data.bandTrend.length >= 2) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text('Recent overall trend', style: TextStyle(fontWeight: FontWeight.w700, color: muted)),
                    const SizedBox(height: 8),
                    _MiniTrendStrip(trend: data.bandTrend),
                  ],
                  if (data.weaknesses.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text('Focus areas', style: TextStyle(fontWeight: FontWeight.w700, color: muted)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final w in data.weaknesses.take(4))
                          Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: const Icon(Icons.flag_outlined, size: 16),
                            label: Text(
                              '${w['type'] ?? '?'} · ${w['accuracy'] ?? '—'}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ActionChip(
                          label: const Text('Full analytics'),
                          onPressed: () => context.go('$base/analytics'),
                        ),
                      ],
                    ),
                  ] else if (hasAttempts) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextButton.icon(
                      onPressed: () => context.go('$base/analytics'),
                      icon: const Icon(Icons.insights_outlined, size: 18),
                      label: const Text('Open full analytics'),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        historyAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (page) {
            final recent = page.items.take(4).toList();
            if (recent.isEmpty) {
              return Material(
                color: scheme.surface,
                borderRadius: AppRadius.card,
                child: InkWell(
                  borderRadius: AppRadius.card,
                  onTap: () => context.go('$base/exams'),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.card,
                      border: Border.all(color: context.semantic.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.play_circle_outline, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No attempts yet — take your first mock exam',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Recent attempts', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('$base/history'),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                for (final a in recent)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        a.exam?.title.isNotEmpty == true ? a.exam!.title : 'Attempt',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [
                          if (a.scores.overallBand != null) 'Overall ${a.scores.overallBand}',
                          if (a.scores.listeningBand != null) 'L ${a.scores.listeningBand}',
                          if (a.scores.readingBand != null) 'R ${a.scores.readingBand}',
                          if (a.submittedAt != null)
                            '${a.submittedAt!.year}-${a.submittedAt!.month.toString().padLeft(2, '0')}-${a.submittedAt!.day.toString().padLeft(2, '0')}',
                        ].join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('$base/results/${a.id}'),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DashBandChip extends StatelessWidget {
  const _DashBandChip({required this.label, required this.value, this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 88),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: emphasize ? AppColors.primary.withValues(alpha: 0.14) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.semantic.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.semantic.textMuted)),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: emphasize ? AppColors.primary : null,
                ),
          ),
        ],
      ),
    );
  }
}

class _MiniTrendStrip extends StatelessWidget {
  const _MiniTrendStrip({required this.trend});

  final List<Map<String, dynamic>> trend;

  @override
  Widget build(BuildContext context) {
    final points = trend.where((t) => t['overallBand'] != null).toList();
    if (points.isEmpty) return const SizedBox.shrink();
    final last = points.length > 8 ? points.sublist(points.length - 8) : points;
    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final p in last) ...[
            Expanded(
              child: Tooltip(
                message: 'Overall ${p['overallBand']}',
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: (((p['overallBand'] as num?)?.toDouble() ?? 0) / 9.0 * 36).clamp(6.0, 36.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
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

class IeltsExamListScreen extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<IeltsExamListScreen> createState() => _IeltsExamListScreenState();
}

class _IeltsExamListScreenState extends ConsumerState<IeltsExamListScreen> {
  bool _busy = false;

  String get _hub => widget.isStudent
      ? '${widget.routePrefix}/learn/${widget.subjectId}/ielts'
      : '${widget.routePrefix}/learning/${widget.subjectId}/ielts';

  String get _examMode => widget.mode ?? 'full';

  String get _title => switch (widget.mode) {
        'listening' => 'Listening',
        'reading' => 'Reading',
        'writing' => 'Writing',
        'speaking' => 'Speaking',
        'full' => 'Mock Exams',
        _ => 'Mock Exams',
      };

  Future<void> _importReadingJson() async {
    final jsonCtrl = TextEditingController();

    Future<void> pickFile(void Function(void Function()) setLocal) async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      String? text;
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        text = utf8.decode(file.bytes!);
      } else if (file.path != null && file.path!.isNotEmpty) {
        text = await File(file.path!).readAsString();
      }
      if (text == null || text.trim().isEmpty) return;
      setLocal(() => jsonCtrl.text = text!);
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          insetPadding: IeltsUi.dialogInset,
          titlePadding: IeltsUi.titlePadding,
          contentPadding: IeltsUi.contentPadding,
          actionsPadding: IeltsUi.actionsPadding,
          title: const Text('Import reading JSON'),
          content: ConstrainedBox(
            constraints: IeltsUi.dialogConstraints(ctx, maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Paste Academic Reading JSON (3 passages, 40 questions), or pick a .json file. '
                  'Creates an unpublished Reading exam.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                IeltsUi.fieldGap,
                OutlinedButton.icon(
                  onPressed: () => pickFile(setLocal),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Pick .json file'),
                ),
                IeltsUi.fieldGap,
                SizedBox(
                  height: 280,
                  child: TextField(
                    controller: jsonCtrl,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '{ "title": "...", "module": "Academic", "passages": [...] }',
                    ),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final raw = jsonCtrl.text.trim();
    if (raw.isEmpty) return;

    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('Root JSON must be an object');
      }
      body = Map<String, dynamic>.from(decoded);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid JSON: ${IeltsUi.errorMessage(e)}')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      body['subjectId'] = widget.subjectId;
      final exam = await ref.read(ieltsApiProvider).importExamJson(body, subjectId: widget.subjectId);
      ref.invalidate(ieltsExamsProvider((subjectId: widget.subjectId, mode: 'reading')));
      ref.invalidate(ieltsExamsProvider((subjectId: widget.subjectId, mode: null)));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported “${exam.title}” as draft')),
      );
      context.go('$_hub/manage/${exam.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: ${IeltsUi.errorMessage(e)}')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createExam() async {
    final titleCtrl = TextEditingController(
      text: switch (_examMode) {
        'listening' => 'New Listening exam',
        'reading' => 'New Reading exam',
        'writing' => 'New Writing exam',
        'speaking' => 'New Speaking exam',
        _ => 'New IELTS Mock',
      },
    );
    var training = 'academic';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Add ${_title.toLowerCase()} exam'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: training,
                decoration: const InputDecoration(labelText: 'Training type'),
                items: const [
                  DropdownMenuItem(value: 'academic', child: Text('Academic')),
                  DropdownMenuItem(value: 'general', child: Text('General Training')),
                ],
                onChanged: (v) => setLocal(() => training = v ?? 'academic'),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mode: $_examMode',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final created = await ref.read(ieltsApiProvider).createExam({
        'subjectId': widget.subjectId,
        'title': titleCtrl.text.trim().isEmpty ? 'New exam' : titleCtrl.text.trim(),
        'mode': _examMode,
        'trainingType': training,
        'published': false,
      });
      ref.invalidate(ieltsExamsProvider((subjectId: widget.subjectId, mode: widget.mode ?? 'full')));
      ref.invalidate(ieltsExamsProvider((subjectId: widget.subjectId, mode: null)));
      if (!mounted) return;
      context.go('$_hub/manage/${created.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(IeltsUi.errorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _togglePublish(IeltsExam exam) async {
    try {
      if (!exam.published) {
        final bundle = await ref.read(ieltsApiProvider).getExam(exam.id);
        final issues = IeltsUi.publishBlockingIssues(bundle);
        if (issues.isNotEmpty) {
          if (!mounted) return;
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Cannot publish yet'),
              content: Text(
                'Authentic IELTS structure required:\n\n• ${issues.join('\n• ')}\n\n'
                'Open the exam editor, add the missing passages/parts/questions, then publish.',
              ),
              actions: [
                FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
              ],
            ),
          );
          return;
        }
      }
      await ref.read(ieltsApiProvider).updateExam(exam.id, {'published': !exam.published});
      ref.invalidate(ieltsExamsProvider((subjectId: widget.subjectId, mode: widget.mode ?? 'full')));
      ref.invalidate(ieltsExamsProvider((subjectId: widget.subjectId, mode: null)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(IeltsUi.errorMessage(e))),
      );
    }
  }

  Future<void> _deleteExam(IeltsExam exam) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${exam.title}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(ieltsApiProvider).deleteExam(exam.id);
    ref.invalidate(ieltsExamsProvider((subjectId: widget.subjectId, mode: widget.mode ?? 'full')));
    ref.invalidate(ieltsExamsProvider((subjectId: widget.subjectId, mode: null)));
  }

  @override
  Widget build(BuildContext context) {
    final listMode = widget.mode ?? 'full';
    final async = ref.watch(ieltsExamsProvider((subjectId: widget.subjectId, mode: listMode)));

    final body = async.when(
      loading: () => const LoadingState(message: 'Loading exams...'),
      error: (e, _) => ErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(ieltsExamsProvider((subjectId: widget.subjectId, mode: listMode))),
      ),
      data: (exams) {
        final filtered = exams.where((e) => e.mode == listMode).toList();
        if (filtered.isEmpty) {
          return EmptyState(
            title: 'No ${_title.toLowerCase()} yet',
            message: widget.isStudent
                ? 'Published exams will appear here.'
                : 'Add an exam for this section, then edit questions and publish.',
            icon: Icons.quiz_outlined,
            action: widget.isStudent
                ? null
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _busy ? null : _createExam,
                        icon: const Icon(Icons.add),
                        label: const Text('Add exam'),
                      ),
                      if (_examMode == 'reading')
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _importReadingJson,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Import JSON'),
                        ),
                    ],
                  ),
          );
        }
        return ListView.separated(
          padding: widget.isStudent ? EdgeInsets.zero : AppSpacing.pagePaddingWide,
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final exam = filtered[i];
            if (widget.isStudent) {
              return Card(
                child: ListTile(
                  title: Text(exam.title),
                  subtitle: Text('${exam.difficulty}${exam.published ? '' : ' · draft'}'),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () => context.go('$_hub/play/${exam.id}'),
                ),
              );
            }
            return Card(
              child: ListTile(
                title: Text(exam.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${exam.trainingType} · ${exam.published ? 'Published' : 'Draft'}'
                  '${exam.archived ? ' · Archived' : ''}',
                ),
                trailing: Wrap(
                  spacing: 0,
                  children: [
                    IconButton(
                      tooltip: 'Edit exam',
                      onPressed: () => context.go('$_hub/manage/${exam.id}'),
                      icon: const Icon(Icons.edit_note),
                    ),
                    IconButton(
                      tooltip: exam.published ? 'Unpublish' : 'Publish',
                      onPressed: () => _togglePublish(exam),
                      icon: Icon(exam.published ? Icons.visibility : Icons.visibility_off),
                    ),
                    IconButton(
                      tooltip: 'Preview / play',
                      onPressed: () => context.go('$_hub/play/${exam.id}'),
                      icon: const Icon(Icons.play_arrow),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'delete') _deleteExam(exam);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    final actions = <Widget>[
      if (!widget.isStudent && _examMode == 'reading')
        IconButton(
          tooltip: 'Import reading JSON',
          onPressed: _busy ? null : _importReadingJson,
          icon: const Icon(Icons.upload_file),
        ),
      if (!widget.isStudent)
        IconButton(
          tooltip: 'Add exam',
          onPressed: _busy ? null : _createExam,
          icon: const Icon(Icons.add),
        ),
      IconButton(
        tooltip: 'Back',
        onPressed: () => context.go(_hub),
        icon: const Icon(Icons.arrow_back),
      ),
    ];

    if (!widget.isStudent) {
      final learningSelected = widget.selectedRoute ?? '${widget.routePrefix}/learning';
      final items = widget.navItems.isNotEmpty
          ? widget.navItems
          : (widget.routePrefix.startsWith('/founder') ? founderNavItems : adminNavItems);
      final selectedIndex = items.indexWhere(
        (i) => learningSelected.startsWith(i.route) || i.route.contains('/learning'),
      );
      return AdaptiveScaffold(
        title: _title,
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        selectedRoute: learningSelected,
        items: items,
        onDestinationSelected: (i) => context.go(items[i].route),
        actions: actions,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                children: [
                  Text(
                    'Add or edit ${_title.toLowerCase()} exams',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.semantic.textMuted,
                        ),
                  ),
                  const Spacer(),
                  if (_examMode == 'reading') ...[
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _importReadingJson,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Import JSON'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilledButton.icon(
                    onPressed: _busy ? null : _createExam,
                    icon: const Icon(Icons.add),
                    label: const Text('Add exam'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go(_hub)),
      ),
      body: Padding(padding: AppSpacing.pagePaddingWide, child: body),
    );
  }
}
