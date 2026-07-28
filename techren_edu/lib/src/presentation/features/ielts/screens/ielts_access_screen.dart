import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/person.dart';
import '../../../../domain/entities/scheduling.dart';
import '../../../providers/ielts_provider.dart';
import '../../../providers/scheduling_provider.dart';

/// Founder-only: unlock/lock IELTS for groups or all English students.
class IeltsAccessScreen extends ConsumerStatefulWidget {
  const IeltsAccessScreen({super.key, this.subjectId});

  final String? subjectId;

  @override
  ConsumerState<IeltsAccessScreen> createState() => _IeltsAccessScreenState();
}

class _IeltsAccessScreenState extends ConsumerState<IeltsAccessScreen> {
  bool _busy = false;
  List<dynamic> _unlocked = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  Future<void> _refreshList() async {
    try {
      final page = await ref.read(ieltsApiProvider).listAccess();
      setState(() {
        _unlocked = page.items;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _runBulk({
    required bool enabled,
    String? examGroupId,
    bool allEnglish = false,
  }) async {
    setState(() => _busy = true);
    try {
      final result = await ref.read(ieltsApiProvider).bulkAccess(
            enabled: enabled,
            examGroupId: examGroupId,
            allEnglish: allEnglish,
          );
      if (!mounted) return;
      final modified = result['modified'] ?? result['matched'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${enabled ? 'Unlocked' : 'Locked'} $modified students')),
      );
      await _refreshList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickGroup(bool enabled) async {
    final groups = await ref.read(examGroupsProvider.future);
    if (!mounted) return;
    ExamGroup? selected = groups.isNotEmpty ? groups.first : null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(enabled ? 'Unlock group' : 'Lock group'),
        content: groups.isEmpty
            ? const Text('No exam groups found.')
            : DropdownButtonFormField<ExamGroup>(
                value: selected,
                items: groups
                    .map((g) => DropdownMenuItem(value: g, child: Text(g.groupName)))
                    .toList(),
                onChanged: (v) => selected = v,
                decoration: const InputDecoration(labelText: 'Exam group'),
              ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: groups.isEmpty ? null : () => Navigator.pop(ctx, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (ok == true && selected != null) {
      await _runBulk(enabled: enabled, examGroupId: selected!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    return Scaffold(
      appBar: AppBar(title: const Text('IELTS access')),
      body: ListView(
        padding: AppSpacing.pagePaddingWide,
        children: [
          Text(
            'Only the founder can unlock IELTS Preparation. Teachers cannot grant access.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : () => _pickGroup(true),
                icon: const Icon(Icons.lock_open),
                label: const Text('Unlock exam group'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _pickGroup(false),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Lock exam group'),
              ),
              FilledButton.tonalIcon(
                onPressed: _busy
                    ? null
                    : () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Unlock all English students?'),
                            content: const Text(
                              'Every student enrolled in an English subject group will get IELTS access.',
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Unlock all')),
                            ],
                          ),
                        );
                        if (ok == true) await _runBulk(enabled: true, allEnglish: true);
                      },
                icon: const Icon(Icons.public),
                label: const Text('Unlock all English'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Currently unlocked', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (_unlocked.isEmpty) Text('No students unlocked yet.', style: TextStyle(color: muted)),
          for (final raw in _unlocked)
            Builder(
              builder: (context) {
                final person = Person.fromJson(Map<String, dynamic>.from(raw as Map));
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.card,
                    side: BorderSide(color: context.semantic.border),
                  ),
                  title: Text(person.name),
                  subtitle: Text(person.email ?? person.displayId ?? person.id),
                  trailing: TextButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            await ref.read(ieltsApiProvider).setStudentAccess(person.id, false);
                            await _refreshList();
                          },
                    child: const Text('Lock'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
