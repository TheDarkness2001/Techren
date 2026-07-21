import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_hub_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/paginated_scroll_body.dart';
import '../../../../domain/entities/competition.dart';
import '../../../../domain/entities/person.dart';
import '../../../../domain/entities/paginated_result.dart';
import '../../../providers/competition_provider.dart';
import '../../../providers/identity_provider.dart';

class CompetitionHubScreen extends ConsumerStatefulWidget {
  const CompetitionHubScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
    this.canDistributeBonuses = false,
  });

  final List<NavItem> navItems;
  final String selectedRoute;
  final bool canDistributeBonuses;

  @override
  ConsumerState<CompetitionHubScreen> createState() => _CompetitionHubScreenState();
}

class _CompetitionHubScreenState extends ConsumerState<CompetitionHubScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));

    return AdaptiveScaffold(
      title: 'Competition',
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => _showRecordSheet(context)),
      ],
      body: Column(
        children: [
          HubTabBarShell(
            tabBar: TabBar(
              controller: _tabs,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Penalties'),
                Tab(text: 'Presentations'),
                Tab(text: 'Bonuses'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                const _PenaltiesTab(),
                const _PresentationsTab(),
                _BonusesTab(canDistribute: widget.canDistributeBonuses),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRecordSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _RecordSheet(onSaved: () {
        ref.invalidate(monthlyPenaltiesProvider);
        ref.invalidate(topPresentersProvider);
        ref.invalidate(bonusPreviewProvider);
      }),
    );
  }
}

class _PenaltiesTab extends ConsumerWidget {
  const _PenaltiesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PaginatedScrollBody<PenaltyRecord, int>(
      provider: monthlyPenaltiesProvider,
      query: 1,
      withPage: (_, page) => page,
      queryCacheKey: 'monthly-penalties',
      onInvalidate: (ref, _) => ref.invalidate(monthlyPenaltiesProvider),
      itemLabel: 'penalties',
      initialLoadingKind: LoadingSkeletonKind.list,
      empty: ListView(
        children: const [
          SizedBox(height: AppSpacing.emptyStateTop),
          EmptyState(
            title: 'No penalties this month',
            message: 'Record lateness or absences with the + button.',
            icon: Icons.gavel_outlined,
          ),
        ],
      ),
      builder: (context, controller, items, state) => ListView.builder(
        controller: controller,
        padding: AppSpacing.listGutter,
        itemCount: items.length,
        itemBuilder: (_, i) {
          final p = items[i];
          return AppAdminRowCard(
            title: p.studentName ?? 'Student',
            subtitle: '${p.type.replaceAll('_', ' ')} · ${p.notes}',
            icon: Icons.warning_amber_outlined,
            accentColor: AppColors.warning,
            trailing: Text(
              '${p.totalPoints}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          );
        },
      ),
    );
  }
}

class _PresentationsTab extends ConsumerWidget {
  const _PresentationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topAsync = ref.watch(topPresentersProvider);
    return topAsync.when(
      loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (entries) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(topPresentersProvider),
        child: ListView(
          padding: AppSpacing.listGutter,
          children: [
            Text('Top presenters this month', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            if (entries.isEmpty)
              const EmptyState(
                title: 'No presentation scores yet',
                message: 'Presentation rankings appear after scores are recorded.',
                icon: Icons.mic_outlined,
              ),
            ...entries.map(
              (e) => LeaderboardHubCard(
                rank: e.rank,
                title: e.name,
                subtitle: '${e.count} presentations',
                trailing: '${e.avgScore}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BonusesTab extends ConsumerWidget {
  const _BonusesTab({required this.canDistribute});

  final bool canDistribute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(bonusPreviewProvider);
    final historyAsync = ref.watch(bonusHistoryProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(bonusPreviewProvider);
        ref.invalidate(bonusHistoryProvider);
      },
      child: ListView(
        padding: AppSpacing.listGutter,
        children: [
          previewAsync.when(
            loading: () => const LoadingState(kind: LoadingSkeletonKind.card),
            error: (e, _) => Text(e.toString()),
            data: (preview) => Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('40 / 30 / 30 split preview', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Total penalties: ${preview.totalPenalties}'),
                    Text('1st place (40%): ${preview.firstPlaceAmount}'),
                    Text('2nd place (30%): ${preview.secondPlaceAmount}'),
                    Text('Education center (30%): ${preview.centerAmount}'),
                    if (canDistribute && preview.topPresenters.length >= 2) ...[
                      const SizedBox(height: AppSpacing.sm),
                      FilledButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final first = preview.topPresenters[0];
                          final second = preview.topPresenters[1];
                          await ref.read(competitionApiProvider).distributeBonuses(
                                year: now.year,
                                month: now.month,
                                firstPlaceStudentId: first.studentId,
                                secondPlaceStudentId: second.studentId,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bonuses distributed')),
                            );
                          }
                          ref.invalidate(bonusHistoryProvider);
                          ref.invalidate(bonusPreviewProvider);
                        },
                        child: const Text('Distribute to top 2 presenters'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('History', style: Theme.of(context).textTheme.titleMedium),
          historyAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: CircularProgressIndicator()),
            error: (e, _) => Text(e.toString()),
            data: (periods) => periods.isEmpty
                ? const Text('No closed periods yet')
                : Column(
                    children: periods
                        .map(
                          (p) => ListTile(
                            title: Text('${p.year}-${p.month.toString().padLeft(2, '0')}'),
                            subtitle: Text(p.status),
                            trailing: Text('${p.totalBonusesDistributed}'),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecordSheet extends ConsumerStatefulWidget {
  const _RecordSheet({required this.onSaved});

  final VoidCallback onSaved;

  @override
  ConsumerState<_RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends ConsumerState<_RecordSheet> {
  String _mode = 'penalty';
  Person? _student;
  String _penaltyType = 'spoken_uzbek';
  final _pointsCtrl = TextEditingController(text: '-5');
  final _scoreCtrl = TextEditingController(text: '8');
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _pointsCtrl.dispose();
    _scoreCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const studentQuery = PageMeta(page: 1, limit: 20);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'penalty', label: Text('Penalty')),
              ButtonSegment(value: 'presentation', label: Text('Presentation')),
            ],
            selected: {_mode},
            onSelectionChanged: (v) => setState(() => _mode = v.first),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 220,
            child: PaginatedScrollBody<Person, PageMeta>(
              provider: studentsProvider,
              query: studentQuery,
              withPage: (q, page) => q.copyWith(page: page),
              queryCacheKey: 'record-sheet-students',
              onInvalidate: (ref, q) => ref.invalidate(studentsProvider(q)),
              itemLabel: 'students',
              initialLoadingKind: LoadingSkeletonKind.list,
              builder: (context, controller, items, state) => ListView.builder(
                controller: controller,
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final student = items[i];
                  final selected = _student?.id == student.id;
                  return ListTile(
                    title: Text('${student.name} (${student.displayId ?? student.id})'),
                    selected: selected,
                    onTap: () => setState(() => _student = student),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_mode == 'penalty') ...[
            DropdownButtonFormField<String>(
              value: _penaltyType,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'spoken_uzbek', child: Text('Spoken Uzbek')),
                DropdownMenuItem(value: 'missed_presentation', child: Text('Missed presentation')),
                DropdownMenuItem(value: 'missed_writing_homework', child: Text('Missed writing homework')),
                DropdownMenuItem(value: 'missed_word_memorization', child: Text('Missed word memorization')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _penaltyType = v ?? _penaltyType),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: _pointsCtrl, decoration: const InputDecoration(labelText: 'Points', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          ] else
            TextField(controller: _scoreCtrl, decoration: const InputDecoration(labelText: 'Score (1-10)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          const SizedBox(height: AppSpacing.sm),
          TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder())),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _saving || _student == null ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final api = ref.read(competitionApiProvider);
      if (_mode == 'penalty') {
        await api.createPenalty(
          studentId: _student!.id,
          type: _penaltyType,
          points: int.parse(_pointsCtrl.text),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
      } else {
        await api.recordPresentation(
          studentId: _student!.id,
          score: int.parse(_scoreCtrl.text),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
